# Validation — Flutter consolidation

Verified locally on Linux with synthetic data only:

- Python CVLT v0 and v1 import, Unicode records and Flutter→Python re-opening.
- GCM corruption and wrong-password rejection; KDF resource bounds.
- New vault creation, encrypted saves, master-password rotation, duplicate-safe import.
- Locked API rejection and cancellation of delayed unlock/save after locking.
- Encrypted previous-version recovery and refusal to overwrite an existing vault on creation.
- Multipart encrypted QR ordering, duplicates, mixed IDs, limits, plaintext rejection and timeout reset.
- Actual Hive/secure-storage-format migration with GCM and legacy CBC fields; missing-key failure preserves old data.
- Responsive desktop/mobile widget layouts and background lock dismissal of detail routes.

`test/fixtures` contains generated sample-only encrypted vaults with the documented test passphrase `fixture-only-password`. Never replace them with a real vault. UI golden images use fake sample records and bundled fonts, not personal credentials.

Native Linux release and Android debug build validation is recorded in the handoff. Windows source/runner is present but must be compiled and exercised on Windows. Real Android camera/QR scanning, signed in-place upgrade, physical-device lifecycle and OS clipboard behavior still require device checks. Automated tests do not constitute an independent security audit.

Final local checks: `flutter analyze` clean; 13 automated tests passed. Linux release built and launched with an isolated application-data directory; new-vault creation and rendering succeeded. Android ARM64 release built (about 37 MB) and the exported preview was signed with the standard development key; APK signature verification passed. Windows, iOS and macOS native builds were not performed.
