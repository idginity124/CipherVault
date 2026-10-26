import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// CVLT v1, compatible with the retired Python vault. All record fields are
/// authenticated and encrypted together. Expensive work stays off the UI isolate.
class VaultCodec {
  static const maxBytes = 16 * 1024 * 1024;
  static const defaults = <String, dynamic>{
    'type': 'argon2id',
    'length': 32,
    'iterations': 2,
    'lanes': 1,
    'memory_cost_kib': 19456,
  };
  static Uint8List random(int n) =>
      Uint8List.fromList(List.generate(n, (_) => Random.secure().nextInt(256)));
  static Future<Uint8List> derive(
    String password,
    List<int> salt,
    Map<String, dynamic> params,
  ) => Isolate.run(() async {
    validateParams(params);
    final key = await Argon2id(
      memory: params['memory_cost_kib'] as int,
      iterations: params['iterations'] as int,
      parallelism: params['lanes'] as int,
      hashLength: 32,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    return Uint8List.fromList(await key.extractBytes());
  });
  static void validateParams(Map<String, dynamic> p) {
    if (p['type'] != 'argon2id' ||
        p['length'] != 32 ||
        p['memory_cost_kib'] is! int ||
        p['iterations'] is! int ||
        p['lanes'] is! int ||
        (p['memory_cost_kib'] as int) < 8192 ||
        (p['memory_cost_kib'] as int) > 131072 ||
        (p['iterations'] as int) < 1 ||
        (p['iterations'] as int) > 6 ||
        (p['lanes'] as int) < 1 ||
        (p['lanes'] as int) > 8) {
      throw const FormatException('Desteklenmeyen kasa parametreleri.');
    }
  }

  static ({
    Uint8List salt,
    Uint8List nonce,
    Uint8List cipher,
    Uint8List aad,
    Map<String, dynamic> params,
  })
  parse(Uint8List bytes) {
    if (bytes.length < 51 || bytes.length > maxBytes) {
      throw const FormatException('Kasa boyutu geçersiz.');
    }
    if (ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'CVLT') {
      // Python v0: no header, Argon2id 64 MiB / 3 iterations / 4 lanes.
      return (
        salt: Uint8List.sublistView(bytes, 0, 16),
        nonce: Uint8List.sublistView(bytes, 16, 28),
        cipher: Uint8List.sublistView(bytes, 28),
        aad: Uint8List(0),
        params: {
          ...defaults,
          'memory_cost_kib': 65536,
          'iterations': 3,
          'lanes': 4,
        },
      );
    }
    if (bytes[4] != 1) {
      throw const FormatException('Kasa sürümü desteklenmiyor.');
    }
    final len = ByteData.sublistView(bytes).getUint16(5);
    final end = 7 + len;
    if (len > 2048 || end + 44 > bytes.length) {
      throw const FormatException('Kasa başlığı bozuk.');
    }
    final params = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(bytes.sublist(7, end))) as Map,
    );
    validateParams(params);
    return (
      salt: Uint8List.sublistView(bytes, end, end + 16),
      nonce: Uint8List.sublistView(bytes, end + 16, end + 28),
      cipher: Uint8List.sublistView(bytes, end + 28),
      aad: Uint8List.sublistView(bytes, 0, end + 16),
      params: params,
    );
  }

  static Future<
    ({
      Uint8List key,
      Uint8List salt,
      Map<String, dynamic> params,
      List<Map<String, dynamic>> entries,
    })
  >
  open(Uint8List bytes, String password) async {
    final p = parse(bytes);
    final key = await derive(password, p.salt, p.params);
    try {
      final entries = await Isolate.run(() async {
        final box = SecretBox(
          p.cipher.sublist(0, p.cipher.length - 16),
          nonce: p.nonce,
          mac: Mac(p.cipher.sublist(p.cipher.length - 16)),
        );
        final plain = await AesGcm.with256bits().decrypt(
          box,
          secretKey: SecretKey(key),
          aad: p.aad,
        );
        final m = jsonDecode(utf8.decode(plain));
        if (m is! Map ||
            m['entries'] is! List ||
            (m['entries'] as List).length > 10000) {
          throw const FormatException('Kasa kayıtları geçersiz.');
        }
        return (m['entries'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
      });
      return (
        key: key,
        salt: Uint8List.fromList(p.salt),
        params: p.params,
        entries: entries,
      );
    } catch (_) {
      key.fillRange(0, key.length, 0);
      rethrow;
    }
  }

  static Future<Uint8List> seal(
    List<Map<String, dynamic>> entries,
    Uint8List key,
    Uint8List salt,
    Map<String, dynamic> params,
  ) async {
    final copy = Uint8List.fromList(key);
    try {
      return await Isolate.run(() async {
        validateParams(params);
        final encoded = utf8.encode(jsonEncode(params));
        final header = BytesBuilder()
          ..add(ascii.encode('CVLT'))
          ..addByte(1)
          ..add(
            (ByteData(2)..setUint16(0, encoded.length)).buffer.asUint8List(),
          )
          ..add(encoded)
          ..add(salt);
        final aad = header.toBytes();
        final nonce = random(12);
        final plain = utf8.encode(
          jsonEncode({
            'entries': entries,
            'meta': {'version': '2.0'},
          }),
        );
        if (plain.length > maxBytes - 4096) {
          throw const FormatException('Kasa boyutu sınırı aşıldı.');
        }
        final box = await AesGcm.with256bits().encrypt(
          plain,
          secretKey: SecretKey(copy),
          nonce: nonce,
          aad: aad,
        );
        return (BytesBuilder()
              ..add(aad)
              ..add(nonce)
              ..add(box.cipherText)
              ..add(box.mac.bytes))
            .toBytes();
      });
    } finally {
      copy.fillRange(0, copy.length, 0);
    }
  }
}
