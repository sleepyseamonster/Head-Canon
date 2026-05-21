#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_PATH="$ROOT_DIR/logs/failures.jsonl"

timestamp="${1:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}"
failure_class="${2:-unknown}"
summary="${3:-}"
observed="${4:-}"
mitigation="${5:-}"
status="${6:-open}"

python3 - "$LOG_PATH" "$timestamp" "$failure_class" "$summary" "$observed" "$mitigation" "$status" <<'PY'
import json
import pathlib
import sys

log_path, timestamp, failure_class, summary, observed, mitigation, status = sys.argv[1:8]

record = {
    "timestamp": timestamp,
    "failure_class": failure_class,
    "summary": summary,
    "bundle_path": "/Applications/HeadCanon.app",
    "target_app": "TextEdit_or_unknown",
    "observed": observed,
    "suspected_cause": "",
    "evidence": [],
    "mitigation_attempted": mitigation,
    "status": status,
}

path = pathlib.Path(log_path)
with path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, ensure_ascii=True) + "\n")
PY

echo "Appended failure to $LOG_PATH"
