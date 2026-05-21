#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SYSTEM_APP_PATH="/Applications/HeadCanon.app"
USER_APP_PATH="$HOME/Applications/HeadCanon.app"
PREFERRED_IDENTITY="${HEAD_CANON_LOCAL_CODESIGN_IDENTITY:-HeadCanon Local Signing}"

open_existing_app() {
  local app_path="$1"
  echo "Preserving existing installed app at $app_path to avoid resetting macOS permissions." >&2
  open "$app_path"
  echo "$app_path"
}

detect_signing_identity() {
  if [[ -n "${HEAD_CANON_CODESIGN_IDENTITY:-}" ]]; then
    printf '%s\n' "$HEAD_CANON_CODESIGN_IDENTITY"
    return 0
  fi

  if security find-identity -v -p codesigning 2>/dev/null | grep -Fq "\"$PREFERRED_IDENTITY\""; then
    printf '%s\n' "$PREFERRED_IDENTITY"
  fi

  return 0
}

SIGNING_IDENTITY="$(detect_signing_identity)"

if [[ -n "$SIGNING_IDENTITY" ]]; then
  echo "Using signing identity: $SIGNING_IDENTITY" >&2
  APP_PATH="$(
    HEAD_CANON_CODESIGN_IDENTITY="$SIGNING_IDENTITY" \
      "$ROOT_DIR/Scripts/build_app_bundle.sh"
  )"
  HEAD_CANON_EXPECTED_SIGNING_IDENTITY="$SIGNING_IDENTITY" \
    "$ROOT_DIR/Scripts/verify_dist_app.sh" "$APP_PATH"
  "$ROOT_DIR/Scripts/install_dist_app.sh" "$APP_PATH"
  exit 0
fi

if [[ -d "$SYSTEM_APP_PATH" && "${HEAD_CANON_REINSTALL:-0}" != "1" ]]; then
  open_existing_app "$SYSTEM_APP_PATH"
  exit 0
fi

if [[ -d "$USER_APP_PATH" && "${HEAD_CANON_REINSTALL:-0}" != "1" ]]; then
  open_existing_app "$USER_APP_PATH"
  exit 0
fi

echo "No trusted code-signing identity is configured." >&2
echo "Create the scoped local signing identity with ./Scripts/setup_local_codesign_identity.sh" >&2
echo "or set HEAD_CANON_CODESIGN_IDENTITY to an expected Developer ID identity before installing." >&2
exit 1
