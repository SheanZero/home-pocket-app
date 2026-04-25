#!/usr/bin/env bash
# scripts/test_audit_pipeline.sh
# Local end-to-end run of the audit pipeline (mirrors `audit.yml` static-analysis job).
# Used by Plan 08 to verify the pipeline pre-commit and during /gsd-verify-work.
set -euo pipefail

echo "[audit:pipeline] running 4 tooling scanners..."
bash scripts/audit_layer.sh
bash scripts/audit_dead_code.sh
bash scripts/audit_providers.sh
bash scripts/audit_duplication.sh

echo "[audit:pipeline] merging shards..."
dart run scripts/merge_findings.dart

echo "[audit:pipeline] verifying outputs..."
test -f .planning/audit/issues.json
test -f .planning/audit/ISSUES.md

# Schema sanity check on issues.json
python3 - <<'EOF'
import json
import sys
data = json.load(open('.planning/audit/issues.json'))
findings = data.get('findings', [])
required = {'category', 'severity', 'file_path', 'line_start', 'line_end',
            'description', 'rationale', 'suggested_fix', 'tool_source',
            'confidence', 'status'}
for i, f in enumerate(findings):
    missing = required - set(f.keys())
    if missing:
        print(f'finding[{i}] missing fields: {missing}', file=sys.stderr)
        sys.exit(1)
    if not (f['id'].startswith('LV-') or f['id'].startswith('PH-')
            or f['id'].startswith('DC-') or f['id'].startswith('RD-')):
        print(f'finding[{i}] invalid id: {f["id"]}', file=sys.stderr)
        sys.exit(1)
print(f'[audit:pipeline] {len(findings)} findings validated.')
EOF

echo "[audit:pipeline] OK"
