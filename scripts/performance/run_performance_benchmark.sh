#!/usr/bin/env bash
set -euo pipefail

# The caller must explicitly select a device. This script never chooses a
# connected iPhone/iPad or Android device automatically.
usage() {
  echo "Usage: $0 --device DEVICE_ID [--dataset 1000|10000|50000] [--mode profile|release] [--flavor uat] [--baseline ID]" >&2
  exit 2
}

device=""
dataset="1000"
mode="profile"
baseline=""
flavor=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) device="${2:-}"; shift 2 ;;
    --dataset) dataset="${2:-}"; shift 2 ;;
    --mode) mode="${2:-}"; shift 2 ;;
    --flavor) flavor="${2:-}"; shift 2 ;;
    --baseline) baseline="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done
[[ -n "$device" ]] || usage
[[ "$dataset" == "1000" || "$dataset" == "10000" || "$dataset" == "50000" ]] || usage
[[ "$mode" == "profile" || "$mode" == "release" ]] || usage
[[ -z "$flavor" || "$flavor" == "uat" ]] || usage
if [[ "$dataset" == "50000" && "${PERFORMANCE_ALLOW_LARGE_DATASET:-false}" != "true" ]]; then
  echo "50k is opt-in: rerun with PERFORMANCE_ALLOW_LARGE_DATASET=true" >&2
  exit 2
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p performance/results
log="performance/results/${timestamp}-${device}-${mode}-${dataset}.log"
result="performance/results/${timestamp}-${device}-${mode}-${dataset}.json"

flavor_args=()
if [[ -n "$flavor" ]]; then
  flavor_args=(--flavor "$flavor")
fi

# flutter drive supports profile and release integration-test artifacts. The
# marker is then extracted into a raw result, never into reviewed thresholds.
flutter drive \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/performance/performance_baseline_test.dart \
  --device-id="$device" \
  --"$mode" \
  "${flavor_args[@]}" \
  --dart-define=PERF_DATASET_SIZE="$dataset" \
  --dart-define=PERF_DEVICE_LABEL="$device" \
  --dart-define=PERF_BUILD_MODE="$mode" \
  2>&1 | tee "$log"

marker="$(grep -E 'PERFORMANCE_RESULT_JSON=' "$log" | tail -n 1 | sed 's/.*PERFORMANCE_RESULT_JSON=//' || true)"
[[ -n "$marker" ]] || { echo "No performance JSON marker found in $log" >&2; exit 1; }
printf '%s\n' "${marker#PERFORMANCE_RESULT_JSON=}" > "$result"
echo "Raw result: $result"
if [[ -n "$baseline" ]]; then
  dart run scripts/performance/performance_gate.dart --result "$result" --baseline "$baseline"
fi
