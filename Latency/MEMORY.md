# Latency Memory

## Identity
- Agent name: `Latency`
- Workspace created on May 21, 2026.

## Repository Facts
- Repository root: `/Users/worldbuilder/Desktop/Head Canon`
- Project category: local-first macOS voice dictation app
- Repo priorities from instructions put activation-to-text latency first
- Preferred implementation direction from repo instructions: Swift, SwiftUI, macOS 14+, Apple Silicon first
- Package manifest present: `Package.swift`
- Existing durable agent workspaces also present: `Builder/` and `GitHubManager/`

## Latency Focus
- The highest-value performance target is the bounded dictation loop from explicit hotkey activation to inserted text in the focused app.
- User-perceived latency includes more than transcription time; activation, recording stop behavior, post-processing, insertion, and visual feedback all matter.
- Performance work should preserve privacy guardrails and avoid hidden background recording behavior.
- The repo now has an end-to-end measurement chain: in-app timing capture, persistent per-attempt JSON diagnostics, Settings UI surfacing, and a repo-local summary CLI.

## Measurement Assets
- Persistent diagnostics location: `~/Library/Application Support/HeadCanon/diagnostics/`
- Repo-local reader: `/Users/worldbuilder/Desktop/Head Canon/Scripts/diagnostics.swift`
- Repeatable snapshot helper: `/Users/worldbuilder/Desktop/Head Canon/Latency/bin/capture_latency_snapshot.sh`
- Historical installed-app baseline artifact: `/Users/worldbuilder/Desktop/Head Canon/D-Bug/artifacts/installed-app-baseline-2026-05-21.md`
- Inventory of latency measurement surfaces: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/measurement-inventory-2026-05-21.md`
- Current live diagnostics snapshot: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/benchmark-2026-05-21-live-diagnostics.md`
- Newer formal snapshot artifact: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/benchmark-2026-05-21T17-50-31-0700-clean-app-matrix-prep.md`

## Current Measured State
- Snapshot captured on May 21, 2026 at `2026-05-21T17:28:10-0700`.
- Latest attempt in the local diagnostics log failed in `Codex` during insertion after a successful `3383 ms` transcription response path and `1671 ms` response-header wait.
- Recent `20`-attempt summary from the local diagnostics log shows:
  - failures: `19`
  - `request -> response p50`: `2656 ms`
  - `request -> response p95`: `3674 ms`
  - `request -> headers p50`: `1278 ms`
  - `request -> headers p95`: `1845 ms`
  - `release -> inserted p50`: `1784 ms`
- Recent `50`-attempt app-class summary is dominated by `Codex`:
  - attempts: `46`
  - failures: `40`
  - `request -> response p50`: `1557 ms`
  - `request -> response p95`: `9534 ms`
- Recent `50`-attempt failure summary still shows insertion as the dominant live failure class, with transcription timeouts present but rare in the current slice.
- Newer formal snapshot captured on May 21, 2026 at `2026-05-21T17:50:31-0700` shows materially better recent `Codex` behavior:
  - recent `20`-attempt failures: `11`
  - recent `20` request -> response `p50`: `3444 ms`
  - recent `50` `Codex` request -> response `p50`: `2060 ms`
  - recent `50` `Codex` release -> inserted `p50`: `2795 ms`
  - recent `10` timeline is mostly successful `Codex` turns, but the sample is still not a balanced `TextEdit` + `Codex` benchmark matrix

## Current Assumptions
- The user wants a dedicated in-repo workspace for latency investigations, memory, and artifacts.
- This workspace should remain lightweight, append-friendly, and easy for future agents to extend.
- Future benchmark artifacts should be saved directly in `Latency/artifacts/` so performance history does not stay split across agent folders.

## Known Preferences
- Save durable context in-repo rather than relying on chat-only state.
- Keep artifacts explicit and discoverable.
- Prefer evidence-backed optimization work over abstract tuning advice.

## First Bootstrap Action
- On May 21, 2026, the `Latency/` folder was created with instructions, memory, schemas, artifacts, and logs.
- On May 21, 2026, the repo was audited for latency measurement surfaces and the findings were copied into `Latency/artifacts/`.
