#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$ROOT_DIR"

rg -n \
  "import Security|Keychain|API key|OpenAI|clipboard|pasteboard|Accessibility|microphone|permission|diagnostic|transcript|secureTarget|URLSession|network|privacy|codesign|Gatekeeper|Application Support" \
  Sources Scripts docs AGENTS.md Dave
