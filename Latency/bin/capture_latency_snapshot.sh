#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LATENCY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$LATENCY_DIR/.." && pwd)"

LABEL="${1:-snapshot}"
SAFE_LABEL="$(printf '%s' "$LABEL" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
STAMP="$(date +%Y-%m-%dT%H-%M-%S%z)"
ARTIFACT_PATH="$LATENCY_DIR/artifacts/benchmark-${STAMP}-${SAFE_LABEL}.md"
CAPTURED_AT="$(date +%Y-%m-%dT%H:%M:%S%z)"

LATEST_OUTPUT="$(swift "$REPO_ROOT/Scripts/diagnostics.swift" latest)"
LIVE_OUTPUT="$(swift "$REPO_ROOT/Scripts/diagnostics.swift" live)"
SUMMARY_20_OUTPUT="$(swift "$REPO_ROOT/Scripts/diagnostics.swift" summary 20)"
SUMMARY_MODEL_50_OUTPUT="$(swift "$REPO_ROOT/Scripts/diagnostics.swift" summary-by-model 50)"
SUMMARY_APP_50_OUTPUT="$(swift "$REPO_ROOT/Scripts/diagnostics.swift" summary-by-app-class 50)"
SUMMARY_FAILURE_50_OUTPUT="$(swift "$REPO_ROOT/Scripts/diagnostics.swift" summary-by-failure 50)"
RECENT_10_OUTPUT="$(swift "$REPO_ROOT/Scripts/diagnostics.swift" recent 10)"

cat >"$ARTIFACT_PATH" <<EOF
date: $(date +%Y-%m-%d)
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: ${LABEL}

# Latency Snapshot

Captured: \`${CAPTURED_AT}\`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
\`\`\`bash
swift Scripts/diagnostics.swift latest
\`\`\`

Observed:
\`\`\`text
${LATEST_OUTPUT}
\`\`\`

## Live State
Command:
\`\`\`bash
swift Scripts/diagnostics.swift live
\`\`\`

Observed:
\`\`\`text
${LIVE_OUTPUT}
\`\`\`

## Recent 20 Summary
Command:
\`\`\`bash
swift Scripts/diagnostics.swift summary 20
\`\`\`

Observed:
\`\`\`text
${SUMMARY_20_OUTPUT}
\`\`\`

## Recent 50 Summary By Model
Command:
\`\`\`bash
swift Scripts/diagnostics.swift summary-by-model 50
\`\`\`

Observed:
\`\`\`text
${SUMMARY_MODEL_50_OUTPUT}
\`\`\`

## Recent 50 Summary By App Class
Command:
\`\`\`bash
swift Scripts/diagnostics.swift summary-by-app-class 50
\`\`\`

Observed:
\`\`\`text
${SUMMARY_APP_50_OUTPUT}
\`\`\`

## Recent 50 Summary By Failure
Command:
\`\`\`bash
swift Scripts/diagnostics.swift summary-by-failure 50
\`\`\`

Observed:
\`\`\`text
${SUMMARY_FAILURE_50_OUTPUT}
\`\`\`

## Recent 10 Timeline
Command:
\`\`\`bash
swift Scripts/diagnostics.swift recent 10
\`\`\`

Observed:
\`\`\`text
${RECENT_10_OUTPUT}
\`\`\`
EOF

printf '%s\n' "$ARTIFACT_PATH"
