#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-$ROOT_DIR/dist/VoiceFlow.app}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle at $APP_PATH" >&2
  exit 1
fi

echo "== codesign identity =="
codesign -dv --verbose=4 "$APP_PATH" 2>&1

echo
echo "== codesign verify =="
codesign --verify --deep --strict "$APP_PATH"

echo
echo "== Gatekeeper assessment =="
if ! spctl -a -vv "$APP_PATH"; then
  echo "Gatekeeper rejected this build." >&2
  exit 1
fi
