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
  final qrKey = GlobalKey(debugLabel: 'encrypted-transfer-scanner');
  final receiver = TransferReceiver();
  StreamSubscription<Barcode>? subscription;
  QRViewController? camera;
  bool completed = false;
  String? lastCode;
  DateTime? lastSeen;
  String hint = 'Diğer cihazdaki şifreli aktarım kodunu okut.';

  void onCreated(QRViewController controller) {
    camera = controller;
    subscription = controller.scannedDataStream.listen((barcode) {
      final raw = barcode.code;
      if (!mounted || completed || raw == null) return;
      final now = DateTime.now();
      if (raw == lastCode &&
          lastSeen != null &&
          now.difference(lastSeen!) < const Duration(seconds: 1)) {
        return;
      }
      lastCode = raw;
      lastSeen = now;
      try {
        final bytes = receiver.accept(raw);
        if (bytes != null) {
          completed = true;
          Navigator.pop(context, bytes);
          return;
        }
        setState(
          () => hint = '${receiver.count} / ${receiver.total} parça alındı.',
        );
      } catch (_) {
        setState(
          () => hint =
              'Bu QR okunamadı. Aynı aktarımın şifreli parçalarını okut.',
        );
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    receiver.clear();
    // QRView owns and disposes its native camera controller.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Şifreli QR tara'),
      actions: [
        IconButton(
          tooltip: 'Feneri aç / kapat',
          icon: const Icon(Icons.flashlight_on_outlined),
          onPressed: () async {
            try {
              await camera?.toggleFlash();
            } catch (_) {
              if (context.mounted)
                message(context, 'Fener bu cihazda kullanılamıyor.');
            }
          },
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: QRView(
            key: qrKey,
            onQRViewCreated: onCreated,
            formatsAllowed: const [BarcodeFormat.qrcode],
            onPermissionSet: (_, granted) {
              if (!granted && mounted) {
                setState(
                  () => hint =
                      'QR taramak için kamera izni gerekli. Dosya aktarımını da kullanabilirsin.',
                );
              }
            },
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).colorScheme.primary,
              borderRadius: 20,
              borderLength: 32,
              borderWidth: 4,
              cutOutSize: 280,
            ),
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
