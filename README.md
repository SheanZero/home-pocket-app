# Home Pocket (まもる家計簿)

<p align="center">
  <!-- Replace with your logo -->
  <img src="assets/logo.png" alt="Home Pocket Logo" width="160" />
</p>

<p align="center">
  <strong>Offline-first family budgeting. Stored on-device.</strong><br/>
  <em>端末内保存・オフライン対応の家計簿（まもる家計簿）</em>
</p>

<p align="center">
  <!-- Badges (optional) -->
  <a href="#"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-%5E3.x-blue"></a>
  <a href="#"><img alt="Platforms" src="https://img.shields.io/badge/Platforms-iOS%20%7C%20Android%20%7C%20Desktop-lightgrey"></a>
  <a href="#"><img alt="License" src="https://img.shields.io/badge/License-Apache--2.0-green"></a>
</p>

---

## What is Home Pocket?

**Home Pocket** is a privacy-first, offline household budgeting app.
In Japan, the app is branded as **まもる家計簿**.

- **On-device by default**: your data stays on your device (no mandatory account).
- **Offline-first**: record expenses anywhere, anytime—no network required.
- **Tamper-evident history**: changes leave a detectable trace, so records are harder to silently alter.
- **Simple family flow**: fast entry, clear monthly view, export/backup when you need it.

> Note: “Tamper-evident” means edits can be detected via chained records / hashes.  
> It does **not** claim “impossible to modify”; it’s designed to make changes **observable**.

---

## Features

- ✅ **Fast entry** (expense / income / transfer) with notes and tags  
- ✅ **Categories & budgets** (monthly category budgets, overspend warnings)  
- ✅ **Monthly / yearly reports** (totals, trends, category breakdowns)  
- ✅ **History & search** (filters by date, category, payment method, keywords)  
- ✅ **Local backup / restore** (encrypted export file)  
- ✅ **CSV export** (for spreadsheets / tax / sharing)  

Planned:
- 🔜 **Family sharing** (optional local sync via file / QR / LAN)  
- 🔜 **Receipt capture** (on-device OCR where possible)  
- 🔜 **Rules & templates** (smart categorization, recurring items)  

---

## Tech Stack

- **Flutter** (UI + cross-platform)
- **Local database**: `sqlite` (via Drift) *or* `isar` (choose one)
- **Crypto / hashing**:
  - SHA-256 for record chaining (tamper-evident ledger)
  - Optional: Ed25519 for signed exports (future)
- **State management**: Riverpod (recommended) / Bloc
- **Serialization**: JSON (backup/export), CSV (reports)
- **CI**: GitHub Actions (analyze, format, test, build)

Suggested packages (example):
- `flutter_riverpod`
- `drift` + `sqlite3_flutter_libs` (or `isar`)
- `cryptography` (hashing / encryption)
- `intl` (date/currency)
- `share_plus` (export sharing)
- `path_provider` (local paths)

---

## Roadmap

### v0.1 — MVP (Local & Offline)
- [ ] Basic expense/income/transfer entry
- [ ] Category management
- [ ] Monthly list + monthly totals
- [ ] Local DB persistence
- [ ] CSV export

### v0.2 — Tamper-evident Ledger
- [ ] Append-only ledger structure
- [ ] Hash-chained records (detectable edits)
- [ ] Integrity Check screen (verification)
- [ ] Encrypted backup export + restore

### v0.3 — Reports & Quality
- [ ] Monthly/yearly charts
- [ ] Budget settings + alerts
- [ ] Advanced search & filters
- [ ] UX polish (quick add, templates)

### v1.0 — Release
- [ ] Store release readiness (iOS/Android)
- [ ] Full localization (EN/JA)
- [ ] Data migration strategy
- [ ] Privacy policy & in-app help

---

## Screenshots

> Coming soon.  
> Add images to `docs/screenshots/` and embed them here.

---

## License

This project is licensed under the **Apache License 2.0**.  
See the `LICENSE` file for details.

---

## Contributing

Issues and PRs welcome. Please run `flutter analyze` and `flutter test` before submitting.
