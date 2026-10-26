part of 'screens.dart';

class UnlockScreen extends StatefulWidget {
  final VaultController controller;
  const UnlockScreen({super.key, required this.controller});
  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final password = TextEditingController(), confirm = TextEditingController();
  String? error;
  bool visible = false;
  @override
  void dispose() {
    password.clear();
    password.dispose();
    confirm.clear();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final create = !widget.controller.exists;
    if (create && password.text != confirm.text) {
      setState(() => error = 'Parolalar eşleşmiyor.');
      return;
    }
    setState(() => error = null);
    try {
      await widget.controller.unlock(password.text, create: create);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = create
              ? 'Kasa oluşturulamadı. En az 12 karakter kullan; dosya erişimini kontrol et.'
              : 'Kasa açılamadı. Parolanı ve kasa dosyasını kontrol et.',
        );
      }
    } finally {
      password.clear();
      confirm.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final create = !widget.controller.exists, busy = widget.controller.busy;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                brand(),
                const SizedBox(height: 48),
                Text(
                  create ? 'Sadece sana ait.' : 'Tekrar hoş geldin.',
                  style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  create
                      ? 'Mobilde ve masaüstünde aynı kasa. Başlamak için güçlü bir ana parola oluştur.'
                      : 'Kayıtlarına ulaşmak için ana parolanla kasanın kilidini aç.',
                  style: TextStyle(
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.controller.hasPendingImport)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Aktarım dosyan hazır. Önce kendi kasanın kilidini aç.',
                    ),
                  ),
                const SizedBox(height: 30),
                TextField(
                  controller: password,
                  enabled: !busy,
                  autofocus: true,
                  obscureText: !visible,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) {
                    if (!busy) submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'Ana parola',
                    helperText: create
                        ? 'En az 12 karakter; birkaç kelimeden oluşan bir ifade kullanabilirsin.'
                        : null,
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => visible = !visible),
                      tooltip: 'Parolayı göster / gizle',
                      icon: Icon(
                        visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                if (create) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirm,
                    enabled: !busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Ana parolayı tekrar yaz',
                    ),
                  ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_outlined),
                    label: Text(
                      busy
                          ? 'Kasan hazırlanıyor…'
                          : create
                          ? 'Kasamı oluştur'
                          : 'Kilidi aç',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ana parolan cihazında saklanmaz. Unutursan parolanı sıfırlayamayız. Şifreli yedeğini ve parolanı güvenli bir yerde tut.',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
                if (create)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Eski CipherVault kaydın mı var? Yeni kasanı oluşturduktan sonra Aktarım menüsünden içe aktarabilirsin.',
                      style: TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
