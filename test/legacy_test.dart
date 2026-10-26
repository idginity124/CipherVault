import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as cipher;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ciphervault_mobile/legacy/vault_entry.dart' as old;
import 'package:ciphervault_mobile/core/legacy_import.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Mobile Hive migration decrypts legacy CBC and GCM without changing old records',
    () async {
      final dir = await Directory.systemTemp.createTemp('cv-legacy-');
      final key = cipher.Key.fromSecureRandom(32);
      String encrypted(String value, bool modern) {
        final iv = cipher.IV.fromSecureRandom(modern ? 12 : 16);
        final enc = cipher.Encrypter(
          cipher.AES(
            key,
            mode: modern ? cipher.AESMode.gcm : cipher.AESMode.cbc,
          ),
        );
        return '${modern ? 'CV2:' : ''}${jsonEncode({'v': 2, 'iv': iv.base64, 'data': enc.encrypt(value, iv: iv).base64})}';
      }

      try {
        Hive.init(dir.path);
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(old.VaultEntryAdapter());
        }
        final box = await Hive.openBox<old.VaultEntry>('vaultBox');
        final gcm = encrypted('gcm-example-secret', true),
            cbc = encrypted('cbc-example-secret', false);
        await box.add(
          old.VaultEntry(
            title: 'Demo',
            username: 'demo',
            password: gcm,
            notes: cbc,
            url: '',
            category: 'Genel',
          ),
        );
        await box.close();
        final migrated = await readLegacyMobile(
          directory: dir.path,
          readKey: () async => key.base64,
        );
        expect(migrated.single.password, 'gcm-example-secret');
        expect(migrated.single.notes, 'cbc-example-secret');
        await expectLater(
          readLegacyMobile(directory: dir.path, readKey: () async => null),
          throwsStateError,
        );
        final unchanged = await Hive.openBox<old.VaultEntry>('vaultBox');
        expect(unchanged.values.single.password, gcm);
        expect(unchanged.values.single.notes, cbc);
        await unchanged.close();
      } finally {
        await Hive.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
