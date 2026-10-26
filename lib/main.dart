import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'core/vault_controller.dart';
import 'core/vault_store.dart';
import 'ui/theme.dart';
import 'ui/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final store = VaultStore(
    File(p.join(dir.path, 'CipherVault', 'vault.cvault')),
  );
  try {
    await store.acquireInstanceLock();
    runApp(CipherVaultApp(controller: VaultController(store)));
  } catch (_) {
    runApp(
      MaterialApp(
        theme: vaultTheme(Brightness.dark),
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Kasa açılamadı. CipherVault başka bir pencerede açık olabilir veya veri klasörüne erişilemiyor.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CipherVaultApp extends StatefulWidget {
  final VaultController controller;
  const CipherVaultApp({super.key, required this.controller});
  @override
  State<CipherVaultApp> createState() => _CipherVaultAppState();
}

class _CipherVaultAppState extends State<CipherVaultApp>
    with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  Timer? idle;
  ThemeMode mode = ThemeMode.dark;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(changed);
  }

  void changed() {
    if (!widget.controller.locked) activity();
    if (mounted) setState(() {});
  }

  void activity() {
    idle?.cancel();
    if (!widget.controller.locked) {
      idle = Timer(const Duration(minutes: 5), lock);
    }
  }

  void lock() {
    idle?.cancel();
    navigator.currentState?.popUntil((r) => r.isFirst);
    ClipboardGuard.clear();
    widget.controller.lock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      lock();
    }
  }

  @override
  void dispose() {
    idle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => activity(),
    onPointerSignal: (_) => activity(),
    child: Focus(
      onKeyEvent: (_, _) {
        activity();
        return KeyEventResult.ignored;
      },
      child: MaterialApp(
        navigatorKey: navigator,
        title: 'CipherVault',
        debugShowCheckedModeBanner: false,
        theme: vaultTheme(Brightness.light),
        darkTheme: vaultTheme(Brightness.dark),
        themeMode: mode,
        home: widget.controller.locked
            ? UnlockScreen(controller: widget.controller)
            : VaultScreen(
                controller: widget.controller,
                onLock: lock,
                onTheme: () => setState(
                  () => mode = mode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                ),
              ),
      ),
    ),
  );
}

class ClipboardGuard {
  static String? _last;
  static Timer? _timer;
  static Future<void> copy(String value) async {
    _timer?.cancel();
    _last = value;
    await Clipboard.setData(ClipboardData(text: value));
    _timer = Timer(const Duration(seconds: 30), clear);
  }

  static Future<void> clear() async {
    _timer?.cancel();
    final last = _last;
    _last = null;
    if (last != null && (await Clipboard.getData('text/plain'))?.text == last) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  }
}
