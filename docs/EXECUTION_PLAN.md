# Head Canon Execution Plan

## Objective
Make the installed app at `/Applications/HeadCanon.app` feel ambient for short dictation while preserving the current safety and reliability bar.

The next plan has three priorities, in this order:

1. measure the latency path precisely instead of guessing
2. make those measurements available outside the Settings UI through persistent local diagnostics
3. remove avoidable local delay and only then decide whether the OpenAI backend path itself needs to change

The repo is no longer blocked on “can it ever transcribe and insert?”
The next phase is evidence-driven latency work.

## Current Audit
Already landed:

- installed app runtime at `/Applications/HeadCanon.app`
- permission onboarding and readiness UI
- bounded audio capture
- `gpt-4o-mini-transcribe` backend
- streamed completed-recording transcription with automatic fallback to standard bounded requests
- direct AX insertion for strong native targets
- clipboard-first insertion support for known opaque editors such as `Codex`
- release-time versus insert-time insertion diagnostics
- immediate processing-state transition on hotkey release
- no microphone refresh on the hotkey path
- trimmed recording finalization before request start
- off-main transcription request construction plus backend response metadata in diagnostics
- reduced paste-path fixed wait versus the earlier `900ms` hold

Current latency findings:

- the app now records full phase timings plus backend metadata in memory and in the Settings UI
- those diagnostics are still volatile and disappear on relaunch because there is no persistent local sink
- the local hot path has been materially trimmed, so the next question is repeated-run evidence rather than more blind local cleanup
- current measured evidence points to the request/response leg as the dominant remaining delay during real use
- one recent installed-app run showed about `5.98s` spent in `request start -> response complete` for a roughly `1.76s` / `45 KB` clip, which is strong enough to justify treating backend time as the main remaining suspect until better file-backed evidence exists
- opaque-editor insertion still needs separate measurement from native AX even after the paste-path delay reduction
- the repo currently uses `gpt-4o-mini-transcribe`, while `AGENTS.md` still names `gpt-4o-transcribe` as the initial implementation priority

## Working Rules
- test only `/Applications/HeadCanon.app`
- do not test `dist/HeadCanon.app`
- do not reinstall unless intentionally updating
- preserve the working `TextEdit` path while improving `Codex` and other opaque editors
- track `TextEdit` and `Codex` separately; do not hide latency differences behind one overall average
- prefer no-regret quick wins before deeper architecture changes
- treat the local diagnostics log as the source of truth, not screenshots of the Settings UI
- do not log raw transcript text by default
- do not start realtime transcription work until measurements show the bounded path is already locally lean
- every failure must be classified into exactly one stage:
  - `permission/readiness`
  - `hotkey delivery`
  - `recording start`
  - `recording finalization`
  - `transcription request`
  - `transcription quality`
  - `insertion context`
  - `insertion transport`
  - `safety policy block`

## Latency Budgets
Use these as working targets, not as release promises:

- `key-up -> visible processing state`: under `100ms`
- `key-up -> recording finalized`: under about `300ms`
- `response complete -> inserted`:
  - native AX target: under about `250ms`
  - opaque paste target: keep as low as possible, but measure separately from AX
- short-phrase `release -> inserted`: usually under about `2-3s`
- diagnostics persistence overhead: negligible relative to the dictation loop and never user-visible

## Measurement Protocol
Use one explicit benchmark routine for every latency pass:

- measure one cold turn after launch
- measure at least `5` warm short-phrase turns in `TextEdit`
- measure at least `5` warm short-phrase turns in `Codex`
- record `p50` and worst observed result for each phase
- record one multi-sentence turn in each supported hotkey mode when testing truncation and latency together
- store each attempt as one local persistent diagnostics record
- use repo-local tooling to inspect the latest attempt rather than relying on screenshots

Do not call a latency phase complete based on one fast anecdotal run.

## Regression Gates
Every performance change must preserve all of the following:

- no wrong-target insertion
- no secure-field insertion
- no silent transcript loss
- `TextEdit` remains solid
- failure recovery still works through last transcript or manual paste
- diagnostics writing failure never blocks dictation
- default logs do not retain raw transcript text

If a speed change regresses one of these, stop and fix that before continuing.

## Phase 1: Runtime Identity And Truth
Question:
Are all tests using one stable installed bundle with truthful readiness reporting?

