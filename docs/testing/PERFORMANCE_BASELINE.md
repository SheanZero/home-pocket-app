# Performance baseline harness

This creates reproducible measurement tooling; it does not create a performance
claim until a comparable physical-device baseline is collected.

## Recorded workloads

- SQLCipher page-query and single-write latency against an isolated encrypted
  fixture of 1k, 10k, or opt-in 50k transactions distributed across five books.
- Multi-book export-shaped materialization and JSON encoding. It does **not**
  execute destructive restore, so it is not restore latency.
- JSON/validation time for a 100-message relay page near the 2 MiB response
  budget.
- Flutter frame build/raster/total timing while scrolling a synthetic 500-row
  list. The JSON `counters`/`observations` also expose `total_frames`,
  `jank_frames`, `jank_percent`, and `frame_budget_ms` as machine-readable
  fields rather than free-form log text.
- Process RSS after the workload when `ProcessInfo.currentRss` is available.

Each populated metric includes P50, P95, and P99. GC, app-process cold start,
warm resume, and time-to-interactive are intentionally reported as unavailable
from an in-process test. Collect them with a launcher + VM-service trace; do
not infer them from this fixture.

## Commands and device policy

The runner never chooses a device. Check IDs first:

```bash
flutter devices
```

After explicit authorization to install/run on a device, collect the minimum
supported iPhone and a low-end Android in profile mode:

```bash
scripts/performance/run_performance_benchmark.sh --device <iphone-id> --dataset 1000 --mode profile --baseline iphone-minimum
scripts/performance/run_performance_benchmark.sh --device <android-id> --dataset 1000 --mode profile --baseline android-low-end
```

Repeat with `--mode release` for release parity. Do not run 50k in ordinary CI:

```bash
PERFORMANCE_ALLOW_LARGE_DATASET=true scripts/performance/run_performance_benchmark.sh --device <device-id> --dataset 50000 --mode profile --baseline <device-baseline>
```

Simulator/desktop output validates the harness but is not comparable to a
physical-device baseline.

## Results, thresholds, and gate

Raw output lives in ignored `performance/results/`. Reviewed limits live in
`performance/thresholds.json`. The committed thresholds file is deliberately
empty: no green number is invented before baseline evidence.

Without an approved entry the gate returns `baseline_required`. CI/release
automation makes this nonzero with `--require-baseline`:

```bash
dart run scripts/performance/performance_gate.dart \
  --result performance/results/<result>.json \
  --baseline iphone-minimum \
  --require-baseline
```

An approved threshold must include device model, OS, Flutter version, mode,
dataset size, repeat count, collection date, and each reviewed `p95_max_ms`.
Keep phone classes separate: never compare a simulator or flagship phone against
a low-end Android limit.

## Additional physical-device collection

Use DevTools/VM service launcher traces on the actual app for cold start, warm
resume, first interactive frame, GC, and RSS peak. Capture background/foreground
WebSocket plus FCM/APNs wakes with platform energy tools. The relay workload is
synthetic parser validation; it does not contact a real relay or user database.
