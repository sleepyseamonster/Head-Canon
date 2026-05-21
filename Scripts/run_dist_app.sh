#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-}"
SYSTEM_APP_PATH="/Applications/HeadCanon.app"
USER_APP_PATH="$HOME/Applications/HeadCanon.app"

if [[ -z "$APP_PATH" ]]; then
  if [[ -d "$SYSTEM_APP_PATH" ]]; then
    APP_PATH="$SYSTEM_APP_PATH"
  elif [[ -d "$USER_APP_PATH" ]]; then
    APP_PATH="$USER_APP_PATH"
  else
    echo "Missing installed app bundle." >&2
    echo "Install a signed build first with: ./Scripts/install_dist_app.sh" >&2
    exit 1
  fi
fi

if [[ "$APP_PATH" == "$ROOT_DIR/dist/HeadCanon.app" && "${HEAD_CANON_ALLOW_DIST_RUN:-0}" != "1" ]]; then
  echo "Refusing to launch the transient dist bundle for permission testing." >&2
  echo "Install the app and run the installed bundle instead." >&2
  echo "Set HEAD_CANON_ALLOW_DIST_RUN=1 only for packaging checks." >&2
  exit 1
fi

EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/HeadCanon"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Missing runnable app at $APP_PATH." >&2
  exit 1
fi

if pgrep -f "$EXECUTABLE_PATH" >/dev/null 2>&1; then
  pkill -f "$EXECUTABLE_PATH" || true

  for _ in {1..20}; do
    if ! pgrep -f "$EXECUTABLE_PATH" >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
fi

open "$APP_PATH"

echo "$APP_PATH"
