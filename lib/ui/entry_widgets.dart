part of 'screens.dart';

class EntryDetail extends StatefulWidget {
  final Entry entry;
  final VoidCallback onEdit, onDelete;
  const EntryDetail({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  State<EntryDetail> createState() => _EntryDetailState();
}

class _EntryDetailState extends State<EntryDetail> {
  bool reveal = false;
  Timer? hide;
  @override
  void dispose() {
    hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    Widget field(String label, String value, {bool secret = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: secret
                    ? Text(
                        reveal ? value : '••••••••••••',
                        style: const TextStyle(fontSize: 19),
                      )
                    : SelectableText(
                        value.isEmpty ? '—' : value,
                        style: const TextStyle(fontSize: 17),
                      ),
              ),
              if (secret)
                IconButton(
                  tooltip: reveal ? 'Gizle' : '15 saniye göster',
                  onPressed: () {
                    hide?.cancel();
                    setState(() => reveal = !reveal);
                    if (reveal) {
                      hide = Timer(const Duration(seconds: 15), () {
                        if (mounted) setState(() => reveal = false);
                      });
                    }
                  },
                  icon: Icon(
                    reveal
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              if (value.isNotEmpty)
                IconButton(
                  tooltip: 'Kopyala',
                  onPressed: () async {
                    await ClipboardGuard.copy(value);
                    if (context.mounted) {
                      message(
                        context,
                        'Kopyalandı. Pano 30 saniye sonra temizlenir.',
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.key_rounded, size: 38, color: Color(0xff65d7c4)),
          const SizedBox(height: 20),
          Text(
            e.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(e.category),
          const SizedBox(height: 24),
          field('Kullanıcı adı', e.username),
          field('Parola', e.password, secret: true),
          field('Web sitesi', e.url),
          field('Notlar', e.notes),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Düzenle'),
              ),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Kaydı sil'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EntryEditor extends StatefulWidget {
  final Entry? entry;
  const EntryEditor({super.key, this.entry});
  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> fields;
  bool show = false;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    fields = [
      e?.title ?? '',
      e?.username ?? '',
      e?.password ?? '',
      e?.url ?? '',
      e?.category ?? 'Genel',
      e?.notes ?? '',
    ].map((v) => TextEditingController(text: v)).toList();
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.clear();
      f.dispose();
    }
    super.dispose();
  }

  void generate() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*-_';
    final random = Random.secure();
    fields[2].text = List.generate(
      24,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.entry == null ? 'Yeni kayıt' : 'Kaydı düzenle'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              6,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: fields[i],
                  obscureText: i == 2 && !show,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLines: i == 5 ? 3 : 1,
                  maxLength: i == 5 ? 10000 : 1000,
                  validator: (v) =>
                      (i == 0 || i == 2) && (v == null || v.trim().isEmpty)
                      ? 'Bu alan gerekli.'
                      : null,
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: [
                      'Başlık',
                      'Kullanıcı adı',
                      'Parola',
                      'Web sitesi',
                      'Kategori',
                      'Notlar',
                    ][i],
                    suffixIcon: i == 2
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Güçlü parola üret',
                                onPressed: generate,
                                icon: const Icon(Icons.casino_outlined),
                              ),
                              IconButton(
                                tooltip: 'Göster / gizle',
                                onPressed: () => setState(() => show = !show),
                                icon: Icon(
                                  show
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          Navigator.pop(
            context,
            Entry(
              id: widget.entry?.id,
              title: fields[0].text.trim(),
              username: fields[1].text.trim(),
              password: fields[2].text,
              url: fields[3].text.trim(),
              category: fields[4].text.trim().isEmpty
                  ? 'Genel'
                  : fields[4].text.trim(),
              notes: fields[5].text,
              createdAt: widget.entry?.createdAt,
            ),
          );
        },
        child: const Text('Kaydet'),
      ),
    ],
  );
}
