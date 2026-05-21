#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACT_DIR="$ROOT_DIR/logs/artifacts"
mkdir -p "$ARTIFACT_DIR"

timestamp="$(date -u +"%Y-%m-%dT%H-%M-%SZ")"
out_path="$ARTIFACT_DIR/runtime_snapshot_$timestamp.md"

{
  echo "# Runtime Snapshot"
  echo
  echo "- Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "- CWD: $(pwd)"
  echo
  echo "## App Path"
  echo '```text'
  echo "/Applications/HeadCanon.app"
  echo '```'
  echo
  echo "## Codesign"
  echo '```text'
  codesign -dv --verbose=4 /Applications/HeadCanon.app 2>&1 || true
  echo '```'
  echo
  echo "## Running Processes"
  echo '```text'
  pgrep -af '/Applications/HeadCanon.app/Contents/MacOS/HeadCanon' || true
  echo '```'
  echo
  echo "## Recent TCC Requests"
  echo '```text'
  /usr/bin/log show --last 10m --predicate 'process == "HeadCanon" AND eventMessage CONTAINS[c] "TCCAccessRequest"' --style compact || true
  echo '```'
  echo
  echo "## User Defaults"
  echo '```text'
  defaults read local.headcanon.app 2>/dev/null || true
  echo '```'
  echo
  echo "## Git Status"
  echo '```text'
  git -C "$(cd "$ROOT_DIR/.." && pwd)" status --short || true
  echo '```'
} >"$out_path"

echo "$out_path"
