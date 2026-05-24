# Current Checkpoint

## Product Definition
`Head Canon` is a local-first macOS dictation utility with one core loop:

1. invoke from anywhere with a global hotkey
2. show immediate recording or processing state
3. capture bounded microphone audio
4. transcribe it quickly
5. insert text into the intended target safely

The project should be judged by whether the installed app at `/Applications/HeadCanon.app` can complete that loop reliably and quickly enough to feel ambient.

## Current Audit
What exists now:

- installed app target at `/Applications/HeadCanon.app`
- microphone and Accessibility onboarding
- keychain-backed OpenAI API key storage
- persisted preferences
- bounded audio capture
- standard request-based OpenAI transcription backend
- direct AX insertion for strong native targets
- clipboard-based insertion for opaque editors such as `Codex`
- release-time and insert-time insertion routing reports
- persistent local diagnostics under `~/Library/Application Support/HeadCanon/diagnostics/`
- repo-local diagnostics reader at `Scripts/diagnostics.swift`
- disk readiness checks with warning and hard-block thresholds
- a reclaimable Head Canon cache reserve under `~/Library/Caches/HeadCanon/`
- manual recovery through `pasteLastTranscript()`
- manual recovery through `Copy Last Transcript`
- one guarded retry for transient transport failures
- one guarded retry for empty `200 OK` transcription responses
- first-pass browser taxonomy and companion-protocol scaffolding in the repo
- browser-aware diagnostics fields for target class, editor family, verification mode, and extension protocol metadata

Accepted limitation:

- `Codex` is an opaque insertion target and does not expose reliable AX text readback.
- Successful `Codex` paste attempts may remain `unverifiedInsert`; this is acceptable and should not be treated as a transcription failure.
- If text is missing after a Codex `unverifiedInsert`, use `Paste Last Transcript` or `Copy Last Transcript` while investigating a Codex-specific verification/readback path.

What the latest installed-app evidence says:

- the current bounded path is materially healthier than the earlier slow baseline
- recent `20`-attempt summary on `gpt-4o-mini-transcribe` shows:
  - failures: `8`
  - `request -> response p50`: `1751 ms`
  - `request -> response p95`: `30158 ms`
  - `release -> inserted p50`: `1719 ms`
  - `release -> inserted p95`: `2498 ms`
- the current success path is still strong, but older tails should be compared against the newer post-fix diagnostics before treating them as current
- the current default path is `gpt-4o-mini-transcribe` plus `Standard Completed Recording`
- older failure windows were split between hard transcription timeouts and `Codex` insertion safety blocks
- later fixes addressed stale transcription transport, empty transcription responses, stuck recording recovery, and recovery actions
- the strongest recent run set is still mostly `Codex` warm turns, so the current numbers should not be treated as a complete app-matrix result yet
- the fallback bounded path remains important, but the next implementation lane is browser insertion support rather than more generic bounded-path tuning

## Current Blockers
1. `browser companion architecture not started`
   - there is still no Chromium or Safari companion extension in the repo
   - browser support remains AX-only and too coarse for `ChatGPT`, `Google`, `Gmail`, or `Docs`-style editors
2. `browser taxonomy and diagnostics are still incomplete in the runtime`
   - the repo can now persist browser target metadata, but the live app does not yet capture origin, frame, or extension-supplied context
   - there is still no operation-id or page-identity enforcement in the insertion loop
3. `timeout-path defect still exists in the fallback bounded lane`
   - some requests still fail at the app-level timeout
   - that remains real work, but it is no longer the primary planning lane
4. `rollback discipline still implicit`
   - browser work must land beside the current bounded baseline, not replace it
   - any browser experiment should preserve the existing AX/paste fallback path cleanly
5. `support policy is not evidence-backed yet`
   - the repo still lacks a browser matrix, local browser fixtures, and explicit support claims by target class
6. `model decision not yet locked`
   - `AGENTS.md` still names `gpt-4o-transcribe` as the initial priority, but the healthy default remains `gpt-4o-mini-transcribe`

## Rules For The Next Pass
1. Test only `/Applications/HeadCanon.app`.
2. Do not test `dist/HeadCanon.app`.
3. Preserve the working `TextEdit` path and the current bounded fallback while browser support lands beside it.
4. Use the persistent diagnostics log as the source of truth, not screenshots.
5. Optimize for `p95` and failure rate, but keep browser evidence capture ahead of site-specific heuristics.
6. Keep the stable bounded path separate from both browser-companion work and realtime/local-backend experiments.
7. Every failure must be classified into exactly one stage:
   - `permission/readiness`
   - `hotkey delivery`
   - `recording start`
   - `recording finalization`
   - `transcription request`
   - `transcription quality`
   - `insertion context`
   - `insertion transport`
   - `safety policy block`
8. Record disk readiness for each installed-app checkpoint:
   - current free space
   - whether the app reported `Healthy`, `Low`, or `Blocked`
   - whether a pre-start block persisted to diagnostics cleanly when exercised
9. For browser attempts, persist target class, editor family, verification mode, and browser identity even if origin or frame data are not available yet.
10. No browser target is considered supported unless it can land in one explicit truth state:
   - `verifiedInsert`
   - `unverifiedInsert`
   - `insertionFailed`
   - `blockedByPermissionsOrSetup`
   - `expiredDueToFocusOrPageChange`
   - `unsupportedTarget`
11. Do not stop at “scaffold complete.” Keep moving until the execution-plan stop condition is met or a hard external blocker requires user input.

## Immediate Next Steps
1. Keep the current bounded baseline locked as the rollback path:
   - `/Applications/HeadCanon.app`
   - `gpt-4o-mini-transcribe`
   - `Standard Completed Recording`
2. Add browser-aware diagnostics and target taxonomy before changing insertion behavior further.
3. Draft and stabilize the native app ↔ browser companion protocol with operation IDs, expiry, and target fingerprints.
4. Scaffold the Chromium companion first.
5. Add local browser fixtures for:
   - `input`
   - `textarea`
   - `contenteditable`
   - `iframe`
   - `shadow DOM`
   - secure-field negative cases
6. Only after those pieces exist, run the first browser evidence matrix:
   - generic browser textarea
   - `ChatGPT`
   - `Google Search`
   - `Gmail`
   - one iframe-backed editor
7. Return to the timeout/Codex lane after browser observability exists, not before.

## Definition Of A Good Next Checkpoint
The next checkpoint should include:

- one locked installed bundle path
- one clear bounded rollback baseline definition
- one explicit browser taxonomy in code and docs
- one persisted browser-aware diagnostics schema with CLI visibility
- one protocol scaffold for the future browser companion
- one note on what browser evidence is still missing from the live app
- one explicit statement about whether the next step is Chromium scaffolding, local fixture work, or timeout-lane fallback hardening
- one next step derived from that evidence
