// Sort configuration enums for transaction queries.
//
// Import path: package:home_pocket/shared/constants/sort_config.dart
//
// Usage scope: data layer (lib/data/daos/) and domain layer
// (lib/features/*/domain/) — safe to import from both layers because
// lib/shared/constants/ is explicitly on the allow-list in import_guard.
//
// D-01: These enums are the compile-time source of truth for ORDER BY column
// selection in TransactionDao.findByBookIds. User input never reaches the
// ORDER BY clause; column names are derived from an exhaustive switch over
// these enum values in the DAO (implemented in Plan 02).

/// The column by which a transaction list query should be ordered.
///
/// Values map to Drift table columns in `TransactionDao`:
/// - [timestamp] → `transactions.timestamp` (transaction date entered by user)
/// - [updatedAt] → `transactions.updated_at` (last edit time)
/// - [amount]    → `transactions.amount` (absolute value, descending for large first)
enum SortField {
  timestamp,
  updatedAt,
  amount,
}

/// The direction of a sorted query result.
///
/// - [asc]  → ascending order (oldest first / smallest first)
/// - [desc] → descending order (newest first / largest first)
enum SortDirection {
  asc,
  desc,
}
