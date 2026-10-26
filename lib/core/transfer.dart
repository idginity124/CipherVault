import 'dart:convert';
import 'dart:typed_data';
import 'entry.dart';
import 'vault_codec.dart';

class Transfer {
  static List<String> encode(Uint8List encrypted) {
    final body = base64UrlEncode(encrypted), id = newId();
    final total = (body.length / 750).ceil();
    if (total > 64) {
      throw const FormatException(
        'Bu kasa QR için büyük. Şifreli dosya aktarımını kullan.',
      );
    }
    return List.generate(
      total,
      (i) => jsonEncode({
        'app': 'CipherVault',
        'v': 2,
        'id': id,
        'part': i,
        'total': total,
        'data': body.substring(i * 750, ((i + 1) * 750).clamp(0, body.length)),
      }),
    );
  }
}

class TransferReceiver {
  final Map<int, String> _parts = {};
  String? _id;
  int? _total;
  DateTime? _started;
  int get count => _parts.length;
  int get total => _total ?? 0;
  void clear() {
    _parts.clear();
    _id = null;
    _total = null;
    _started = null;
  }

  Uint8List? accept(String raw, {DateTime? now}) {
    now ??= DateTime.now();
    if (_started != null &&
        now.difference(_started!) > const Duration(minutes: 3)) {
      clear();
    }
    if (raw.length > 1200) throw const FormatException('QR boyutu geçersiz.');
    final m = jsonDecode(raw);
    if (m is! Map ||
        m['app'] != 'CipherVault' ||
        m['v'] != 2 ||
        m['id'] is! String ||
        (m['id'] as String).length != 24 ||
        m['part'] is! int ||
        m['total'] is! int ||
        m['data'] is! String) {
      throw const FormatException(
        'Yalnızca şifreli CipherVault 2 QR kodları kabul edilir.',
      );
    }
    final part = m['part'] as int,
        total = m['total'] as int,
        data = m['data'] as String;
    if (total < 1 ||
        total > 64 ||
        part < 0 ||
        part >= total ||
        data.isEmpty ||
        data.length > 750) {
      throw const FormatException('QR parçası geçersiz.');
    }
    if (_id != null && (_id != m['id'] || _total != total)) {
      throw const FormatException(
        'Farklı aktarımların parçaları karıştırılamaz.',
      );
    }
    _id = m['id'] as String;
    _total = total;
    _started ??= now;
    if (_parts.containsKey(part) && _parts[part] != data) {
      throw const FormatException('QR parçası değişmiş.');
    }
    _parts[part] = data;
    if (_parts.length != total) return null;
    final bytes = base64Url.decode(
      List.generate(total, (i) => _parts[i]!).join(),
    );
    VaultCodec.parse(bytes);
    return bytes;
  }
}
