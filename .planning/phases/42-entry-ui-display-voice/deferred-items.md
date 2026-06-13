# Deferred Items — Phase 42

Out-of-scope discoveries logged during plan execution (not fixed; SCOPE BOUNDARY).

## From plan 42-09 (currency-linked edit host)

- **provider_graph_hygiene_test.dart HIGH-04 failure (PRE-EXISTING).**
  `lib/features/accounting/presentation/providers/recent_currency_provider.dart`
  is flagged: "is not a state_*.dart (HIGH-04 violation)". Introduced by plan
  42-06 (`c7475090 feat(42-06): recent-use currency session provider`), predates
  42-09's first commit (verified at `511c7ffa~1`). Not caused by 42-09 changes.
  Fix likely belongs to a 42-06 follow-up: either rename to `state_recent_currency.dart`
  or relocate the provider so the feature dir contains only `repository_providers.dart`
  + `state_*.dart` siblings. Left untouched per execution SCOPE BOUNDARY.
