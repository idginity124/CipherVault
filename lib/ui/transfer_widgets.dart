part of 'screens.dart';

Future<String?> passwordDialog(
  BuildContext context, {
  bool create = false,
  bool master = false,
}) async {
  final pass = TextEditingController(), confirm = TextEditingController();
  final form = GlobalKey<FormState>();
  try {
    return await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          create
              ? (master ? 'Yeni ana parola' : 'Aktarım parolası oluştur')
              : 'Mevcut parolayı gir',
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    create
                        ? (master
                              ? 'Kasanın yeni ana parolasını seç. Eski yedeklerin parolası değişmez.'
                              : 'Alıcı bu parolayla kayıtları açacak. En az 12 karakter seç ve QR kodundan ayrı paylaş.')
                        : 'Kaynak kasanın ana parolasını veya aktarım için oluşturduğun parolayı kullan.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: pass,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'Parola'),
                    validator: (v) =>
                        v == null || v.isEmpty || (create && v.length < 12)
                        ? 'Parolayı kontrol et.'
                        : null,
                  ),
                  if (create) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirm,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Parolayı tekrar yaz',
                      ),
                      validator: (v) =>
                          v != pass.text ? 'Parolalar eşleşmiyor.' : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(c, pass.text);
            },
            child: const Text('Devam et'),
          ),
        ],
      ),
    );
  } finally {
    // Allow the dialog route to finish disposing its fields.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    pass.clear();
    confirm.clear();
    pass.dispose();
    confirm.dispose();
  }
}

class QrTransferDialog extends StatefulWidget {
  final List<String> frames;
  const QrTransferDialog({super.key, required this.frames});
  @override
  State<QrTransferDialog> createState() => _QrTransferDialogState();
}

class _QrTransferDialogState extends State<QrTransferDialog> {
  int index = 0;
  Timer? expiry;
  @override
  void initState() {
    super.initState();
    expiry = Timer(const Duration(minutes: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Şifreli aktarım'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Diğer cihazda “Şifreli QR tara” seçeneğini aç. Parçaları sırayla okut. Bu ekran 3 dakika sonra kapanır.',
            ),
            const SizedBox(height: 18),
            ColoredBox(
              color: Colors.white,
              child: QrImageView(
                data: widget.frames[index],
                size: 320,
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 18),
            Text('Parça ${index + 1} / ${widget.frames.length}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Önceki',
                  onPressed: index > 0 ? () => setState(() => index--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Sonraki',
                  onPressed: index + 1 < widget.frames.length
                      ? () => setState(() => index++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Kapat'),
      ),
    ],
  );
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final scanner = MobileScannerController();
  final receiver = TransferReceiver();
  bool completed = false;
  String hint =
      'Yalnızca CipherVault 2 ile oluşturulan şifreli QR kodları kabul edilir.';
  @override
  void dispose() {
    receiver.clear();
    scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Şifreli QR tara')),
    body: Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: scanner,
            onDetect: (capture) {
              if (completed) return;
              for (final code in capture.barcodes) {
                if (code.rawValue == null) continue;
                try {
                  final bytes = receiver.accept(code.rawValue!);
                  if (bytes != null) {
                    completed = true;
                    Navigator.pop(context, bytes);
                    return;
                  }
                  setState(
                    () => hint =
                        '${receiver.count} / ${receiver.total} parça alındı.',
                  );
                } catch (_) {
                  setState(
                    () => hint =
                        'Bu QR okunamadı. Aynı aktarımın şifreli parçalarını okut.',
                  );
                }
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(hint, textAlign: TextAlign.center),
        ),
      ],
    ),
  );
}