Actions:
- launch only `/Applications/HeadCanon.app`
- confirm the app path shown in settings matches `/Applications/HeadCanon.app`
- confirm microphone and Accessibility state in the app matches System Settings
- confirm the app does not report `Ready` while blocked

Pass:
- one bundle path is in use for the whole checkpoint
- readiness is truthful

Do not proceed if:
- bundle paths are mixed
- the app misreports permission state

## Phase 2: Instrument The Full Latency Path
Question:
Can the app prove where time is being spent in a single dictation turn and preserve that evidence outside the UI?

Required timing checkpoints:
- hotkey press timestamp
- hotkey release timestamp
- visible processing state timestamp
- recording finalized timestamp
- request start timestamp
- response complete timestamp
- insertion complete timestamp
- recorded clip duration
- recorded file size
- transcript character or word count
- backend identifier
- `x-request-id`
- `openai-processing-ms`
- request mode
- streaming fallback flag
- HTTP status
- response content type

Implementation note:
- detailed timing and request metadata may be richer in debug mode, but one metadata-only attempt record should still be persisted locally by default
- use a versioned JSONL schema in `Application Support/HeadCanon/diagnostics/`
- keep transcript text out of the default log

Pass:
- one `TextEdit` turn and one `Codex` turn can be decomposed by phase
- local overhead can be separated from OpenAI processing time
- the latest attempt can be inspected from the terminal without opening the UI

Do not proceed if:
- timing still collapses multiple phases into one opaque “transcribing” wait
- the evidence still depends on screenshots or clipboard export

## Phase 2A: Persist Diagnostics Locally
Question:
Can the app retain per-attempt performance evidence in a terminal-readable local format?

Actions:
- add one append-only JSONL diagnostics log under `~/Library/Application Support/HeadCanon/diagnostics/`
- define a versioned attempt schema with session ID, timings, backend metadata, insertion outcome, and failure classification
- add a `latest.json` or equivalent fast-path pointer for quick inspection
- add log rotation and clear behavior
- add one small repo-local reader script for latest attempt and recent summaries

Implementation scope for this phase:
- add `Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift`
- add `Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift`
- centralize diagnostics-path resolution instead of rebuilding `Application Support` paths ad hoc
- emit one record only when an attempt reaches a terminal state:
  - inserted
  - transcription failed
  - insertion failed
  - timed out
  - canceled
- keep writes off the hot path; logging failure should downgrade to `OSLog` and never block dictation
- add one repo-local reader entrypoint under `Scripts/` for:
  - latest attempt
  - recent attempts
  - basic latency summary

Minimum record contents:
- schema version
- attempt ID
- session ID
- installed bundle identity
- target app or target class
- timing fields and derived durations
- backend request metadata
- insertion strategy and outcome
- one terminal failure stage and message
- transcript counts only by default, not transcript text

Pass:
- every terminal-state dictation attempt writes one local record
- a slow turn can be inspected from the terminal without using Settings
- diagnostics survive app relaunch

Do not proceed if:
- logging can block dictation
- default logs include raw transcript text

## Phase 3: No-Regret Quick Wins
Question:
What can be made faster immediately without changing product shape?

Actions:
- verify the already-landed quick wins against repeated installed-app runs
- keep the immediate hotkey-release state transition
- keep microphone refresh off the hotkey path
- keep default-path release-time insertion planning out of the hot path unless diagnostics mode needs it
- keep the lightest transcription response shape and metadata needed for the current UX

Pass:
- key-up visibly responds immediately
- short-phrase turns feel better even before deeper refactors

Do not proceed if:
- the “quick win” also weakens insertion safety or recovery behavior

## Phase 4: Shorten Key-Up To Request Start
Question:
What local work is delaying the start of transcription?

Actions:
- verify whether any meaningful local delay remains after the already-landed release-path cleanup
- keep recording-service teardown out of the critical request-start path
- keep request construction off the main actor
- only remove more pre-request work if repeated measurements show this phase is still non-trivial

Pass:
- `key-up -> request start` drops materially
- local sequencing is no longer the dominant source of delay on short turns

## Phase 5: Shorten Response Complete To Inserted
Question:
Why are opaque editors materially slower than native AX targets?

Actions:
- treat known opaque editors such as `Codex` as app-level paste targets early
- reduce repeated AX/context validation around a single paste operation
- keep the reduced paste wait unless measurements show it is still an artificial tax
- use repeated `Codex` versus `TextEdit` runs to prove whether insertion is still a first-order bottleneck

