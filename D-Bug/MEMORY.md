# D-Bug Memory

## Durable Facts
- As of 2026-05-21, `swift test` passes in this repo.
- As of 2026-05-21, the main active user-facing failures are in runtime behavior rather than compile health.
- As of 2026-05-21, installed-app diagnostics show recent `Codex` failures clustering in insertion rather than transcription.
- As of 2026-05-21, `/Applications/HeadCanon.app` is the primary debugging target.
- As of 2026-05-21, some planner tests currently encode paste-oriented routing for strong AX opaque editors such as `Codex`.
- As of 2026-05-21 18:06 -0700, the updated signed app bundle was installed to `/Applications/HeadCanon.app`.
- As of 2026-05-21 18:06 -0700, bounded OpenAI transcription uses `Standard Completed Recording` directly instead of attempting a streaming preflight first.

## Current Suspects
- `Codex` insertion routing may be over-constrained by focus-safety requirements in app-level paste paths.
- Strategy selection for opaque editors may regress from usable AX-aware paste paths into self-blocking app-only paste paths.
- App-only context modeling may be assuming editability from app identity rather than actual focused-target evidence.
- Focus-equivalence checks may be too strict for editors whose AX object identity churns between observation and insertion.
- Streaming preflight for bounded transcription caused timeout risk before fallback could run; keep bounded dictation on standard completed-recording unless live streaming is deliberately reintroduced.
- Remaining live uncertainty is post-install `Codex` behavior after the app-level paste and focus-equivalence fixes.

## Working Assumptions
- Installed-app diagnostics are more trustworthy than green unit tests for this project stage.
- Preserving a known-good `TextEdit` path matters while iterating on opaque editors like `Codex`.
- Evidence should be captured from persistent diagnostics before escalating to architecture changes.
