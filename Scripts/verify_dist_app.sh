#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-$ROOT_DIR/dist/HeadCanon.app}"
EXPECTED_IDENTITY="${HEAD_CANON_EXPECTED_SIGNING_IDENTITY:-${HEAD_CANON_CODESIGN_IDENTITY:-}}"
EXPECTED_TEAM_ID="${HEAD_CANON_EXPECTED_TEAM_ID:-}"
LOCAL_SIGNING_IDENTITY="${HEAD_CANON_LOCAL_CODESIGN_IDENTITY:-HeadCanon Local Signing}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle at $APP_PATH" >&2
  exit 1
fi

codesign_info="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1)"
ACTUAL_IDENTITY="$(printf '%s\n' "$codesign_info" | awk -F= '/^Authority=/ { print $2; exit }')"
ACTUAL_TEAM_ID="$(printf '%s\n' "$codesign_info" | awk -F= '/^TeamIdentifier=/ { print $2; exit }')"

echo "== codesign identity =="
echo "$codesign_info"

if [[ "$codesign_info" == *"Signature=adhoc"* ]]; then
  echo >&2
  echo "Ad-hoc signatures are not stable enough for Accessibility permission testing." >&2
  echo "Build and install a signed app bundle before treating this as a trusted runtime." >&2
  exit 1
fi

if [[ -z "$EXPECTED_IDENTITY" && -z "$EXPECTED_TEAM_ID" ]]; then
  echo >&2
  echo "Set HEAD_CANON_EXPECTED_SIGNING_IDENTITY or HEAD_CANON_EXPECTED_TEAM_ID before treating this build as trusted." >&2
  exit 1
fi

if [[ -n "$EXPECTED_IDENTITY" && "$ACTUAL_IDENTITY" != "$EXPECTED_IDENTITY" ]]; then
  echo >&2
  echo "Signing identity mismatch." >&2
  echo "Expected: $EXPECTED_IDENTITY" >&2
  echo "Actual:   ${ACTUAL_IDENTITY:-<missing>}" >&2
  exit 1
fi

if [[ -n "$EXPECTED_TEAM_ID" && "$ACTUAL_TEAM_ID" != "$EXPECTED_TEAM_ID" ]]; then
  echo >&2
  echo "Team ID mismatch." >&2
  echo "Expected: $EXPECTED_TEAM_ID" >&2
  echo "Actual:   ${ACTUAL_TEAM_ID:-<missing>}" >&2
  exit 1
fi

echo
echo "== codesign verify =="
codesign --verify --deep --strict "$APP_PATH"

echo
echo "== Gatekeeper assessment =="
if ! spctl -a -vv "$APP_PATH"; then
  if [[ "$ACTUAL_IDENTITY" == "$LOCAL_SIGNING_IDENTITY" ]]; then
    echo "Gatekeeper rejected the local self-signed build, which is expected for $LOCAL_SIGNING_IDENTITY." >&2
    echo "Continuing because codesign verification passed and the signer identity matched." >&2
    exit 0
  fi

  echo "Gatekeeper rejected this build." >&2
  exit 1
fi
