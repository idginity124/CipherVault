import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../core/entry.dart';
import '../core/vault_codec.dart';
import '../core/vault_controller.dart';
import '../core/legacy_import.dart';
import '../core/transfer.dart';
import '../main.dart' show ClipboardGuard;

part 'unlock_screen.dart';
part 'vault_screen.dart';
part 'entry_widgets.dart';
part 'transfer_widgets.dart';

void message(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

Widget brand() => const Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.shield_outlined, color: Color(0xff65d7c4), size: 28),
    SizedBox(width: 10),
    Text(
      'CipherVault',
      style: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        letterSpacing: -.7,
      ),
    ),
  ],
);
