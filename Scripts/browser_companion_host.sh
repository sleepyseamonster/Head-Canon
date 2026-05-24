#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec /usr/bin/env swift "$ROOT_DIR/Scripts/browser_companion_host.swift"
