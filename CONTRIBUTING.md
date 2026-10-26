# Contributing

Use a current stable Flutter SDK, run `flutter pub get`, `flutter analyze` and `flutter test`. Build platform runners on their supported host toolchains. Never commit personal vaults, real passwords, screenshots containing secrets, keystores, signing properties or environment credentials.

Before changing encryption, migration or persistence, add interoperability and failure-mode tests. Keep existing vaults readable, preserve originals during migration and maintain bounded parsers. Propose new vault formats before implementing them; changing the format breaks other installations and exported backups.

The encrypted fixtures in `test/fixtures` are synthetic. See their README for their test-only passphrase. Preview images also use synthetic records. Read SECURITY.md before reporting a security issue; use private reporting for vulnerabilities.

Original contributions are licensed under GPL-3.0-only, matching this project. Third-party code and assets must include compatible license notices. Do not describe development previews as audited or production-certified.
