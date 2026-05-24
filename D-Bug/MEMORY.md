# D-Bug Memory

## Durable Facts
- As of 2026-05-21, `swift test` passes in this repo.
- As of 2026-05-21, the main active user-facing failures are in runtime behavior rather than compile health.
- As of 2026-05-21, installed-app diagnostics show recent `Codex` failures clustering in insertion rather than transcription.
- As of 2026-05-21, `/Applications/HeadCanon.app` is the primary debugging target.
- As of 2026-05-21, some planner tests currently encode paste-oriented routing for strong AX opaque editors such as `Codex`.
- As of 2026-05-21 18:06 -0700, the updated signed app bundle was installed to `/Applications/HeadCanon.app`.
- As of 2026-05-21 18:06 -0700, bounded OpenAI transcription uses `Standard Completed Recording` directly instead of attempting a streaming preflight first.
- As of 2026-05-21 18:33 -0700, `/Applications/HeadCanon.app` includes stuck-recording HUD hardening for missed modifier release events.
- As of 2026-05-21 19:14 -0700, `/Applications/HeadCanon.app` includes a fast app-model recording release watchdog that finalizes when the configured hotkey is no longer physically pressed.
- As of 2026-05-21 19:33 -0700, `/Applications/HeadCanon.app` includes audio lifecycle reconciliation for unexpected capture completion and stale recording-state cleanup.
- As of 2026-05-21 19:39 -0700, `/Applications/HeadCanon.app` writes privacy-safe live diagnostics to `live-state.json` and exposes menu/settings recovery buttons for finalize/cancel.
- As of 2026-05-22 06:39 -0700, `/Applications/HeadCanon.app` includes a transcription transport-fatigue fix: standard bounded transcription uses a fresh per-request URLSession and invalidates it after each POST to avoid stale reused CFNetwork/QUIC connections.
- As of 2026-05-22 06:57 -0700, `/Applications/HeadCanon.app` includes stricter hotkey physical-state reconciliation: modifier/key watchdogs require both combined-session and HID hardware state to agree that the hotkey is still held, so a stale session flag alone cannot keep the app recording.
- As of 2026-05-22 07:02 -0700, `/Applications/HeadCanon.app` retries one empty `200 OK` text/plain transcription response before surfacing failure, which covers the observed short-turn empty-body response at `06:55`.
- As of 2026-05-22, the user accepts `Codex` insertion being classified as `unverifiedInsert`: Codex does not expose reliable AX text readback, so the app should preserve/copy recovery text but should not treat successful unverified paste as a transcription failure.
- As of 2026-05-23, repo-wide audit found the installed app healthy after rebuild: live diagnostics are ready with no stuck recording/transcription, the latest 20 attempts are successful `Codex` `unverifiedInsert` turns, and the remaining repo-level risks are dirty-worktree discipline, diagnostic truthfulness around `noSpeechDetected`, and keeping Browser Companion experimental until reviewed.

## Current Suspects
- `Codex` insertion routing may be over-constrained by focus-safety requirements in app-level paste paths.
- Strategy selection for opaque editors may regress from usable AX-aware paste paths into self-blocking app-only paste paths.
- App-only context modeling may be assuming editability from app identity rather than actual focused-target evidence.
- Focus-equivalence checks may be too strict for editors whose AX object identity churns between observation and insertion.
- Streaming preflight for bounded transcription caused timeout risk before fallback could run; keep bounded dictation on standard completed-recording unless live streaming is deliberately reintroduced.
- A missed modifier-hold release can make transcription appear completely broken because the app remains in `recording` and blocks new dictation before a transcription request is made.
- Hotkey-manager-only release recovery was insufficient; the model now independently polls physical hotkey state during recording.
- Root stuck-HUD evidence showed the audio graph can tear down while the model remains `.recording`; unexpected capture completion must be treated as an app-model lifecycle event.
- `Scripts/diagnostics.swift live` is now the first command to run for any currently stuck state; `latest` only describes terminal attempts.
- Remaining live `Codex` work is only for missing text or failed truth states; `unverifiedInsert` alone is an accepted honest limitation for this opaque app target.
- After repeated-dictation fatigue on 2026-05-22, the primary suspect moved from audio capture to stale hosted-transcription transport: macOS logs showed a reused QUIC connection timing out after recording had finalized.
- Live diagnostics can expose transport vs audio failures quickly: if `Audio Capture Recording` is `No`, clip metadata exists, and `Last Truth State` is `transcriptionTimedOut`, inspect CFNetwork logs before patching hotkey/audio code.

## Working Assumptions
- Installed-app diagnostics are more trustworthy than green unit tests for this project stage.
- Preserving a known-good `TextEdit` path matters while iterating on opaque editors like `Codex`.
- Evidence should be captured from persistent diagnostics before escalating to architecture changes.
- If recording sticks again, inspect whether the new unexpected-completion handler or stale-state watchdog emitted a recording-stop failure.
- `swift test` should not overwrite installed-app live diagnostics; direct model tests now use `NoOpDiagnosticsStore()` unless they are intentionally testing diagnostics persistence.
