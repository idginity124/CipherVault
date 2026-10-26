part of 'screens.dart';

class VaultScreen extends StatefulWidget {
  final VaultController controller;
  final VoidCallback onLock, onTheme;
  const VaultScreen({
    super.key,
    required this.controller,
    required this.onLock,
    required this.onTheme,
  });
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String search = '', category = 'Tümü';
  String? selected;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.controller.locked) return;
      final pending = widget.controller.takePendingImport();
      if (pending == null) return;
      try {
        await importData(pending);
      } catch (_) {
        if (mounted) {
          message(
            context,
            'Dosya açılamadı. Kaynak kasanın parolasını kontrol et.',
          );
        }
      }
    });
  }

  bool get mobile => Platform.isAndroid || Platform.isIOS;
  List<Entry> get filtered =>
      widget.controller.entries
          .where(
            (e) =>
                (category == 'Tümü' || e.category == category) &&
                '${e.title} ${e.username} ${e.url}'.toLowerCase().contains(
                  search.toLowerCase(),
                ),
          )
          .toList()
        ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
  Future<void> edit([Entry? e]) async {
    final value = await showDialog<Entry>(
      context: context,
      builder: (_) => EntryEditor(entry: e),
    );
    if (value == null || widget.controller.locked) return;
    try {
      await widget.controller.save(value);
      if (mounted) setState(() => selected = value.id);
    } catch (_) {
      if (mounted) {
        message(context, 'Kayıt saklanamadı. Önceki veriler korundu.');
      }
    }
  }

  Future<void> remove(Entry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kaydı sil?'),
        content: Text(
          '“${e.title}” kasandan kaldırılacak. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || widget.controller.locked) return;
    try {
      await widget.controller.delete(e.id);
      if (mounted) setState(() => selected = null);
    } catch (_) {
      if (mounted) message(context, 'Kayıt silinemedi.');
    }
  }

  Future<void> transfer(String action) async {
    try {
      if (action == 'password') {
        final old = await passwordDialog(context);
        if (old == null || !mounted || widget.controller.locked) return;
        final next = await passwordDialog(context, create: true, master: true);
        if (next == null || widget.controller.locked) return;
        await widget.controller.changePassword(old, next);
        if (mounted) {
          message(
            context,
            'Ana parola değiştirildi. Eski yedekler eski parolalarıyla açılır.',
          );
        }
        return;
      }
      if (action == 'legacy') {
        if (!mobile) {
          message(
            context,
            'Eski masaüstü kasanı “Şifreli dosyadan içe aktar” ile seç.',
          );
          return;
        }
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Eski mobil kayıtlarını taşı'),
            content: const Text(
              'Bu cihazdaki önceki kasanın kayıtları yeni kasaya kopyalanır. Eski veriler ve cihaz anahtarı silinmez.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Kayıtları taşı'),
              ),
            ],
          ),
        );
        if (ok != true || widget.controller.locked) return;
        final data = await readLegacyMobile();
        if (widget.controller.locked) return;
        final n = await widget.controller.merge(data);
        if (mounted) message(context, '$n kayıt taşındı.');
        return;
      }
      if (action == 'scan') {
        if (!mobile) return;
        final bytes = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(builder: (_) => const ScanScreen()),
        );
        if (bytes != null && mounted && !widget.controller.locked) {
          await importData(bytes);
        }
        return;
      }
      if (action == 'import') {
        final file = await openFile(
          acceptedTypeGroups: [
            const XTypeGroup(
              label: 'CipherVault',
              extensions: ['cvault'],
              uniformTypeIdentifiers: ['public.data'],
            ),
          ],
        );
        if (file == null) return;
        if (await file.length() > VaultCodec.maxBytes) {
          throw const FormatException('Kasa çok büyük.');
        }
        final bytes = await file.readAsBytes();
        if (mounted && !widget.controller.locked) {
          await importData(bytes);
        } else {
          // Native mobile file pickers may background and lock the app.
          // Keep only encrypted bytes, then require authentication again.
          widget.controller.queueImport(bytes);
        }
        return;
      }
      final pass = await passwordDialog(context, create: true);
      if (pass == null || widget.controller.locked) return;
      if (mounted) message(context, 'Şifreli aktarım hazırlanıyor…');
      final bytes = await widget.controller.exportEncrypted(pass);
      if (!mounted || widget.controller.locked) return;
      if (action == 'qr') {
        final frames = Transfer.encode(bytes);
        await showDialog<void>(
          context: context,
          builder: (_) => QrTransferDialog(frames: frames),
        );
        return;
      }
      if (mobile) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(bytes, mimeType: 'application/octet-stream'),
            ],
            fileNameOverrides: ['CipherVault.cvault'],
            title: 'Şifreli kasa yedeği',
          ),
        );
      } else {
        final location = await getSaveLocation(
          suggestedName: 'CipherVault.cvault',
        );
        if (location != null) await XFile.fromData(bytes).saveTo(location.path);
      }
    } catch (e) {
      if (mounted) {
        message(
          context,
          e is FormatException
              ? e.message
              : 'Aktarım tamamlanamadı. Dosyanı, parolanı ve erişim izinlerini kontrol et.',
        );
      }
    }
  }

  Future<void> importData(Uint8List bytes) async {
    final password = await passwordDialog(context);
    if (password == null || widget.controller.locked) return;
    final n = await widget.controller.importEncrypted(bytes, password);
    if (mounted) {
      message(context, '$n kayıt eklendi. Tekrarlanan kayıtlar atlandı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.controller.entries, items = filtered;
    final categories = [
      'Tümü',
      ...all.map((e) => e.category).toSet().toList()..sort(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final matches = items.where((e) => e.id == selected);
    final chosen = matches.isEmpty ? null : matches.first;
    final menu = PopupMenuButton<String>(
      tooltip: 'Aktarım ve yedekleme',
      onSelected: transfer,
      enabled: !widget.controller.busy,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'export',
          child: Text('Şifreli yedek oluştur'),
        ),
        const PopupMenuItem(
          value: 'import',
          child: Text('Şifreli dosyadan içe aktar'),
        ),
        const PopupMenuItem(value: 'qr', child: Text('Şifreli QR ile gönder')),
        if (mobile)
          const PopupMenuItem(value: 'scan', child: Text('Şifreli QR tara')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'password',
          child: Text('Ana parolayı değiştir'),
        ),
        const PopupMenuItem(
          value: 'legacy',
          child: Text('Eski CipherVault kayıtlarını taşı'),
        ),
      ],
      icon: const Icon(Icons.import_export_rounded),
    );
    return Scaffold(
      appBar: AppBar(
        title: brand(),
        actions: [
          menu,
          IconButton(
            tooltip: 'Temayı değiştir',
            onPressed: widget.onTheme,
            icon: const Icon(Icons.contrast_rounded),
          ),
          IconButton(
            tooltip: 'Kasayı kilitle',
            onPressed: widget.onLock,
            icon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: !wide
          ? FloatingActionButton.extended(
              onPressed: widget.controller.busy ? null : () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Yeni kayıt'),
            )
          : null,
      body: Column(
        children: [
          if (widget.controller.busy)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: Row(
              children: [
                if (wide)
                  SizedBox(
                    width: 230,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'KİŞİSEL KASAM',
                            style: TextStyle(fontSize: 11, letterSpacing: 2),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${all.length} kayıt',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: widget.controller.busy
                                ? null
                                : () => edit(),
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni kayıt'),
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: ListView(
                              children: categories
                                  .map(
                                    (v) => ListTile(
                                      dense: true,
                                      selected: category == v,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      leading: Icon(
                                        v == 'Tümü'
                                            ? Icons.grid_view_rounded
                                            : Icons.folder_outlined,
                                        size: 19,
                                      ),
                                      title: Text(v),
                                      onTap: () => setState(() => category = v),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const Divider(),
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.shield_outlined,
                              color: Color(0xff65d7c4),
                            ),
                            title: Text(
                              'Cihazında şifreli',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              'Ana parola ile korunur',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 8 : 18, 20, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Her şey yerli yerinde.',
                          style: TextStyle(
                            fontSize: wide ? 28 : 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Parolaların, notların ve hesapların.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          onChanged: (v) => setState(() => search = v),
                          decoration: const InputDecoration(
                            hintText: 'Kasanda ara',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        if (!wide)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: categories
                                    .map(
                                      (v) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(v),
                                          selected: category == v,
                                          onSelected: (_) =>
                                              setState(() => category = v),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: items.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.key_outlined, size: 50),
                                      SizedBox(height: 16),
                                      Text('Burada henüz kayıt yok.'),
                                      SizedBox(height: 8),
                                      Text(
                                        'Yeni bir kayıt ekle veya eski kasanı içe aktar.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 90),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final e = items[i];
                                    return Card(
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 8,
                                            ),
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          child: Text(
                                            e.title.isEmpty
                                                ? '?'
                                                : e.title.characters.first
                                                      .toUpperCase(),
                                          ),
                                        ),
                                        title: Text(
                                          e.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          e.username.isEmpty
                                              ? e.category
                                              : e.username,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                        ),
                                        onTap: widget.controller.busy
                                            ? null
                                            : () {
                                                if (wide) {
                                                  setState(
                                                    () => selected = e.id,
                                                  );
                                                } else {
                                                  Navigator.push<void>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => AnimatedBuilder(
                                                        animation:
                                                            widget.controller,
                                                        builder: (detailContext, _) {
                                                          final matching =
                                                              widget
                                                                  .controller
                                                                  .entries
                                                                  .where(
                                                                    (v) =>
                                                                        v.id ==
                                                                        e.id,
                                                                  );
                                                          if (matching
                                                              .isEmpty) {
                                                            return Scaffold(
                                                              appBar: AppBar(),
                                                              body: const Center(
                                                                child: Text(
                                                                  'Kayıt kaldırıldı.',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                          final current =
                                                              matching.first;
                                                          return Scaffold(
                                                            appBar: AppBar(
                                                              title: Text(
                                                                current.title,
                                                              ),
                                                            ),
                                                            body: SingleChildScrollView(
                                                              child: EntryDetail(
                                                                key: ValueKey(
                                                                  current.id +
                                                                      current
                                                                          .updatedAt
                                                                          .toIso8601String(),
                                                                ),
                                                                entry: current,
                                                                onEdit: () =>
                                                                    edit(
                                                                      current,
                                                                    ),
                                                                onDelete: () async {
                                                                  await remove(
                                                                    current,
                                                                  );
                                                                  if (detailContext
                                                                          .mounted &&
                                                                      !widget
                                                                          .controller
                                                                          .locked &&
                                                                      !widget
                                                                          .controller
                                                                          .entries
                                                                          .any(
                                                                            (
                                                                              v,
                                                                            ) =>
                                                                                v.id ==
                                                                                current.id,
                                                                          )) {
                                                                    Navigator.of(
                                                                      detailContext,
                                                                    ).pop();
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (wide)
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 24, 20),
                      child: Card(
                        child: chosen == null
                            ? const Center(
                                child: Text(
                                  'Ayrıntılarını görmek için bir kayıt seç.',
                                ),
                              )
                            : SingleChildScrollView(
                                child: EntryDetail(
                                  key: ValueKey(
                                    chosen.id +
                                        chosen.updatedAt.toIso8601String(),
                                  ),
                                  entry: chosen,
                                  onEdit: () => edit(chosen),
                                  onDelete: () => remove(chosen),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
