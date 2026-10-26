CipherVault 2.0.1 is an open-source Flutter development preview for Android, Linux and Windows.

- Full-vault AES-256-GCM encryption with an Argon2id master passphrase.
- Shared mobile/desktop UI, categories, search, password generation, auto-lock and guarded clipboard cleanup.
- Encrypted backups, password-protected QR transfer and explicit legacy vault import.
- Offline ZXing QR scanning; no Google ML Kit binaries or Android Internet permission.
- Android target API 36, versionCode 3; 16 KB bundle/ELF alignment checked.

Choose your package:

| File | Purpose |
|---|---|
| `CipherVault_2.0.1_android_arm64.apk` | Direct Android ARM64 installation, signed with the project's upload key |
| `CipherVault_2.0.1_play-store.aab` | Google Play upload; cannot be installed directly |
| `CipherVault_2.0.1_amd64.deb` | Debian/Ubuntu x86_64 installation |
| `CipherVault_2.0.1_linux_x64.tar.gz` | Portable Linux x86_64 bundle; glibc 2.35+, GTK 3, libsecret and GSettings desktop schemas |
| `CipherVault_2.0.1_windows_x64.zip` | Portable Windows x64 app with runtime DLLs; extract the whole folder |
| `CipherVault_2.0.1_x64-store.msix` | Unsigned Microsoft Store submission package for CipherVault Desktop |

The MSIX is intended for Partner Center. Microsoft signs accepted Store packages; this file is not an ordinary signed sideload installer. These packages have not been submitted to Google Play or Microsoft Store automatically.

Android identity: `com.bulgan.ciphervault`. Windows identity: `EkremBulgan.CipherVaultDesktop`. MSIX version: `2.0.1.0`.

Thirteen automated tests pass. Linux was built locally against Ubuntu 22.04.5 and its native UI launch was checked. Windows was compiled and packaged on Windows; MSIX identity, runtime DLLs and block/file hashes were independently verified. Android AAB signature, configured upload certificate, bundle structure, target API and 16 KB alignment were checked. Real-device QR/upgrade checks, Windows UI/WACK and Store certification remain pending. This preview has not been independently security-audited; start with sample data and verify encrypted backup restoration.

Play-installed apps and direct APKs may have different signing certificates. Back up your encrypted vault before switching channels; do not uninstall a vault containing records until you have a verified backup and passphrase.

Original application code: GPL-3.0-only. Source archive, hashes, license, privacy policy, Turkish publishing guide, listing copy and store artwork/UI previews are attached. UI previews use synthetic sample data. Older v1 releases belong to the retired implementation.
