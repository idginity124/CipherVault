import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ciphervault_mobile/core/vault_codec.dart';
import 'package:ciphervault_mobile/core/vault_store.dart';
import 'package:ciphervault_mobile/core/vault_controller.dart';
import 'package:ciphervault_mobile/core/transfer.dart';
import 'package:ciphervault_mobile/core/entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Python v1: Argon2id, Unicode, GCM AAD and shared file format',
    () async {
      final old = await File('test/fixtures/python-v1.cvault').readAsBytes();
      final result = await VaultCodec.open(old, 'fixture-only-password');
      expect(result.entries.single['title'], 'Örnek hesap');
      final rewritten = await VaultCodec.seal(
        result.entries,
        result.key,
        result.salt,
        result.params,
      );
      expect(rewritten, isNot(old));
      expect(
        base64Encode(VaultCodec.parse(rewritten).nonce),
        isNot(base64Encode(VaultCodec.parse(old).nonce)),
      );
      await File(
        '${Directory.systemTemp.path}/ciphervault-dart-interop.cvault',
      ).writeAsBytes(rewritten);
      final corrupt = Uint8List.fromList(old)..[old.length - 1] ^= 1;
      await expectLater(
        VaultCodec.open(corrupt, 'fixture-only-password'),
        throwsA(anything),
      );
      await expectLater(
        VaultCodec.open(old, 'wrong password'),
        throwsA(anything),
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
  test('Python v0 read compatibility', () async {
    final result = await VaultCodec.open(
      await File('test/fixtures/python-v0.cvault').readAsBytes(),
      'fixture-only-password',
    );
    expect(result.entries, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));
  test('KDF input is bounded before allocation', () {
    expect(
      () => VaultCodec.validateParams({
        ...VaultCodec.defaults,
        'memory_cost_kib': 99999999,
      }),
      throwsFormatException,
    );
    expect(
      () => VaultCodec.validateParams({...VaultCodec.defaults, 'lanes': 0}),
      throwsFormatException,
    );
    expect(() => VaultCodec.parse(Uint8List(3)), throwsFormatException);
  });
  test(
    'QR reassembly rejects plaintext, mixtures and bounds; handles order/repeats',
    () async {
      final data = await File('test/fixtures/python-v1.cvault').readAsBytes();
      final frames = Transfer.encode(data), receiver = TransferReceiver();
      Uint8List? got;
      for (final f in frames.reversed) {
        got = receiver.accept(f) ?? got;
      }
      expect(got, data);
      expect(receiver.accept(frames.last), data);
      expect(
        () => TransferReceiver().accept('{"password":"plain"}'),
        throwsFormatException,
      );
      final mixed = Transfer.encode(data);
      expect(() => receiver.accept(mixed.first), throwsFormatException);
      final malicious = jsonDecode(frames.first) as Map<String, dynamic>;
      malicious['total'] = 99999;
      expect(
        () => TransferReceiver().accept(jsonEncode(malicious)),
        throwsFormatException,
      );
      final expired = TransferReceiver();
      expired.accept(frames.first, now: DateTime(2026));
      expired.accept(
        mixed.first,
        now: DateTime(2026).add(const Duration(minutes: 4)),
      );
      expect(expired.count, 1);
    },
  );
  test(
    'Atomic encrypted save retains recovery version and refuses overwrite on creation',
    () async {
      final dir = await Directory.systemTemp.createTemp('ciphervault-test-');
      try {
        final store = VaultStore(File('${dir.path}/vault.cvault'));
        await store.write(Uint8List.fromList([1, 2, 3]), create: true);
        await expectLater(
          store.write(Uint8List(1), create: true),
          throwsStateError,
        );
        await store.write(Uint8List.fromList([4, 5, 6]));
        expect(await store.previous.readAsBytes(), [1, 2, 3]);
        await store.file.delete();
        expect(await store.read(), [1, 2, 3]);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'Locked controller cannot read records, mutate, import or export',
    () async {
      final dir = await Directory.systemTemp.createTemp('ciphervault-locked-');
      try {
        final c = VaultController(VaultStore(File('${dir.path}/vault.cvault')));
        expect(c.locked, isTrue);
        expect(c.entries, isEmpty);
        await expectLater(
          c.exportEncrypted('fixture-only-password'),
          throwsStateError,
        );
        await expectLater(
          c.importEncrypted(Uint8List(0), 'x'),
          throwsStateError,
        );
        await expectLater(c.delete('unknown'), throwsStateError);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'Full session: encrypted persistence, password rotation and duplicate-safe import',
    () async {
      final dir = await Directory.systemTemp.createTemp('cv-session-');
      try {
        final store = VaultStore(File('${dir.path}/vault.cvault'));
        final c = VaultController(store);
        await c.unlock('first-example-password', create: true);
        await c.save(
          Entry(
            title: 'Example title',
            username: 'demo',
            password: 'secret-only-example',
          ),
        );
        final before = await store.read();
        expect(
          utf8.decode(before, allowMalformed: true),
          isNot(contains('Example title')),
        );
        final exported = await c.exportEncrypted('transfer-example-password');
        expect(
          await c.importEncrypted(exported, 'transfer-example-password'),
          0,
        );
        await expectLater(
          c.changePassword('wrong', 'next-example-password'),
          throwsA(anything),
        );
        expect(c.locked, isFalse);
        await c.changePassword(
          'first-example-password',
          'next-example-password',
        );
        c.lock();
        expect(c.entries, isEmpty);
        await expectLater(
          c.unlock('first-example-password'),
          throwsA(anything),
        );
        expect(c.locked, isTrue);
        await c.unlock('next-example-password');
        expect(c.entries.single.password, 'secret-only-example');
        final save = c.save(
          Entry(title: 'Cancelled save', username: '', password: 'example'),
        );
        c.lock();
        await save;
        expect(c.locked, isTrue);
        expect(c.entries, isEmpty);
        await c.unlock('next-example-password');
        expect(c.entries.length, 1);
      } finally {
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
  test(
    'Lock while unlocking invalidates late authentication results',
    () async {
      final dir = await Directory.systemTemp.createTemp('cv-lock-race-');
      try {
        final store = VaultStore(File('${dir.path}/vault.cvault'));
        await store.write(
          await File('test/fixtures/python-v1.cvault').readAsBytes(),
          create: true,
        );
        final c = VaultController(store);
        final unlock = c.unlock('fixture-only-password');
        c.lock();
        await unlock;
        expect(c.locked, isTrue);
        expect(c.entries, isEmpty);
        expect(c.busy, isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test(
    'Encrypted import may wait across background lock; plaintext cannot be queued',
    () async {
      final c = VaultController(VaultStore(File('/unused-vault')));
      final encrypted = await File(
        'test/fixtures/python-v1.cvault',
      ).readAsBytes();
      c.queueImport(encrypted);
      c.lock();
      expect(c.hasPendingImport, isTrue);
      expect(c.entries, isEmpty);
      expect(c.takePendingImport(), encrypted);
      expect(c.hasPendingImport, isFalse);
      expect(
        () => c.queueImport(Uint8List.fromList(utf8.encode('plaintext'))),
        throwsFormatException,
      );
    },
  );
}
