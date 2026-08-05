---
title: "Privacy Policy"
description: "How Happy Pocket handles information, external connections, family-sync retention, safeguards, and user rights."
translationKey: "privacy"
eyebrow: "LEGAL · PRIVACY"
---

**Happy Pocket: Family Budget**

Established and last updated: August 5, 2026

Effective: the date of the App's first public release

Operator: ナープ株式会社

## 1. Our Approach

ナープ株式会社 (“we”) provides Happy Pocket: Family Budget (the “App”) as a local-first, privacy-focused ledger. This policy explains how the App and its official website handle information.

## 2. Financial Data on Your Device

Plaintext transactions, amounts, categories, notes, receipt photos, and other financial records are generally stored on your device. The device database is protected with SQLCipher, sensitive fields with ChaCha20-Poly1305, and photos and similar files with AES-256-GCM.

Encryption keys are managed on your device. Neither we nor the family-sync relay receives plaintext financial data or decryption keys. In the current version, receipt photos stay only on the device where they were recorded and are not included in family sync or encrypted backup files.

## 3. External Connections

### 3.1 Exchange Rates

The multi-currency feature sends the requested date, base currency, and target currency to Frankfurter, the fawazahmed0 currency API delivered through jsDelivr, or the same API delivered through Cloudflare Pages. It does not send names, contact details, device IDs, transactions, amounts, notes, photos, or other financial data.

### 3.2 Speech Recognition

Voice input prefers on-device recognition. Only when you allow cloud fallback in Settings and on-device recognition is unavailable may audio be processed by the operating-system speech service provided by Apple or Google. That processing is governed by the relevant provider's privacy terms. Our relay server does not receive or retain audio or recognition results.

### 3.3 Family Sync

When you use family sync, data you choose to share is end-to-end encrypted on the sending device. Encrypted messages and the operational metadata needed for delivery are then sent to the relay. Personal-ledger records are not shared.

### 3.4 Push Notifications

Push notifications are disabled in the first public release. This version does not request notification permission, register a token with APNs or Firebase Cloud Messaging, or send a push token to the relay.

## 4. Family-Sync Data

Family-sync data is temporarily stored and forwarded by the relay server. The relay server does not hold decryption keys and therefore cannot decrypt transactions, amounts, categories, notes, or similar content.

Each encrypted message expires 7 days after creation. A receipt acknowledgement from the receiving device deletes the corresponding message from the online database. Unacknowledged messages are removed after expiry by a task that runs every hour, normally within about one hour; an outage may delay deletion until the next successful run.

Content-free anti-duplication processing records are kept for 7 days, group control events for 90 days, and inactive-device records become eligible for deletion 90 days after last access. Operational metadata such as device records, public keys, display names, group state, and membership state is kept while necessary to provide and secure sync and prevent abuse. Information removed from the online database may remain in rotating backups for up to 14 days.

## 5. Operational Logs

Relay application logs may contain the HTTP method, request path, response status, processing time, device ID, and, for errors, a group ID. We do not intentionally log request bodies, encrypted-message bodies, public keys, signatures, audio, push tokens, or financial data. Production PostgreSQL is configured not to log bind parameters.

Access logs, error logs, and database slow-query logs are kept for 30 days and then permanently deleted by automatic rotation. We do not retain recoverable backups of those logs.

## 6. Purposes of Use

We handle information only to:

- provide the App, family sync, exchange rates, and user support;
- verify users, devices, and sync groups;
- troubleshoot, secure the service, and prevent abuse; and
- comply with legal obligations.

The App displays no advertising and uses no third-party advertising or behavioral-analytics SDK. We do not use financial data for advertising, sale, or user profiling.

## 7. Processors and External Providers

The family-sync infrastructure is located in the Tencent Cloud Japan (Tokyo) region. For our account with Japan as the registered billing country, the contracting entity is Aceville Pte. Ltd. of Singapore. It and approved subprocessors process data on our behalf under Tencent Cloud's contractual and data-processing terms.

Exchange-rate providers and, when you permit it, Apple or Google's operating-system speech service receive only the limited information described in Section 3. We do not sell user information except where disclosure is required by law.

## 8. Your Controls and Requests

You can delete on-device data through the App's deletion controls or by uninstalling the App. Leaving or dissolving a family group may cause related pending encrypted messages to be deleted earlier than their ordinary expiry.

To request notice of purpose, access, correction, suspension of use, suspension of third-party provision, or deletion of personal information held by us, email `support@napu.co.jp`. We will verify the requester's connection to the relevant device or sync group, act within a reasonable and necessary scope, and generally respond within 30 days. Because of the zero-knowledge design, we cannot view, recover, or provide your plaintext financial data.

## 9. Security

We apply safeguards appropriate to the information handled, including access control, encryption, permissions management, log and backup controls, and processor oversight. If a data incident occurs, we will investigate, mitigate harm, notify as required, and take steps to prevent recurrence under applicable law.

## 10. Changes and Contact

We will announce material changes in the App or on the official website. The current policy is available at `https://happypocket.app/en/privacy`.

- Operator: ナープ株式会社
- Address: GYB Akihabara 5F, 2-25 Kanda-Sudacho, Chiyoda-ku, Tokyo 101-0041, Japan
- Email: support@napu.co.jp
- Telephone: 03-6859-7235 (weekdays 10:00–17:00 Japan Standard Time)
