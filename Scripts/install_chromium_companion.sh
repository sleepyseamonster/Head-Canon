#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_NAME="local.headcanon.browser_companion"
DEFAULT_MANIFEST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
EXTENSION_ID=""
MANIFEST_DIR="$DEFAULT_MANIFEST_DIR"

usage() {
  cat <<EOF
Usage: ./Scripts/install_chromium_companion.sh --extension-id <id> [--manifest-dir <dir>]

Installs the local native-messaging manifest for the Chromium companion scaffold.

Examples:
  ./Scripts/install_chromium_companion.sh --extension-id abcdefghijklmnopqrstuvwxyzabcdef
  ./Scripts/install_chromium_companion.sh --extension-id abcdef --manifest-dir "\$HOME/Library/Application Support/Arc/NativeMessagingHosts"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --extension-id)
      EXTENSION_ID="${2:-}"
      shift 2
      ;;
    --manifest-dir)
      MANIFEST_DIR="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$EXTENSION_ID" ]]; then
  echo "Missing required --extension-id argument." >&2
  usage >&2
  exit 1
fi

mkdir -p "$MANIFEST_DIR"
chmod +x "$ROOT_DIR/Scripts/browser_companion_host.sh"

HOST_PATH="$ROOT_DIR/Scripts/browser_companion_host.sh"
MANIFEST_PATH="$MANIFEST_DIR/$HOST_NAME.json"

cat > "$MANIFEST_PATH" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Head Canon local Chromium companion host scaffold",
  "path": "$HOST_PATH",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$EXTENSION_ID/"
  ]
}
EOF

echo "Installed Chromium native host manifest:"
echo "  $MANIFEST_PATH"
echo
echo "Companion extension folder:"
echo "  $ROOT_DIR/BrowserCompanion/Chromium"
