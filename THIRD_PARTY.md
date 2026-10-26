# Third-party software

CipherVault's original application code is licensed under GPL-3.0-only. Dependencies retain their own licenses; the application license does not replace those licenses.

Runtime and platform dependencies are declared in `pubspec.yaml` and pinned in `pubspec.lock`: Flutter, cryptography, file_selector, path_provider, path, qr_flutter, mobile_scanner and share_plus. Hive, hive_flutter, encrypt and flutter_secure_storage are retained only for importing the previous mobile store. Their transitive dependencies and native platform components also retain their respective license notices.

Bundled Noto Sans fonts use the SIL Open Font License; the complete notice is in `assets/fonts/OFL.txt`. Platform runner/generated SDK files preserve their original notices. Project logo and Training Arc artwork are project assets; do not imply endorsement by the project author when redistributing modified versions.

Flutter-generated application bundles include the collected dependency notices in their assets. Inspect dependency notices and applicable native SDK requirements when distributing a build for a new platform.
