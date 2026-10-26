import 'package:flutter/foundation.dart';
import 'entry.dart';
import 'vault_codec.dart';
import 'vault_store.dart';

class VaultController extends ChangeNotifier {
  final VaultStore store;
  VaultController(this.store);
  Uint8List? _key, _salt;
  Map<String, dynamic> _params = {...VaultCodec.defaults};
  List<Entry> _entries = [];
  int _epoch = 0;
  bool busy = false;
  Uint8List? _pendingImport;
  bool get hasPendingImport => _pendingImport != null;
  void queueImport(Uint8List bytes) {
    VaultCodec.parse(bytes);
    _pendingImport = Uint8List.fromList(bytes);
    notifyListeners();
  }

  Uint8List? takePendingImport() {
    final bytes = _pendingImport;
    _pendingImport = null;
    return bytes;
  }

  bool get locked => _key == null;
  bool get exists => store.exists;
  List<Entry> get entries => List.unmodifiable(_entries);

  Future<void> unlock(String password, {bool create = false}) async {
    if (busy || !locked) return;
    busy = true;
    final epoch = _epoch;
    notifyListeners();
    Uint8List? key;
    try {
      late Uint8List salt;
      late Map<String, dynamic> params;
      late List<Entry> entries;
      if (create) {
        if (password.length < 12) {
          throw ArgumentError('En az 12 karakter kullan.');
        }
        salt = VaultCodec.random(16);
        params = {...VaultCodec.defaults};
        key = await VaultCodec.derive(password, salt, params);
        entries = [];
        final bytes = await VaultCodec.seal([], key, salt, params);
        if (epoch != _epoch) return;
        await store.write(bytes, create: true);
      } else {
        final result = await VaultCodec.open(await store.read(), password);
        key = result.key;
        salt = result.salt;
        params = result.params;
        entries = result.entries.map(Entry.fromJson).toList();
      }
      if (epoch != _epoch) return;
      _key = key;
      key = null;
      _salt = salt;
      _params = params;
      _entries = entries;
    } finally {
      key?.fillRange(0, key.length, 0);
      busy = false;
      notifyListeners();
    }
  }

  void lock() {
    _epoch++;
    _key?.fillRange(0, _key!.length, 0);
    _key = null;
    _salt = null;
    _entries = [];
    notifyListeners();
  }

  Future<void> _commit(List<Entry> next) async {
    if (locked || busy) throw StateError('Önce kasanın kilidini aç.');
    if (next.length > 10000) {
      throw const FormatException("En fazla 10.000 kayıt desteklenir.");
    }
    busy = true;
    final epoch = _epoch;
    notifyListeners();
    try {
      final bytes = await VaultCodec.seal(
        next.map((e) => e.toJson()).toList(),
        _key!,
        _salt!,
        _params,
      );
      if (epoch != _epoch) return;
      await store.write(bytes);
      if (epoch == _epoch) _entries = next;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> save(Entry entry) =>
      _commit([..._entries.where((e) => e.id != entry.id), entry]);
  Future<void> delete(String id) =>
      _commit(_entries.where((e) => e.id != id).toList());
  Future<int> importEncrypted(Uint8List bytes, String password) async {
    if (locked || busy) throw StateError('Önce kasanın kilidini aç.');
    final epoch = _epoch;
    final result = await VaultCodec.open(bytes, password);
    try {
      if (epoch != _epoch) throw StateError('Kasa kilitlendi.');
      return await merge(result.entries.map(Entry.fromJson).toList());
    } finally {
      result.key.fillRange(0, result.key.length, 0);
    }
  }

  Future<int> merge(List<Entry> incoming) async {
    final next = [..._entries];
    var added = 0;
    for (final e in incoming) {
      // Duplicate imports never overwrite existing records.
      if (next.any(
        (v) =>
            v.title == e.title &&
            v.username == e.username &&
            v.password == e.password &&
            v.url == e.url &&
            v.notes == e.notes &&
            v.category == e.category,
      )) {
        continue;
      }
      next.add(
        Entry(
          title: e.title,
          username: e.username,
          password: e.password,
          url: e.url,
          notes: e.notes,
          category: e.category,
          createdAt: e.createdAt,
        ),
      );
      added++;
    }
    if (next.length > 10000) {
      throw const FormatException('En fazla 10.000 kayıt desteklenir.');
    }
    if (added > 0) await _commit(next);
    return added;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (locked || busy) throw StateError('Önce kasanın kilidini aç.');
    if (newPassword.length < 12) {
      throw ArgumentError('En az 12 karakter kullan.');
    }
    busy = true;
    final epoch = _epoch;
    notifyListeners();
    Uint8List? newKey;
    try {
      final verified = await VaultCodec.open(await store.read(), oldPassword);
      verified.key.fillRange(0, verified.key.length, 0);
      final salt = VaultCodec.random(16);
      newKey = await VaultCodec.derive(newPassword, salt, VaultCodec.defaults);
      if (epoch != _epoch) return;
      final bytes = await VaultCodec.seal(
        _entries.map((e) => e.toJson()).toList(),
        newKey,
        salt,
        VaultCodec.defaults,
      );
      if (epoch != _epoch) return;
      await store.write(bytes);
      if (epoch != _epoch) return;
      _key?.fillRange(0, _key!.length, 0);
      _key = newKey;
      newKey = null;
      _salt = salt;
      _params = {...VaultCodec.defaults};
    } finally {
      newKey?.fillRange(0, newKey.length, 0);
      busy = false;
      notifyListeners();
    }
  }

  Future<Uint8List> exportEncrypted(String password) async {
    if (locked || busy) throw StateError('Kasa kilitli.');
    if (password.length < 12) {
      throw ArgumentError('Aktarım parolası en az 12 karakter olmalı.');
    }
    final epoch = _epoch;
    final salt = VaultCodec.random(16);
    final data = _entries.map((e) => e.toJson()).toList();
    final key = await VaultCodec.derive(password, salt, VaultCodec.defaults);
    try {
      if (epoch != _epoch) throw StateError('Kasa kilitlendi.');
      final bytes = await VaultCodec.seal(data, key, salt, VaultCodec.defaults);
      if (epoch != _epoch) throw StateError('Kasa kilitlendi.');
      return bytes;
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }
}
