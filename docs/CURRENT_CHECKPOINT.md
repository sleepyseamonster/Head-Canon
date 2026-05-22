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
- manual recovery through `pasteLastTranscript()`
- manual recovery through `Copy Last Transcript`
- one guarded retry for transient transport failures
- one guarded retry for empty `200 OK` transcription responses

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
- the immediate next question is not model choice; it is whether timeout cancellation and `Codex` focus-drift fixes can stabilize the bounded path without adding mess

## Current Blockers
1. `timeout-path defect`
   - some requests still fail at the app-level `30s` timeout
   - the in-flight request path needs explicit cancellation rather than more retry layering
2. `codex verification limitation`
   - `Codex` can transcribe and paste successfully while still reporting `unverifiedInsert`
   - this is accepted unless the text is actually missing or the truth state becomes a real failure
3. `model decision not yet locked`
   - `AGENTS.md` still names `gpt-4o-transcribe` as the initial priority, but the current healthy default is `gpt-4o-mini-transcribe`
   - that should become an explicit measured decision
4. `architecture decision still pending`
   - it is not yet clear whether the bounded path is “done enough” or whether realtime/local backend work is still worth the complexity
5. `rollback discipline still implicit`
   - the docs need to keep treating the current bounded baseline as a known-good snapshot
   - any retry, model, or architecture experiment should be able to fall back to that state cleanly

## Rules For The Next Pass
1. Test only `/Applications/HeadCanon.app`.
2. Do not test `dist/HeadCanon.app`.
3. Preserve the working `TextEdit` path while improving `Codex`.
4. Use the persistent diagnostics log as the source of truth, not screenshots.
5. Optimize for `p95` and failure rate now, not just `p50`.
6. Keep the stable bounded path separate from realtime or local-backend experiments.
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

## Immediate Next Steps
1. Lock the current bounded baseline:
   - `/Applications/HeadCanon.app`
   - `gpt-4o-mini-transcribe`
   - `Standard Completed Recording`
2. Fix timeout cancellation cleanly and retest the bounded path.
3. Treat successful `Codex` `unverifiedInsert` as acceptable; only investigate Codex further when text is missing or diagnostics show a failed truth state.
4. After those fixes, run the longer installed-app soak test:
   - `30-50` warm short-phrase turns in `Codex`
   - `10` turns in `TextEdit`
   - `5` turns in one browser target
5. Use `Scripts/diagnostics.swift` to capture:
   - success rate
   - `request -> response p50`
   - `request -> response p95`
   - `release -> inserted p50`
   - `release -> inserted p95`
   - dominant failure reason
6. If the bounded path still looks healthy after those fixes, run the controlled bounded model comparison between:
   - `gpt-4o-mini-transcribe`
   - `gpt-4o-transcribe`
7. Include one transcript-quality note in the model comparison so speed is not the only decision input.
8. Only then decide whether to:
   - keep the bounded path and stop
   - prototype realtime transcription
   - prototype `whisper.cpp`

## Definition Of A Good Next Checkpoint
The next checkpoint should include:

- one locked installed bundle path
- one clear bounded baseline definition
- one explicit result for the timeout-cancellation fix
- one explicit result for the `Codex` focus-drift fix
- one longer run summary by app class
- `p50`, `p95`, and failure rate from the persistent diagnostics log
- one note on whether transcript quality stayed acceptable
- one explicit statement about whether the remaining pain is acceptable bounded-path variance or a reason to escalate architecture work
- one next step derived from that evidence
