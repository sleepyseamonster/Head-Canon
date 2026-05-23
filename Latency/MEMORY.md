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
- Early live diagnostics snapshot: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/benchmark-2026-05-21-live-diagnostics.md`
- Earlier formal snapshot artifact: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/benchmark-2026-05-21T17-50-31-0700-clean-app-matrix-prep.md`
- Current known-good baseline artifact: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/benchmark-2026-05-22T06-23-23-0700-known-good-bounded-baseline.md`

## Current Measured State
- Known-good baseline captured on May 22, 2026 at `2026-05-22T06:23:23-0700`.
- Latest attempt in the baseline artifact succeeded in `Codex` with:
  - `request -> response`: `1487 ms`
  - `request -> headers`: `1452 ms`
  - `release -> inserted`: `2061 ms`
  - backend: `openai.gpt-4o-mini-transcribe`
  - mode: `Standard Completed Recording`
  - insertion route: `appClipboardPaste`
- Recent `20`-attempt summary in the baseline artifact shows:
  - verified inserts: `0`
  - unverified inserts: `18`
  - failures: `2`
  - `request -> response p50`: `1487 ms`
  - `request -> response p95`: `8940 ms`
  - `request -> headers p50`: `1282 ms`
  - `request -> headers p95`: `1993 ms`
  - `release -> inserted p50`: `2225 ms`
  - `release -> inserted p95`: `9515 ms`
- Recent `50`-attempt `gpt-4o-mini-transcribe` summary in the baseline artifact shows:
  - attempts: `46`
  - failures: `0`
  - streaming fallbacks: `0`
  - `request -> response p50`: `1276 ms`
  - `request -> response p95`: `8940 ms`
  - `release -> inserted p50`: `1916 ms`
  - `release -> inserted p95`: `9515 ms`
- Recent `50`-attempt app-class summary remains overwhelmingly `Codex`:
  - attempts: `49`
  - failures: `3`
  - verified inserts: `6`
  - unverified inserts: `40`
- The current baseline is a strong latency anchor for the bounded path, but it is still mostly a `Codex`-only, `unverifiedInsert` slice rather than a balanced multi-app or fully verified insertion baseline.
- A follow-up quick diagnostic captured on May 22, 2026 at `2026-05-22T06:27:16-0700` regressed sharply in the tail:
  - latest attempt timed out at `30081 ms`
  - recent `20` `request -> response p95` rose to `30076 ms`
  - recent `20` failures rose to `3`
- That regression snapshot also exposed a live-diagnostics inconsistency:
  - `Current Attempt: None`
  - `Active Transcription: 16CC441B-17BF-42D3-88E6-F5CC9285468C`
  - `Workflow: Needs Attention (failed)`
- The inconsistency was traced to `HeadCanonModel` persisting failed live state before `activeTranscriptionAttemptID` was cleared in the `transcribeAndInsert(...)` defer path.
- On May 22, 2026, that cleanup ordering bug was fixed so the model persists live state again after clearing `activeTranscriptionAttemptID`.
- A focused regression test now checks that a timed-out turn leaves the last persisted live-state record with `activeTranscriptionAttemptID == nil`.
- This fix improves diagnostics fidelity, but it does not yet solve the underlying `~30s` timeout tail.
- A fatigue audit on May 22, 2026 at `06:30 -0700` tied the timeout tail to reused CFNetwork/QUIC transport rather than audio capture. The final failed transcription reused `Connection 23`, timed out with zero response bytes, and later emitted QUIC blackhole detection and `Operation timed out` reads.
- The installed build from May 22, 2026 at `06:38:50 -0700` now uses a fresh per-request `URLSession` for each standard bounded transcription request and invalidates that session after the request. This is intended to prevent repeated dictation turns from inheriting stale transport state.
- Post-fix audit through May 22, 2026 `06:45 -0700` captured `11` completed installed-app attempts with `0` transcription failures/timeouts. Post-install request latency over that slice was p50 `1647 ms`, p95 `3524 ms`.
- Post-fix CFNetwork logs for pid `16531` showed fresh connection IDs per transcription request and explicit cleanup after each success; no post-fix blackhole or operation-timeout entries were observed in the checked window.
- Codex insertion verification is an accepted limitation rather than a failure by itself: Codex does not expose reliable AX text readback, so successful Codex paste attempts can remain `unverifiedInsert` while Head Canon preserves/copies recovery text.
- On May 22, 2026 at `06:52 -0700`, production maximum recording duration was raised from `30 s` to `90 s`. The short fuse remains configurable in tests, but the installed app should be less likely to auto-finalize ordinary long dictations.
- On May 22, 2026 at `06:57 -0700`, hotkey physical-state checks were hardened to require both combined-session and HID hardware state to agree that the shortcut is still held. A stale session flag should no longer delay release finalization until the duration fuse.
- A fresh installed-app attempt at `06:58 -0700` finalized via `globalModifierMonitor`, transcribed in about `2.03 s`, inserted as `unverifiedInsert`, and ended with no active recording/transcription.
- On May 22, 2026 at `07:02 -0700`, empty `200 OK` text/plain transcription responses became retryable once. This targets the observed `06:55` record where headers and processing succeeded but the response body was empty.
- On May 22, 2026 at `19:55 -0700`, D-Bug traced a recovery UI regression likely introduced during latency/status work: the copyable last-transcript panel still existed, but it only rendered when `lastTranscript` was non-empty. The fix keeps the `Last Transcript` recovery surface visible in both the menu and Settings with available, empty, and retention-off states. Treat this as a latency lesson: fast primary-path work must not hide the manual recovery path, because time-to-recovery is part of user-perceived performance.
- See `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/checkpoint-2026-05-22T19-55-00-0700-recovery-ui-regression.md`.

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
