import 'dart:convert';
import 'package:encrypt/encrypt.dart' as old;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../legacy/vault_entry.dart' as legacy;
import 'entry.dart';

/// Read-only migration. Never creates a replacement key for existing data.
Future<List<Entry>> readLegacyMobile({
  String? directory,
  Future<String?> Function()? readKey,
}) async {
  if (directory == null) {
    await Hive.initFlutter();
  } else {
    Hive.init(directory);
  }
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(legacy.VaultEntryAdapter());
  }
  if (!await Hive.boxExists('vaultBox')) {
    throw StateError('Eski mobil kasa bulunamadı.');
  }
  final keyText = readKey != null
      ? await readKey()
      : await const FlutterSecureStorage().read(key: 'cipher_vault_aes_key_v1');
  final box = await Hive.openBox<legacy.VaultEntry>('vaultBox');
  try {
    String decode(String value) {
      if (value.isEmpty) return '';
      final modern = value.startsWith('CV2:');
      if (!modern && !value.startsWith('{')) return value;
      if (keyText == null) {
        throw StateError(
          'Eski kasanın cihaz anahtarı bulunamadı. Veriler değiştirilmedi.',
        );
      }
      final m = jsonDecode(modern ? value.substring(4) : value) as Map;
      final cipher = old.Encrypter(
        old.AES(
          old.Key.fromBase64(keyText),
          mode: modern ? old.AESMode.gcm : old.AESMode.cbc,
        ),
      );
      return cipher.decrypt(
        old.Encrypted.fromBase64(m['data'] as String),
        iv: old.IV.fromBase64(m['iv'] as String),
      );
    }

    return box.values
        .map(
          (e) => Entry(
            title: e.title,
            username: e.username,
            password: decode(e.password),
            notes: decode(e.notes),
            url: e.url,
            category: e.category,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          ),
        )
        .toList();
  } finally {
    await box.close();
  }
}
