# Codebase Concerns

**Analysis Date:** 2026-08-08

## Tech Debt

**Deferred budget tracking:**
- Issue: `GetBudgetProgressUseCase` is a compilable placeholder that always returns an empty list; the domain model exists without a backing Budget table or repository.
- Files: `lib/application/analytics/get_budget_progress_use_case.dart`, `lib/features/analytics/domain/models/budget_progress.dart`
- Impact: Any budget UI or caller silently receives no progress rather than an explicit unsupported state.
- Fix approach: Add a persisted Budget model/table, DAO and repository contract, then replace the placeholder with tested aggregation and a feature flag or explicit unavailable result during migration.

**Historical test scaffolding:**
- Issue: Shopping-list and analytics widget tests retain TODO-based mock providers and many `UnimplementedError` methods.
- Files: `test/widget/features/shopping_list/helpers/mock_use_cases.dart`, `test/widget/features/analytics/presentation/screens/analytics_screen_test.dart`, `test/widget/features/analytics/presentation/screens/analytics_refresh_group_mode_test.dart`
- Impact: Tests can pass while unexercised provider methods remain runtime traps; future refactors require maintaining brittle hand-written mocks.
- Fix approach: Replace dynamic/partial mocks with focused fakes or generated mocks and add assertions for every provider method used by each screen.

**Generated-file bulk:**
- Issue: Drift and localization/generated files dominate the tree (for example `lib/data/app_database.g.dart` is ~19k lines and generated localization is ~6.5k lines).
- Files: `lib/data/app_database.g.dart`, `lib/generated/app_localizations.dart`
- Impact: Slow analysis/code review and large diffs obscure source changes; regeneration can create unrelated churn.
- Fix approach: Keep generated outputs out of manual review paths, regenerate only from pinned tool versions, and isolate schema/localization changes in separate commits.

## Known Bugs

**Budget result ambiguity:**
- Symptoms: Callers cannot distinguish “no budgets configured” from a calculation failure because the use case always returns `[]`.
- Files: `lib/application/analytics/get_budget_progress_use_case.dart`
- Trigger: Any request for monthly budget progress.
- Workaround: None; callers must treat an empty result as absence of data.

## Security Considerations

**Sensitive error propagation in debug logs:**
- Risk: Several infrastructure/application paths interpolate exception objects or operation context into `debugPrint`; exception text from networking, platform SDKs, or sync parsing may include endpoints, tokens, identifiers, or payload metadata.
- Files: `lib/application/currency/get_exchange_rate_use_case.dart`, `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart`, `lib/infrastructure/sync/sync_scheduler.dart`, `lib/infrastructure/sync/push_notification_service.dart`, `lib/infrastructure/sync/websocket_service.dart`
- Current mitigation: Most logs are debug-only and sync request/response helpers avoid body logging.
- Recommendations: Centralize privacy-filtered logging, redact exception text by default, and add architecture tests forbidding interpolation of raw exceptions in production logging.

**Third-party exchange-rate availability:**
- Risk: Currency conversion depends on three public unauthenticated services and remote CDN content; outages, tampering, or stale responses can affect persisted financial amounts.
- Files: `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart`, `lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart`, `lib/application/currency/get_exchange_rate_use_case.dart`
- Current mitigation: Source fallback chain, short timeouts, finite/positive-rate validation, and cached rates.
- Recommendations: Pin/verify response schemas, record freshness and provenance in UI, add maximum staleness policy, and consider signed/controlled upstream data for persisted conversions.

## Performance Bottlenecks

**Unbounded transaction reads:**
- Problem: Transaction DAO queries intentionally have no limit or pagination and materialize every matching row for a date range.
- Files: `lib/data/daos/transaction_dao.dart` (`findByBookIds`, `watchByBookIds`)
- Cause: Pagination is explicitly deferred; multi-book streams sort and map complete result sets on every invalidation.
- Improvement path: Add indexed cursor pagination, bounded page sizes, and a lightweight summary stream for list screens; verify indexes for book/timestamp/ledger/category predicates.

