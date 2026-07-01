# Privacy Policy

**Home Pocket (まもる家計簿)**

Last updated: July 1, 2026 (Draft)

> **IMPORTANT / DRAFT:** This policy is a draft to be reviewed by Japanese legal counsel before launch. Its content may be updated when the official version is published.

---

## 1. Our Approach

Home Pocket (the "App") is a local-first, privacy-focused family accounting app. The App is designed with a zero-knowledge architecture, meaning the developer and any external server cannot read your financial data.

This policy honestly describes how the App handles your information, based on the App's actual behavior.

## 2. On-Device Storage and Encryption

The financial data you enter (transactions, amounts, categories, notes, photos, etc.) is, as a rule, stored only on your device. Data is protected by a four-layer encryption stack:

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

## 4. Family Sync

The family data-sync feature is an end-to-end encrypted communication that takes place directly between devices. Synced data is never stored on the developer's servers.

## 5. Advertising and Tracking

The App displays no advertising. It does not embed any third-party analytics or tracking SDK. It does not collect your behavioral history or perform profiling.

## 6. Provision to Third Parties

Except as required by law, the App does not provide your information to third parties. The exchange-rate fetch and push-token registration described above are limited to what is necessary to provide those services.

## 7. Contact

For inquiries regarding this policy, please contact us at:

- Contact email: `support@example.com` (to be replaced with the real address before launch)

The latest version of this policy will be published within the App and at a designated public URL (to be finalized before launch).

## 8. Changes to This Policy

The App may revise this policy as needed. When we make material changes, we will provide notice within the App or by other appropriate means.

---

> **DRAFT MARKER:** This document is to be reviewed by Japanese legal counsel before launch.
