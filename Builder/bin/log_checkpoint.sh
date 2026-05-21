#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_PATH="$ROOT_DIR/logs/checkpoints.jsonl"

timestamp="${1:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}"
goal="${2:-}"
tested="${3:-}"
happened="${4:-}"
ruled_out="${5:-}"
next_step="${6:-}"

python3 - "$LOG_PATH" "$timestamp" "$goal" "$tested" "$happened" "$ruled_out" "$next_step" <<'PY'
import json
import pathlib
import sys

log_path, timestamp, goal, tested, happened, ruled_out, next_step = sys.argv[1:8]

record = {
    "timestamp": timestamp,
    "checkpoint_goal": goal,
    "tested": tested,
    "happened": happened,
    "ruled_out": ruled_out,
    "next_high_signal_step": next_step,
}

path = pathlib.Path(log_path)
with path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, ensure_ascii=True) + "\n")
PY

echo "Appended checkpoint to $LOG_PATH"
