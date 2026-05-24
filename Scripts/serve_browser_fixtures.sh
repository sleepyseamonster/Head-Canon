#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/Support/BrowserFixtures"
HOST="127.0.0.1"
PORT="47831"
OPEN_AFTER_START="false"

usage() {
  cat <<EOF
Usage: ./Scripts/serve_browser_fixtures.sh [--port <port>] [--open]

Serves the local Head Canon browser fixture page for companion development.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --open)
      OPEN_AFTER_START="true"
      shift
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

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to serve the browser fixtures." >&2
  exit 1
fi

URL="http://$HOST:$PORT/index.html"

echo "Serving Head Canon browser fixtures from:"
echo "  $FIXTURE_DIR"
echo "Open:"
echo "  $URL"

if [[ "$OPEN_AFTER_START" == "true" ]]; then
  (sleep 1 && open "$URL") &
fi

cd "$FIXTURE_DIR"
exec python3 -m http.server "$PORT" --bind "$HOST"
