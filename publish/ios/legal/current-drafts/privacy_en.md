# Privacy Policy

**Happy Pocket (ハピポケ家族家計簿)**

Last updated: August 4, 2026 (Draft)

> **IMPORTANT / DRAFT:** This policy is a draft to be reviewed by Japanese legal counsel before launch. Its content may be updated when the official version is published.

---

## 1. Our Approach

Happy Pocket (the "App") is a local-first, privacy-focused family accounting app. The App is designed with a zero-knowledge architecture, meaning the developer and any external server cannot read your financial data.

This policy honestly describes how the App handles your information, based on the App's actual behavior.

## 2. On-Device Storage and Encryption

Plaintext financial data you enter (transactions, amounts, categories, notes, photos, etc.) and the on-device database are stored on your device. Encrypted messages and operational metadata used for family sync are handled as described in Section 4. Data is protected by a four-layer encryption stack:

1. Database encryption (SQLCipher / AES-256)
2. Field-level encryption (ChaCha20-Poly1305)
3. File encryption (photos, etc. / AES-256-GCM)
4. Transport encryption (device-to-device end-to-end encryption during family sync)

Encryption keys are managed on your device. The developer has no access to these keys or to the contents of your financial data.

## 3. Outbound Network Communication

The App does not perform any advertising or analytics communication that collects or transmits your financial data. However, the following limited outbound communications do occur, and we disclose them honestly:

### 3-1. Exchange-Rate Fetch

To support multi-currency amounts, the App connects to an external exchange-rate provider to retrieve up-to-date exchange rates. This communication is used solely to obtain exchange rates; no personal information or financial data is transmitted.

### 3-2. Push-Notification Token (only when enabled)

Only if you enable push notifications, a push token used for delivering notifications is registered with Google (Firebase Cloud Messaging). This registration is a technical step required to deliver notifications; no financial data itself is transmitted. If you do not use push notifications, this communication does not occur.

### 3-3. Family-Sync Relay (only when used)

If you use family sync, end-to-end encrypted messages and operational metadata required for delivery are sent to the relay server. Section 4 describes their retention, deletion, and logging.

## 4. Family Sync and the Relay Server

Family-sync data is end-to-end encrypted on the sending device and temporarily stored and forwarded by the relay server as encrypted messages. The relay server does not hold decryption keys and cannot decrypt or view transactions, amounts, categories, notes, or other financial content.

### 4-1. Encrypted-Message Retention and Deletion

Each encrypted message expires 7 days after creation. After a receipt acknowledgement arrives from the receiving device, the relevant message is physically deleted from the relay server's online database. A message that is not acknowledged is also physically deleted after expiry by a cleanup task that runs every hour. During normal operation, deletion generally occurs within about one hour after expiry; server downtime or a failed cleanup can delay deletion until the next successful run. Group dissolution, member departure, or encryption-key rotation may delete queued messages sooner.

To prevent duplicate delivery, the server retains content-free processing records such as the sync request ID, request hash, and recipient count for 7 days. Group-key-request coordination records are active for only 10 minutes, but the current code has no scheduled deletion for expired records. Group control events, which contain neither encryption keys nor financial data, are retained for 90 days. The scheduler periodically attempts to delete inactive devices after 90 days without access. The current server code does not define one uniform deletion deadline for all device, group, membership, and expired group-key-request operational metadata.

Records deleted from the online database may remain temporarily in rotating database backups. The standard production deployment configuration reviewed for this draft retains backups for 14 days. If the actual production environment changes that setting, the final policy will be updated accordingly.

### 4-2. Operational Metadata and Logs

To provide relay functionality and prevent abuse, the server processes operational metadata such as device IDs, public keys, device names, display names, group names, platforms, push tokens, last-access timestamps, and group and membership state. This metadata does not contain plaintext financial data.

Application logs record the HTTP method, request path, response status, processing duration, and device ID; an error log may also include a group ID. Application-layer code does not add request bodies, encrypted-message bodies, public keys, signatures, push tokens, or financial data as log fields.

However, the standard production deployment configures PostgreSQL to log SQL statements that take at least 500 milliseconds. Bind-parameter logging has not been disabled, so encrypted-message bodies and operational metadata may appear in database logs. Encrypted-message bodies remain unreadable to the server even if logged, but parameter output must still be disabled before launch. The current server implementation does not set a fixed log-retention period in code or in the standard deployment configuration. The hosting environment controls retention, so the operator must set the retention period and deletion method before launch and reflect them in the final policy.

Receipt photos are currently local-only. They are not included in family sync or encrypted backup files; only a non-sensitive availability marker may be synchronized so another device can explain that the photo remains on the device where the transaction was recorded.

## 5. Advertising and Tracking

The App displays no advertising. It does not embed any third-party analytics or tracking SDK. It does not collect your behavioral history or perform profiling.

## 6. Provision to Third Parties

Except as required by law, the App does not sell your information to third parties. The exchange-rate fetch, push-token registration, and family-sync relay described above are limited to what is necessary to provide those features. If a third-party hosting provider is used for the relay server, the operator must confirm the provider, storage region, and processing terms before launch and reflect them in the final policy.

## 7. Contact

For inquiries regarding this policy, please contact us at:

- Contact email: `support@example.com` (to be replaced with the real address before launch)

The latest version of this policy will be published within the App and at a designated public URL (to be finalized before launch).

## 8. Changes to This Policy

The App may revise this policy as needed. When we make material changes, we will provide notice within the App or by other appropriate means.

---

> **DRAFT MARKER:** This document is to be reviewed by Japanese legal counsel before launch.
