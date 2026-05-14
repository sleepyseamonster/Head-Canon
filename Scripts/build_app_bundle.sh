#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/VoiceFlow.app"
CONTENTS_DIR="$APP_DIR/Contents"
CONFIGURATION="${CONFIGURATION:-release}"
SIGNING_IDENTITY="${VOICEFLOW_CODESIGN_IDENTITY:-}"
if [[ -n "${VOICEFLOW_SIGNING_MODE:-}" ]]; then
  SIGNING_MODE="$VOICEFLOW_SIGNING_MODE"
elif [[ "$CONFIGURATION" == "release" ]]; then
  SIGNING_MODE="require-identity"
else
  SIGNING_MODE="adhoc"
fi

swift build -c "$CONFIGURATION" >/dev/null
BUILD_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE_PATH="$BUILD_DIR/VoiceFlow"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Missing built executable at $EXECUTABLE_PATH after release build." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"

cp "$EXECUTABLE_PATH" "$CONTENTS_DIR/MacOS/VoiceFlow"
cp "$ROOT_DIR/Support/VoiceFlow-Info.plist" "$CONTENTS_DIR/Info.plist"

sign_app() {
  if [[ -n "$SIGNING_IDENTITY" ]]; then
    echo "Signing VoiceFlow.app with identity: $SIGNING_IDENTITY" >&2
    codesign \
      --force \
      --deep \
      --sign "$SIGNING_IDENTITY" \
      --options runtime \
      --timestamp \
      "$APP_DIR"
    return
  fi

  case "$SIGNING_MODE" in
    auto)
      echo "No signing identity configured. Falling back to ad-hoc signing." >&2
      echo "Set VOICEFLOW_CODESIGN_IDENTITY to enable hardened runtime signing." >&2
      codesign --force --deep --sign - "$APP_DIR"
      ;;
    adhoc)
      echo "Using ad-hoc signing for VoiceFlow.app." >&2
      codesign --force --deep --sign - "$APP_DIR"
      ;;
    require-identity)
      echo "VOICEFLOW_CODESIGN_IDENTITY is required when VOICEFLOW_SIGNING_MODE=require-identity." >&2
      exit 1
      ;;
    *)
      echo "Unsupported VOICEFLOW_SIGNING_MODE: $SIGNING_MODE" >&2
      exit 1
      ;;
  esac
}

sign_app
codesign --verify --deep --strict "$APP_DIR"

echo "$APP_DIR"
