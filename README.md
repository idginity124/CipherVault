# CipherVault

One Flutter application for an offline password vault on Android, Linux and Windows. The UI adapts from a phone list to a desktop category/list/detail workspace. Application source remains private.

## Develop

```bash
flutter pub get
flutter run -d linux
flutter test
flutter analyze
```

Windows requires the Windows Flutter/Visual Studio desktop toolchain: `flutter build windows --release`. Build on Windows; the Linux host does not produce a Windows executable. Android: `flutter build apk --debug` for a development preview. Distribution builds require your original signing key; credentials belong in ignored `android/key.properties`, never in Git.

The canonical project is `/home/ekrem/Projects/CipherVault`. The previous mobile and desktop paths point here, so edits share one source tree.

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
