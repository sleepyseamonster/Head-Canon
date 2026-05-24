#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/Support/BrowserFixtures"
EXTENSION_DIR="$ROOT_DIR/BrowserCompanion/Chromium"
BROKER_DIR="$HOME/Library/Application Support/HeadCanon/browser-companion"
COMMANDS_DIR="$BROKER_DIR/commands"
RESULTS_DIR="$BROKER_DIR/results"
SNAPSHOT_FILE="$BROKER_DIR/latest-target.json"
ARTIFACT_DIR="$ROOT_DIR/artifacts/browser-fixture-matrix"
PORT="47831"
HOST="127.0.0.1"
CHROME_APP="/Applications/Google Chrome.app"
SERVER_PID=""
CHROME_PID=""
PROFILE_DIR=""
ARTIFACT_PATH=""

usage() {
  cat <<EOF
Usage: ./Scripts/run_chromium_fixture_matrix.sh

Launches a temporary Chrome instance with the local Head Canon Chromium companion,
drives the generic browser fixture page, and records a matrix artifact.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$CHROME_APP" ]]; then
  echo "Missing Chrome app at $CHROME_APP" >&2
  exit 1
fi

cleanup() {
  if [[ -n "$CHROME_PID" ]]; then
    kill "$CHROME_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$PROFILE_DIR" ]]; then
    pkill -f "$PROFILE_DIR" >/dev/null 2>&1 || true
    sleep 1
  fi
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$PROFILE_DIR" && -d "$PROFILE_DIR" ]]; then
    rm -rf "$PROFILE_DIR"
  fi
}
trap cleanup EXIT

