# Validation — Flutter consolidation

## Initial 2.0.0 consolidation

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

## 2.0.1 distribution validation

- Replaced the Google ML Kit camera scanner with local ZXing/AVFoundation scanning. No Google ML Kit binaries remain in the Android bundle. Release Internet/network-state permissions are explicitly removed. Camera permission remains optional for installation.
- Android version 2.0.1+3: upload-key certificate matched the configured keystore; JAR signature and bundletool validation passed. The package ID is com.bulgan.ciphervault, target API 36, with PAGE_ALIGNMENT_16K and 64-bit ELF LOAD alignments at least 16 KiB.
- All 13 tests passed after the scanner change; static analysis is clean. Real Android camera and physical 16 KiB-device checks remain pending.
- Linux x64 built locally in an isolated official Ubuntu 22.04.5 environment with clang 14 and glibc 2.35. Required GLIBC symbols were inspected (maximum 2.34 in the executable); bundle metadata matches 2.0.1+3. DEB and portable tar packages include license/privacy notices.
- Windows x64 built with Flutter 3.47.7 on the manually dispatched Windows runner, run 40350268811. Windows SDK MakeAppx packaging/validation succeeded. Store identity, bundled MSVC runtime DLLs, SHA-256 manifests and all 536 MSIX block/whole-file hashes were independently checked after download. MSIX version is 2.0.1.0. Windows UI/WACK and Microsoft Store certification are not implied by package validation.
