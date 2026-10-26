# Security model and limits

CipherVault encrypts the complete record list with AES-256-GCM. Each save uses a fresh 96-bit nonce. The CVLT version, Argon2id parameters and 128-bit salt are authenticated as associated data. New vaults use Argon2id 19 MiB, two iterations, one lane and a 256-bit key; the Python 64 MiB/three-iteration/four-lane format remains readable. Parameter, payload and record-count bounds are checked before costly work. Expensive derivation/encryption runs off the Flutter UI isolate.

The master passphrase is not persisted. Unlocking requires it on every platform, including devices without biometrics. Lock discards entry collections, clears the session key buffer on a best-effort basis, invalidates pending authentication/mutations and dismisses open record/editor/transfer screens. A background lock is immediate; an idle lock occurs after five minutes. Plaintext can remain in runtime/OS memory until garbage collection; there is no claim of guaranteed zeroization or protection from a compromised OS/keylogger/debugger.

Encrypted records are written to a flushed temporary file, preserving an encrypted previous version. A local instance lock prevents separate processes from concurrently editing the same vault. Hardware failure and simultaneous external file modification are not completely preventable; keep external encrypted backups. Master-password changes do not re-encrypt old backups.

The clipboard is cleared after 30 seconds or locking only if it still matches the value placed there by CipherVault. System clipboard managers may retain copies; the application cannot erase their history. Android uses FLAG_SECURE to reduce screenshot/recent-task exposure and disables automatic OS backup. Other platforms can still capture application windows. Revealed passwords are masked again after 15 seconds.

Transfers use a separately password-encrypted CVLT envelope. Multipart QR metadata is bounded; its content is authenticated by the encrypted envelope before import. Mixed transfer IDs, oversized messages, plaintext QR packets, unsupported versions and incomplete packets are rejected. QR assembly expires after three minutes; a newly collected copy of the encrypted data has no cryptographic expiry. Use a strong unique transfer passphrase and communicate it separately.

Legacy mobile migration is explicit and read-only. It uses the existing secure-storage key and supports the original GCM/CBC and plaintext field formats solely for migration. Old CBC data does not gain retroactive authentication. Imported fields are stored inside the new authenticated encrypted vault. Legacy dependencies are retained for this path; they are not the new storage format.

The source is available under GPLv3. Report issues privately to the project owner without sending a real vault, master password, account password, screenshots of secrets or signing credentials. No independent security audit or production-readiness claim is made.