mkdir -p "$COMMANDS_DIR" "$RESULTS_DIR" "$ARTIFACT_DIR"
setopt null_glob
rm -f "$COMMANDS_DIR"/*.json "$RESULTS_DIR"/*.json "$BROKER_DIR/latest-result.json" "$SNAPSHOT_FILE"
unsetopt null_glob

python3 -m http.server "$PORT" --bind "$HOST" -d "$FIXTURE_DIR" >/tmp/headcanon-browser-fixtures.log 2>&1 &
SERVER_PID=$!

PROFILE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/headcanon-chrome-profile.XXXXXX")"
open -na "$CHROME_APP" --args \
  --user-data-dir="$PROFILE_DIR" \
  --no-first-run \
  --disable-default-apps \
  --disable-extensions-except="$EXTENSION_DIR" \
  --load-extension="$EXTENSION_DIR" \
  "http://$HOST:$PORT/index.html?focus=fixture-search"
sleep 2

wait_for_result() {
  local operation_id="$1"
  local result_path="$RESULTS_DIR/$operation_id.json"
  local attempts=0
  while [[ $attempts -lt 120 ]]; do
    if [[ -f "$result_path" ]]; then
      cat "$result_path"
      rm -f "$result_path"
      return 0
    fi
    sleep 0.1
    attempts=$((attempts + 1))
  done
  echo "Timed out waiting for browser companion result $operation_id" >&2
  return 1
}

send_command() {
  local command="$1"
  local transcript="$2"
  local target_file="$3"
  local operation_id
  operation_id="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  local command_path="$COMMANDS_DIR/$operation_id.json"
  python3 - "$command" "$operation_id" "$transcript" "$target_file" > "$command_path" <<'PY'
import json, sys, datetime, pathlib

command = sys.argv[1]
operation_id = sys.argv[2]
transcript = sys.argv[3]
target_path = sys.argv[4]

issued_at = datetime.datetime.now(datetime.timezone.utc)
expires_at = issued_at + datetime.timedelta(seconds=8)
target = None
if target_path:
    target = json.loads(pathlib.Path(target_path).read_text())

payload = {
    "protocolVersion": 1,
    "command": command,
    "operationID": operation_id,
    "issuedAt": issued_at.isoformat().replace("+00:00", "Z"),
    "expiresAt": expires_at.isoformat().replace("+00:00", "Z"),
    "target": target,
    "transcript": transcript or None,
}
print(json.dumps(payload, sort_keys=True))
PY
  wait_for_result "$operation_id"
}

wait_for_snapshot() {
  local attempts=0
  while [[ $attempts -lt 120 ]]; do
    if [[ -f "$SNAPSHOT_FILE" ]]; then
      return 0
    fi
    sleep 0.1
    attempts=$((attempts + 1))
  done
  echo "Timed out waiting for a fresh browser companion snapshot at $SNAPSHOT_FILE" >&2
  return 1
}

navigate_to() {
  local url="$1"
  osascript <<EOF >/dev/null
tell application "Google Chrome"
  activate
  if (count of windows) = 0 then
    make new window
  end if
  set URL of active tab of front window to "$url"
end tell
EOF
}

extract_target() {
  local source_file="$1"
  local target_file="$2"
  python3 - "$source_file" "$target_file" <<'PY'
import json, pathlib, sys
source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
payload = json.loads(source.read_text())
target.write_text(json.dumps(payload.get("target"), sort_keys=True))
PY
}

field_value() {
  local source_file="$1"
  local field="$2"
  python3 - "$source_file" "$field" <<'PY'
import json, pathlib, sys
payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
value = payload
for part in sys.argv[2].split("."):
    value = value.get(part) if isinstance(value, dict) else None
print("" if value is None else value)
PY
}

wait_for_snapshot

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
ARTIFACT_PATH="$ARTIFACT_DIR/chromium-fixture-matrix-$timestamp.md"

cases=(
  "fixture-search|Plain Input|plainTextControl|inserted|verified"
  "fixture-textarea|Textarea|plainTextControl|inserted|verified"
  "fixture-composer|Rich Contenteditable|richEditable|unverifiedInsert|unverified fallback"
  "shadow-composer|Shadow DOM Editor|richEditable|unverifiedInsert|unverified fallback"
  "iframe-rich-editor|Iframe Editor|framedEditable|unverifiedInsert|unverified fallback"
  "fixture-password|Secure Field Negative|unsupportedOrSecure|unsupported|unsupported in v1"
)

{
  echo "# Chromium Fixture Matrix"
  echo
  echo "- generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "- browser: Google Chrome"
  echo "- extension path: $EXTENSION_DIR"
  echo "- fixture URL: http://$HOST:$PORT/index.html"
  echo
  echo "| Fixture | Capture Result | Target Class | Insert Result | Classification |"
  echo "| --- | --- | --- | --- | --- |"
} > "$ARTIFACT_PATH"

for case_entry in "${cases[@]}"; do
  IFS="|" read -r focus_key label expected_class expected_insert classification <<< "$case_entry"
  url="http://$HOST:$PORT/index.html?focus=$focus_key"
  navigate_to "$url"
  sleep 1.5

  capture_json="$(send_command "captureFocusedTarget" "" "")"
  capture_file="$(mktemp "${TMPDIR:-/tmp}/headcanon-capture.XXXXXX")"
  print -r -- "$capture_json" > "$capture_file"
  capture_result="$(field_value "$capture_file" "result")"
  target_class="$(field_value "$capture_file" "target.targetClass")"
  target_file="$(mktemp "${TMPDIR:-/tmp}/headcanon-target.XXXXXX")"
  extract_target "$capture_file" "$target_file"

  insert_json="$(send_command "insertTranscript" "Head Canon fixture matrix: $label" "$target_file")"
  insert_file="$(mktemp "${TMPDIR:-/tmp}/headcanon-insert.XXXXXX")"
  print -r -- "$insert_json" > "$insert_file"
  insert_result="$(field_value "$insert_file" "result")"

  if [[ "$capture_result" != "targetSnapshot" ]]; then
    echo "Capture failed for $label: $capture_result" >&2
    exit 1
  fi

  if [[ "$target_class" != "$expected_class" ]]; then
    echo "Unexpected target class for $label: expected $expected_class, got $target_class" >&2
    exit 1
  fi

  if [[ "$insert_result" != "$expected_insert" ]]; then
    echo "Unexpected insert result for $label: expected $expected_insert, got $insert_result" >&2
    exit 1
  fi

  echo "| $label | $capture_result | $target_class | $insert_result | $classification |" >> "$ARTIFACT_PATH"

  rm -f "$capture_file" "$target_file" "$insert_file"
done

echo
echo "Wrote Chromium fixture matrix artifact:"
echo "  $ARTIFACT_PATH"
