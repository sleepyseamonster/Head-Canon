#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_PATH="$ROOT_DIR/logs/experiments.jsonl"

timestamp="${1:-}"
goal="${2:-}"
action="${3:-}"
result="${4:-}"
failure_class="${5:-unknown}"
next_step="${6:-}"

if [[ -z "$timestamp" ]]; then
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
fi

python3 - "$LOG_PATH" "$timestamp" "$goal" "$action" "$result" "$failure_class" "$next_step" <<'PY'
import json
import pathlib
import sys

log_path, timestamp, goal, action, result, failure_class, next_step = sys.argv[1:8]

record = {
    "timestamp": timestamp,
    "goal": goal,
    "actor": "Builder",
    "bundle_path": "/Applications/HeadCanon.app",
    "bundle_identifier": "local.headcanon.app",
    "signing_mode": "adhoc_or_unknown",
    "target_app": "TextEdit_or_unknown",
    "action": action,
    "result": result,
    "failure_class": failure_class,
    "confidence": "medium",
    "evidence": [],
    "next_step": next_step,
}

path = pathlib.Path(log_path)
with path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, ensure_ascii=True) + "\n")
PY

echo "Appended experiment to $LOG_PATH"
