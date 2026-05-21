#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/HeadCanon.app"
CONTENTS_DIR="$APP_DIR/Contents"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
CONFIGURATION="${CONFIGURATION:-release}"
SIGNING_IDENTITY="${HEAD_CANON_CODESIGN_IDENTITY:-}"
PREFERRED_IDENTITY="${HEAD_CANON_LOCAL_CODESIGN_IDENTITY:-HeadCanon Local Signing}"
ENTITLEMENTS_PATH="$ROOT_DIR/Support/HeadCanon.entitlements"
BRANDING_SOURCE_PNG="$ROOT_DIR/Support/Branding/HeadCanonLogo.png"

generate_app_icon() {
  local source_png="$1"
  local iconset_dir="$2/AppIcon.iconset"
  local icon_path="$3/AppIcon.icns"

  rm -rf "$iconset_dir" "$icon_path"
  mkdir -p "$iconset_dir"

  sips -z 16 16     "$source_png" --out "$iconset_dir/icon_16x16.png" >/dev/null
  sips -z 32 32     "$source_png" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
  sips -z 32 32     "$source_png" --out "$iconset_dir/icon_32x32.png" >/dev/null
  sips -z 64 64     "$source_png" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
  sips -z 128 128   "$source_png" --out "$iconset_dir/icon_128x128.png" >/dev/null
  sips -z 256 256   "$source_png" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
  sips -z 256 256   "$source_png" --out "$iconset_dir/icon_256x256.png" >/dev/null
  sips -z 512 512   "$source_png" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
  sips -z 512 512   "$source_png" --out "$iconset_dir/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$source_png" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null

  iconutil -c icns "$iconset_dir" -o "$icon_path"
}

resolve_signing_identity() {
  if [[ -n "$SIGNING_IDENTITY" ]]; then
    return 0
  fi

  if security find-identity -v -p codesigning 2>/dev/null | grep -Fq "\"$PREFERRED_IDENTITY\""; then
    SIGNING_IDENTITY="$PREFERRED_IDENTITY"
  fi

  return 0
}

resolve_signing_identity

if [[ -n "${HEAD_CANON_SIGNING_MODE:-}" ]]; then
  SIGNING_MODE="$HEAD_CANON_SIGNING_MODE"
elif [[ "$CONFIGURATION" == "release" ]]; then
  SIGNING_MODE="require-identity"
else
  SIGNING_MODE="adhoc"
fi

swift build -c "$CONFIGURATION" >/dev/null
BUILD_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE_PATH="$BUILD_DIR/HeadCanon"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Missing built executable at $EXECUTABLE_PATH after release build." >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$CONTENTS_DIR/MacOS/HeadCanon"
cp "$ROOT_DIR/Support/HeadCanon-Info.plist" "$CONTENTS_DIR/Info.plist"

if [[ -f "$BRANDING_SOURCE_PNG" ]]; then
  cp "$BRANDING_SOURCE_PNG" "$RESOURCES_DIR/HeadCanonLogo.png"

  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT
  generate_app_icon "$BRANDING_SOURCE_PNG" "$temp_dir" "$RESOURCES_DIR"
fi

sign_app() {
  if [[ -n "$SIGNING_IDENTITY" ]]; then
    echo "Signing HeadCanon.app with identity: $SIGNING_IDENTITY" >&2
    codesign \
      --force \
      --deep \
      --sign "$SIGNING_IDENTITY" \
      --entitlements "$ENTITLEMENTS_PATH" \
      --options runtime \
      --timestamp \
      "$APP_DIR"
    return
  fi

  case "$SIGNING_MODE" in
    auto)
      echo "No signing identity configured. Falling back to ad-hoc signing for packaging-only use." >&2
      echo "Do not use this build for Accessibility permission testing." >&2
      echo "Set HEAD_CANON_CODESIGN_IDENTITY to enable hardened runtime signing." >&2
      codesign --force --deep --sign - "$APP_DIR"
      ;;
    adhoc)
      echo "Using ad-hoc signing for HeadCanon.app." >&2
      echo "This build is not suitable for stable Accessibility permission testing." >&2
      codesign --force --deep --sign - "$APP_DIR"
      ;;
    require-identity)
      echo "No usable code-signing identity was found." >&2
      echo "Set HEAD_CANON_CODESIGN_IDENTITY or run ./Scripts/install_app.sh for the normal local install flow." >&2
      exit 1
      ;;
    *)
      echo "Unsupported HEAD_CANON_SIGNING_MODE: $SIGNING_MODE" >&2
      exit 1
      ;;
  esac
}

sign_app
codesign --verify --deep --strict "$APP_DIR"

echo "$APP_DIR"