Pass:
- `Codex` is still slower than `TextEdit`, but no longer by an obviously artificial fixed tax
- wrong-target and secure-field protections still hold

## Phase 6: Warm The Fast Path
Question:
Is first-turn or per-turn setup making the app feel sluggish?

Actions:
- compare cold launch, first dictation turn, and warm repeated turns
- decide whether capture infrastructure should stay warm between turns
- measure whether per-turn session construction is materially affecting startup-to-recording feel

Pass:
- the difference between cold and warm turns is understood
- the supported path is optimized for repeated daily use

## Implementation Order
Prefer this write order so each pass stays reviewable:

1. `Sources/HeadCanon/Diagnostics/...`
2. `Sources/HeadCanon/App/HeadCanonModel.swift`
3. `Scripts/...` reader tooling
4. `Sources/HeadCanon/UI/SettingsRootView.swift`
5. `Tests/HeadCanonTests/HeadCanonTests.swift`
6. `Sources/HeadCanon/Audio/AudioCaptureService.swift`
7. `Sources/HeadCanon/Insertion/TextInsertionService.swift`
8. `Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift`

Keep deeper architecture experiments separate from the first speed pass when possible.

## Phase 7: Verify By Editor Class
Question:
Does the app feel fast enough in the actual editor classes it cares about?

App matrix:
- `TextEdit`
- `Codex`
- one browser textarea
- one Electron-style editor

For each app, record:
- cold versus warm turn
- short phrase
- one multi-sentence utterance
- phase timings
- chosen insertion strategy
- final result

Pass:
- `TextEdit` stays solid
- `Codex` is usable without a conspicuous latency penalty caused by avoidable local work
- slow turns are explainable from the local diagnostics log without screenshots

## Phase 8: Decide On Backend Evolution
Question:
After local-path fixes, is the OpenAI request/response leg still the dominant remaining delay?

Actions:
- keep the current streamed-with-fallback bounded path as the measured baseline
- compare `gpt-4o-mini-transcribe` against `gpt-4o-transcribe` only after the local path is already lean
- treat model choice as an evidence-backed product decision, not a default inherited from older docs
- use the persistent diagnostics log to separate:
  - streamed success
  - streamed fallback
  - standard request
  - server processing time
- if logs show frequent fallback or little benefit from streaming, compare the current streamed-with-fallback path against a standard bounded-only path
- if server time still dominates after that, compare:
  - bounded request mode choices
  - realtime transcription architecture
- do not switch architectures until the measured local path is already lean

Pass:
- backend changes are justified by measurements, not by guesswork

## Experiment Track
If bounded upload is still too slow after the local path is lean, use a separate experiment track for:

- standard bounded-only requests versus streamed-with-fallback bounded requests
- realtime transcription sessions

Do not mix those experiments into the first bounded-path cleanup pass. Keep the main path stable until the measurements justify a new default.

## Diagnostics Plan
Persistent diagnostics should follow these rules:

- metadata-only by default
- no raw transcript text without explicit debug mode
- one record per terminal-state attempt
- append-only JSONL with size-based rotation
- one stable schema version field on every record
- one session identifier per app launch
- one repo-local reader script in `Scripts/`
- one in-app action to open the diagnostics folder
- one in-app action to clear persistent diagnostics

The file log is the source of truth.
The Settings panel is a viewer, not the only storage location.

## Phase 9: Lock Defaults
Question:
What should be considered the supported fast path for `v1`?

Decisions to lock:
- default hotkey
- whether modifier-only hold remains supported
- default insertion path by editor class
- whether performance diagnostics stay hidden behind debug mode
- whether bounded upload remains the default transcription mode

These decisions must update together:
- `/Users/worldbuilder/Desktop/Head Canon/docs/V1_SPEC.md`
- `/Users/worldbuilder/Desktop/Head Canon/docs/USABILITY_CHECKLIST.md`
- runtime diagnostics copy
- settings copy

## Definition Of Usable
Call the app usable only when all of these are true:

- `/Applications/HeadCanon.app` launches normally
- readiness is reported truthfully
- the supported default hotkey works reliably
- recording start and stop are reliable
- short phrases usually land in about `2-3s` or less
- `TextEdit` succeeds `10/10`
- `Codex` is usable under the supported policy
- failures are explicit and recoverable
- latency differences between editor classes are explainable with evidence

## Checkpoint Template
Use this exact template after every meaningful pass:

- what was changed
- what was measured
- what actually happened
- what that rules out
- next highest-signal step