**Large analytics aggregation surface:**
- Problem: `AnalyticsDao` contains many custom SQL aggregate methods over `transactions`, each potentially scanning broad ranges.
- Files: `lib/data/daos/analytics_dao.dart`
- Cause: Repeated ad-hoc aggregates and wide date ranges without a materialized monthly summary.
- Improvement path: Benchmark representative datasets, inspect SQLite query plans, add composite indexes or precomputed summaries, and keep date/book predicates mandatory.

## Fragile Areas

**Sync orchestration and inbound processing:**
- Files: `lib/application/family_sync/sync_engine.dart`, `lib/application/family_sync/sync_orchestrator.dart`, `lib/application/family_sync/apply_sync_operations_use_case.dart`, `lib/application/family_sync/pull_sync_use_case.dart`
- Why fragile: Cross-device ordering, retries, quarantine, websocket events, push notifications, and local database writes are coordinated across very large modules; small lifecycle changes can create duplicate or lost operations.
- Safe modification: Preserve idempotency/revision checks, add focused failure/reconnect tests, and change one sync path at a time with encrypted integration fixtures.
- Test coverage: Broad unit coverage exists, but production timing, network interruption, and multi-device conflict scenarios remain difficult to exercise deterministically.

**Very large presentation widgets:**
- Files: `lib/features/accounting/presentation/widgets/transaction_details_form.dart`, `lib/features/shopping_list/presentation/screens/shopping_item_form_screen.dart`, `lib/features/family_sync/presentation/screens/group_management_screen.dart`
- Why fragile: Files exceed 1,600–2,000 lines and combine validation, provider wiring, navigation, localization, and rendering.
- Safe modification: Extract field sections/controllers and pure validation helpers before behavior changes; preserve golden/widget coverage for each extracted section.
- Test coverage: Targeted tests exist, but large widget surfaces rely on extensive manual stubs and smoke paths.

**Silent decryption/data-loss behavior:**
- Files: `lib/data/repositories/shopping_item_repository_impl.dart`
- Why fragile: Note decryption failures are intentionally swallowed and mapped to `null`, making wrong-key/corrupt-data indistinguishable from an empty note.
- Safe modification: Keep ciphertext out of logs, but expose a typed recoverable-decryption status to the application/UI and add migration/key-rotation tests.
- Test coverage: Failure handling is covered only indirectly; corrupt ciphertext and key-version transitions need explicit integration tests.

## Scaling Limits

**Relay and local sync payload limits:**
- Current capacity: Relay pull pages are capped at 100 messages and response/body limits are roughly a few MiB.
- Limit: Large families, offline periods, or avatar/file-heavy queues can exceed bounded pages and prolong catch-up/retry cycles.
- Scaling path: Add server/client cursor checkpoints, backpressure metrics, resumable chunking for large artifacts, and load tests with worst-case queues.

## Dependencies at Risk

**Public rate APIs and platform push/speech SDKs:**
- Risk: Availability, schema, quota, or platform-policy changes are outside app control.
- Impact: Currency entry, push-driven sync wakeups, or speech input may degrade without a release.
- Migration plan: Keep adapters behind existing infrastructure interfaces, add contract fixtures, and define offline/manual fallback behavior.

## Missing Critical Features

**Operational observability:**
- Problem: No dedicated error-tracking/metrics integration is detected; failures are primarily debug logs.
- Blocks: Diagnosing sync stalls, rate-source failures, and device-specific initialization errors in production.

## Test Coverage Gaps

**Realistic performance and resilience tests:**
- What's not tested: Large transaction datasets, pagination behavior (none implemented), prolonged offline sync, and concurrent reconnect/conflict resolution.
- Files: `lib/data/daos/transaction_dao.dart`, `lib/data/daos/analytics_dao.dart`, `lib/application/family_sync/`
- Risk: Regressions appear only with real-world data volume or timing.
- Priority: High

**External-service contract failures:**
- What's not tested: Malformed/changed exchange-rate schemas, CDN poisoning/staleness, and all-source outage UX beyond unit exceptions.
- Files: `lib/infrastructure/exchange_rate/exchange_rate_api_client.dart`
- Risk: Incorrect or unavailable conversion data reaches users without clear recovery guidance.
- Priority: Medium

---

*Concerns audit: 2026-08-08*
