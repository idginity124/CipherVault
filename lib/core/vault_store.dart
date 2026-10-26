import 'dart:io';
import 'dart:typed_data';
import 'vault_codec.dart';

class VaultStore {
  final File file;
  RandomAccessFile? _instanceLock;
  Future<void> acquireInstanceLock() async {
    await file.parent.create(recursive: true);
    final handle = await File("${file.path}.lock").open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive);
      _instanceLock = handle;
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  Future<void> releaseInstanceLock() async {
    await _instanceLock?.close();
    _instanceLock = null;
  }

  VaultStore(this.file);
  File get previous => File('${file.path}.previous');
  bool get exists => file.existsSync() || previous.existsSync();
  Future<Uint8List> read() async {
    final source = file.existsSync() ? file : previous;
    if (await source.length() > VaultCodec.maxBytes) {
      throw const FormatException('Kasa çok büyük.');
    }
    return source.readAsBytes();
  }

  Future<void> write(Uint8List bytes, {bool create = false}) async {
    if (create && exists) throw StateError('Mevcut kasanın üzerine yazılamaz.');
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.pending');
    await temp.writeAsBytes(bytes, flush: true);
    // Every on-disk slot is encrypted. Preserve the last complete version.
    if (file.existsSync()) {
      await file.copy(previous.path);
    }
    try {
      if (Platform.isWindows && file.existsSync()) await file.delete();
      await temp.rename(file.path);
    } catch (_) {
      if (!file.existsSync() && previous.existsSync()) {
        await previous.copy(file.path);
      }
      rethrow;
    }
    if (!Platform.isWindows) {
      // Best effort permission tightening; encryption does not depend on chmod.
      try {
        await Process.run('chmod', ['600', file.path]);
      } catch (_) {}
    }
  }
}
