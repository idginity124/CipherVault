import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ciphervault_mobile/main.dart';
import 'package:ciphervault_mobile/core/entry.dart';
import 'package:ciphervault_mobile/core/vault_controller.dart';
import 'package:ciphervault_mobile/core/vault_store.dart';

class PreviewController extends VaultController {
  bool closed;
  PreviewController({this.closed = false})
    : super(VaultStore(File('/unused-preview-vault')));
  @override
  bool get locked => closed;
  @override
  bool get exists => true;
  @override
  List<Entry> get entries => closed
      ? []
      : [
          Entry(
            id: 'one',
            title: 'Demo Mail',
            username: 'demo@example.invalid',
            password: 'example-only-not-real',
            category: 'Kişisel',
          ),
          Entry(
            id: 'two',
            title: 'Studio Workspace',
            username: 'demo',
            password: 'example-only-not-real',
            category: 'İş',
          ),
          Entry(
            id: 'three',
            title: 'Git hosting',
            username: 'sample-user',
            password: 'example-only-not-real',
            category: 'Geliştirme',
          ),
        ];
  @override
  void lock() {
    closed = true;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('CipherSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final (name, size) in [
    ('desktop', const Size(1280, 820)),
    ('mobile', const Size(390, 844)),
  ]) {
    testWidgets('$name layout, navigation and manual lock remove secrets', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = PreviewController();
      await tester.pumpWidget(
        RepaintBoundary(child: CipherVaultApp(controller: c)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Demo Mail'), findsOneWidget);
      expect(find.text('example-only-not-real'), findsNothing);
      await expectLater(
        find.byType(CipherVaultApp),
        matchesGoldenFile('goldens/$name.png'),
      );
      await tester.tap(find.text('Demo Mail'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Locking from background must also dismiss the mobile detail route.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.text('Tekrar hoş geldin.'), findsOneWidget);
      expect(find.text('demo@example.invalid'), findsNothing);
      expect(c.locked, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('locked UI never enters the vault without a master password', (
    tester,
  ) async {
    final c = PreviewController(closed: true);
    await tester.pumpWidget(CipherVaultApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Kilidi aç'), findsOneWidget);
    expect(find.text('Demo Mail'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
