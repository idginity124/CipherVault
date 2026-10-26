# CipherVault

One Flutter application for an offline password vault on Android, Linux and Windows. The UI adapts from a phone list to a desktop category/list/detail workspace. Application source is available under GPL-3.0-only.

## Develop

```bash
flutter pub get
flutter run -d linux
flutter test
flutter analyze
```

Windows requires the Windows Flutter/Visual Studio desktop toolchain: `flutter build windows --release`. Build on Windows; the Linux host does not produce a Windows executable. Android: `flutter build apk --debug` for a development preview. Distribution builds require your original signing key; credentials belong in ignored `android/key.properties`, never in Git.

The application uses one shared `lib/` tree. Platform directories contain native runner/build configuration, not separate application implementations. On the maintainer’s PC, the canonical project is `/home/ekrem/Projects/CipherVault`.

## Included

- Entire-vault AES-256-GCM encryption; Argon2id master-password derivation, off the UI isolate.
- The same authenticated CVLT v1 format used by the old Python application.
- Add/edit/delete, search, categories, random password generation and light/dark appearance.
- Master password required on every unlock; lock on background and after five minutes without interaction.
- Short-lived password reveal; guarded clipboard cleanup after 30 seconds and when locking.
- Encrypted file export/import, separately password-protected QR transfer, duplicate-safe imports.
- Explicit read-only migration from the previous mobile Hive store.
- Master-password changes; encrypted previous-version recovery file.
- Local fonts; no account, telemetry or network font loading.

## Migrating your existing records

Create a new vault with a master passphrase of at least 12 characters first. Existing user data is never automatically overwritten.

**Old Python desktop vault:** in the transfer menu choose “Şifreli dosyadan içe aktar”, select `~/.ciphervault/secure_vault.cvault`, then enter its old master password. Both Python v0 and v1 files are accepted. An encrypted file export can also be opened by the retired Python codec (verified with synthetic fixtures).

**Old Android/mobile vault:** upgrade the existing app using its original application ID **and signing key**. Do not uninstall it first: uninstalling can remove the old data and secure-storage key. Unlock the new vault, then choose “Eski CipherVault kayıtlarını taşı”. Existing Hive records and the device key are read but never deleted or replaced. Migration fails without the old key rather than inventing a replacement. Verify records and export an encrypted backup before removing any older copy. A debug APK is not a substitute for a correctly signed upgrade.

**Transfer:** export a `.cvault` file or encrypted QR with a separate passphrase (minimum 12 characters), then import it on the other device. Share the passphrase separately. QR accepts only CipherVault v2 encrypted packets, has a 64-part bound and a three-minute assembly window. Large vaults should use file transfer. Old plaintext QR imports are intentionally rejected.

## Data and recovery

The primary file is `CipherVault/vault.cvault` under the OS application-support directory. `vault.cvault.previous` is the last encrypted version; `vault.cvault.pending` is a temporary encrypted write. If the primary is missing, the previous file can be opened. If the primary is corrupt, use the import menu to select the `.previous` file (rename a **copy** to `.cvault` if the picker filters it). The recovery file is not a substitute for an external backup. Older backups retain the password used when they were created.

No master-password reset or remote recovery exists. App memory cannot be guaranteed to be forensically erased in a garbage-collected runtime. This is a development preview, not independently audited security software. See [SECURITY.md](SECURITY.md) and [validation](docs/VALIDATION.md).

## Android identity

The new Play product uses `com.bulgan.ciphervault`. Historical development packages used `com.example.ciphervault_mobile`; Android treats them as separate applications. Automatic Hive migration only works for data already accessible under the same package identity and signing key. Use an encrypted export/import for a cross-package migration. No existing user data was removed.
