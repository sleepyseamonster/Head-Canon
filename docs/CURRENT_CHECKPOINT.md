# Current Checkpoint

## Product Definition
`Head Canon` should be a local-first macOS dictation utility with one dependable core loop:

1. invoke from anywhere with a global hotkey
2. show immediate visible recording state
3. capture bounded microphone audio
4. transcribe it quickly
5. insert text into the currently focused app

This product is not a dashboard, not a general AI workspace, and not a vague speech experiment.
It is a utility. The entire project should be judged by whether the installed app can complete that loop reliably and fast enough to feel ambient.

## Current Audit
What exists:

- installed app bundle at `/Applications/HeadCanon.app`
- microphone and accessibility onboarding UI
- keychain-backed OpenAI API key storage
- persisted preferences
- bounded audio capture service
- request-based OpenAI transcription backend
- accessibility-based insertion service plus app-level clipboard transport
- floating recording/transcribing status overlay
- release-time versus insert-time insertion diagnostics
- in-memory latency timings and backend metadata visible in Settings for the latest attempt
- immediate processing-state transition on hotkey release
- trimmed recording-finalization and request-start hot path
- streamed transcription with automatic fallback to standard bounded requests

What the current source strongly suggests:

- the largest remaining delay is probably the transcription request/response leg, not hotkey handling or insertion
- the app now records enough in-memory timing and backend metadata to separate local delay from request time
- at least one recent installed-app run already showed a large `request start -> response complete` gap on a very small clip, which reinforces that backend time is the main remaining suspect
- those diagnostics are still trapped in memory and the Settings UI, so terminal inspection still depends on screenshots or manual copy/export
- the repo default is still `gpt-4o-mini-transcribe`, and model choice should remain evidence-driven

## Current Blockers
1. `persistent diagnostics gap`
   - the app records useful timing and backend metadata, but only in memory
   - there is no local append-only attempt log that can be read from the terminal
2. `backend observability gap`
   - the UI shows the latest attempt, but there is no persistent file-backed source of truth for repeated speed runs
   - the current workflow still depends on screenshots or manual UI inspection
3. `request/response bottleneck`
   - current real-use evidence points to the transcription request leg as the dominant remaining delay
   - the app now needs persistent logs to prove whether a slow turn used streaming, fallback, or just waited on the server
4. `model-default ambiguity`
   - the product direction docs are not fully aligned on whether `gpt-4o-mini-transcribe` or `gpt-4o-transcribe` should be the baseline
   - that choice should be locked only after local-path latency is measured and trimmed

Observed benchmark example:

- one recent installed-app run showed about `5.98s` in `request start -> response complete` for a roughly `1.76s` / `45 KB` clip
- that is not enough data to lock a backend decision, but it is enough to justify making persistent request metadata the next concrete work item

## Audit Of The Old Plan
What the old plan got right:

- it kept the installed app as the source of truth
- it treated truncation and insertion reliability as real product risks
- it forced explicit failure classification

What the old plan was missing:

- a phase-by-phase latency budget
- a distinction between “feels faster” and “is actually faster”
- a no-regret quick-wins phase
- separate treatment for `TextEdit` versus `Codex`
- a hard gate before jumping to streaming or realtime backend work
- a benchmark protocol for cold versus warm turns and repeated runs
- explicit regression gates so speed work does not silently weaken safety
- a persistent local diagnostics log and repo-local read path

What the old plan now also overstated:

- several local hot-path cuts as if they were still future work
- streamed transcription as a hypothetical experiment instead of a path that is already in the repo with fallback

## Rules For The Next Pass
Use these rules during the next latency pass:

1. Test only the installed app at `/Applications/HeadCanon.app`.
2. Do not switch bundle paths during the same checkpoint.
3. Preserve the working `TextEdit` path while improving `Codex` and other opaque editors.
4. Track `TextEdit` and `Codex` separately.
5. Every failure must be classified into exactly one stage:
   - hotkey did not fire
   - recording did not start
   - recording did not finalize
   - transcription request was delayed locally
   - transcription request failed remotely
   - insertion context was insufficient
   - insertion transport was slow or failed
   - app misreported permission or readiness state
6. Each checkpoint note must include:
   - what changed
   - what was measured
   - what actually happened
   - what that rules out
   - the next highest-signal step
7. Every timing claim should note whether it came from a cold turn, a warm turn, or repeated warm runs.
8. Do not move to backend experiments until the bounded local path has been measured and trimmed first.
9. The Settings panel is a viewer, not the canonical diagnostics store.
10. Default diagnostics must remain metadata-only and local-first.

Reference docs for this pass:

- [EXECUTION_PLAN.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/EXECUTION_PLAN.md)
- [USABILITY_CHECKLIST.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/USABILITY_CHECKLIST.md)

## Immediate Next Steps
1. Add a diagnostics record model and store under `Sources/HeadCanon/Diagnostics/`.
2. Append one metadata-only JSONL record per terminal-state dictation attempt under `Application Support/HeadCanon/diagnostics/`.
3. Add a `latest.json` fast-path artifact plus bounded rotation for history files.
4. Add a repo-local reader script so the latest attempt and recent summaries can be inspected from the terminal.
5. Only after that, resume repeated `TextEdit` / `Codex` speed runs using the file-backed log as the source of truth.
6. If request time is still dominant after that evidence is easy to inspect, decide whether to keep the current streamed-with-fallback path, drop back to standard bounded requests, compare models, or move toward realtime.

## Definition Of “Going Smoother”
The project will go smoother when each checkpoint has:

- one bundle path
- one clear latency question
- one measured before/after result
- one explicit `TextEdit` comparison
- one explicit `Codex` comparison
- one note about cold versus warm behavior
- one terminal-readable diagnostics artifact
- one next step that follows from evidence

Until then, backend speculation is mostly noise.
