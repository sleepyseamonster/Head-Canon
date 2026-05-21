#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP_PATH="${1:-$ROOT_DIR/dist/HeadCanon.app}"
PREFERRED_DESTINATION="${HEAD_CANON_INSTALL_DIR:-/Applications}"

if [[ ! -d "$SOURCE_APP_PATH" ]]; then
  echo "Missing built app bundle at $SOURCE_APP_PATH" >&2
  echo "Build it first with: HEAD_CANON_CODESIGN_IDENTITY=\"Developer ID Application: ...\" ./Scripts/build_app_bundle.sh" >&2
  exit 1
fi

codesign_info="$(codesign -dv --verbose=4 "$SOURCE_APP_PATH" 2>&1 || true)"
if [[ "$codesign_info" == *"Signature=adhoc"* && "${HEAD_CANON_ALLOW_ADHOC_INSTALL:-0}" != "1" ]]; then
  echo "Refusing to install an ad-hoc signed app bundle for permission testing." >&2
  echo "Accessibility trust is unstable when the installed bundle identity changes between rebuilds." >&2
  echo "Build with a stable signing identity, or set HEAD_CANON_ALLOW_ADHOC_INSTALL=1 to override for non-permission packaging checks." >&2
  exit 1
fi

destination_dir="$PREFERRED_DESTINATION"

if [[ ! -d "$destination_dir" ]]; then
  mkdir -p "$destination_dir"
fi

if [[ ! -w "$destination_dir" ]]; then
  destination_dir="$HOME/Applications"
  mkdir -p "$destination_dir"
fi

destination_app_path="$destination_dir/HeadCanon.app"
staging_app_path="$destination_dir/.HeadCanon.app.staged"
backup_app_path="$destination_dir/.HeadCanon.app.backup"

restore_backup() {
  if [[ -d "$backup_app_path" && ! -d "$destination_app_path" ]]; then
    mv "$backup_app_path" "$destination_app_path"
  fi
}

trap restore_backup ERR

pkill -f "$destination_app_path/Contents/MacOS/HeadCanon" || true
rm -rf "$staging_app_path" "$backup_app_path"
ditto "$SOURCE_APP_PATH" "$staging_app_path"

if [[ -d "$destination_app_path" ]]; then
  mv "$destination_app_path" "$backup_app_path"
fi

mv "$staging_app_path" "$destination_app_path"
rm -rf "$backup_app_path"
trap - ERR

echo "Installed HeadCanon.app to $destination_app_path"
open "$destination_app_path"
echo "$destination_app_path"
