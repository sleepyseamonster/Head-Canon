#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$(VOICEFLOW_SIGNING_MODE="${VOICEFLOW_SIGNING_MODE:-adhoc}" "$ROOT_DIR/Scripts/build_app_bundle.sh")"
swift build -c "${CONFIGURATION:-release}" >/dev/null
BUILD_DIR="$(swift build -c "${CONFIGURATION:-release}" --show-bin-path)"

pkill -f "$APP_PATH/Contents/MacOS/VoiceFlow" || true
pkill -f "$BUILD_DIR/VoiceFlow" || true

open "$APP_PATH"

echo "$APP_PATH"
