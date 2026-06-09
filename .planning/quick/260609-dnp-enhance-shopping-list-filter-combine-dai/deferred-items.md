# Deferred / Out-of-Scope Items — quick 260609-dnp

| Category | Item | Status |
|----------|------|--------|
| flaky_test | `test/scripts/merge_findings_test.dart` "idempotency: identical shards produce byte-identical issues.json" failed once under the full parallel `flutter test` run (+2502) but PASSES in isolation (8/8 green). Subprocess-idempotency test in `test/scripts/`, unrelated to the shopping-list presentation layer touched by this task. Pre-existing parallelism sensitivity. | out-of-scope (not caused by this change); do not fix here |
