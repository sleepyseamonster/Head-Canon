#!/usr/bin/env bash

set -euo pipefail

SYSTEM_APP_PATH="/Applications/HeadCanon.app"
USER_APP_PATH="$HOME/Applications/HeadCanon.app"

if [[ -d "$SYSTEM_APP_PATH" ]]; then
  open "$SYSTEM_APP_PATH"
  echo "$SYSTEM_APP_PATH"
  exit 0
fi

if [[ -d "$USER_APP_PATH" ]]; then
  open "$USER_APP_PATH"
  echo "$USER_APP_PATH"
  exit 0
fi

echo "HeadCanon.app is not installed." >&2
echo "Install it first with: ./Scripts/install_app.sh" >&2
exit 1
