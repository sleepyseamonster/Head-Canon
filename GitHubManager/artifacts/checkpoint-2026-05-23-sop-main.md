date: 2026-05-23
branch: main
status: complete
owner: GitHub Manager
purpose: Capture the May 23 SOP result for the browser-companion and diagnostics checkpoint

# Main SOP Checkpoint

## Baseline
- Current branch: `main`
- Upstream: `origin/main`
- Remote: `https://github.com/sleepyseamonster/Head-Canon.git`
- Baseline commit before this SOP batch: `37ee5df`

## Landed Scope
- browser-companion taxonomy, monitoring, scripts, fixtures, and Chromium scaffold
- browser-aware diagnostics fields and CLI visibility
- more truthful no-speech and too-short-turn handling in the bounded transcription lane
- updated latency tooling and repo docs to reflect the browser-companion planning lane
- D-Bug and Latency artifacts capturing the repo-wide audit and browser checkpoint evidence

## Verification
- `swift test`
- `swift Scripts/diagnostics.swift live`
- `swift Latency/bin/latency_decision_support.swift --window 20`
- `sh Scripts/install_chromium_companion.sh --help`
- `sh Scripts/serve_browser_fixtures.sh --help`
- `sh Scripts/browser_companion_host.sh </dev/null >/dev/null 2>/dev/null`

## Audit
- The batch is coherent around one transition: from bounded-only diagnostics toward browser-aware insertion scaffolding without changing the default installed-app path.
- Verification passed on both the runtime and the companion-development helpers.
- The installed app currently reports browser companion status as `Not Installed`, which is expected for the scaffold state.

## Next Recommended Step
- Keep the installed app fallback path healthy, then manually verify:
  - Chromium companion installation flow with a real extension ID
  - local browser fixtures for input, textarea, contenteditable, iframe, and shadow DOM
  - browser-aware diagnostics fields after the first real companion-assisted turn
