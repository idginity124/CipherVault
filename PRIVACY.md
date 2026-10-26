# Privacy

CipherVault is an offline vault application. It has no user account service, analytics or automatic cloud synchronization. The master passphrase is used to derive the encryption key and is not saved by the application.

Records are stored in a locally encrypted file. Titles, usernames, passwords, websites, categories and notes are encrypted together. Decrypted records are held in memory while the vault is unlocked. Clipboard copying is explicit; a timed cleanup is attempted, but external clipboard history is outside the application's control.

Camera access is used only when scanning an encrypted transfer QR code. File import/export and OS sharing occur at the user's request. Exported files and QR codes contain encrypted vault data; the recipient needs the separately chosen transfer passphrase. Files shared with another application are subsequently handled under that application's rules.

The previous mobile store and device key are read only when the user requests legacy migration. CipherVault does not delete those legacy copies automatically. Keep encrypted external backups; deleting/uninstalling an application can remove its local files and keys.

No secrets should be submitted in GitHub issues or diagnostic screenshots. See SECURITY.md for memory, clipboard, screenshot and backup limitations.
