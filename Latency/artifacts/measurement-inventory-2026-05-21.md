date: 2026-05-21
status: complete
owner: Latency
purpose: Inventory every repo-local latency and performance-measurement surface.

# Latency Measurement Inventory

## What This Audit Found
The repo already has a real end-to-end measurement path for the bounded dictation loop:

1. runtime timestamps and transport metadata are captured in-app
2. each attempt is persisted to a local diagnostics store
3. the latest and recent attempts can be reviewed in Settings or from the terminal
4. benchmark summaries already exist in docs and historical artifacts
5. tests cover both successful timing capture and several failure-path diagnostics

This means the current gap is not observability. The current gap is deciding which numbers matter most and using them to harden the remaining tail failures.

## Current Audit Summary
- User-perceived timing is measured across press, release, finalization, request, response, and insertion phases.
- Transport metadata is measured for both successful and failed OpenAI transcription requests.
- The diagnostics schema also captures insertion context, strategy choice, and clipboard recovery, which makes latency investigations explainable when a turn is "fast but failed."
- The current historical baseline artifact lives outside `Latency/` in `D-Bug/`, so this inventory records it here for future reuse.

## Measurement Surfaces

### Persistent diagnostics store
- [Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift:3)
  Defines the durable diagnostics storage contract.
- [Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift:49)
  Persists each attempt to `attempts.jsonl` and `latest.json`.
- [Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift:92)
  Stores diagnostics under `~/Library/Application Support/HeadCanon/diagnostics/`.
- [Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift:132)
  Rotates `attempts*.jsonl` files so the log stays bounded.

### Attempt record schema
- [Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift:16)
  Timing fields cover press-to-recording-start, release-to-finalizing, release-to-finalized, finalized-to-request, request-to-response, response-to-insertion, and release-to-insertion.
- [Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift:45)
  Backend fields capture request mode, fallback usage, HTTP status, request ID, OpenAI processing time, response-header timing, and transport/network failure details.
- [Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift:60)
  Insertion fields capture target app, capability profile, chosen/applied strategy, placeholder state, and compatibility signals.
- [Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift:95)
  The full record binds timing, backend, insertion, failure, and clipboard recovery into one per-attempt artifact.

### In-app timing capture
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:232)
  `RecordingAttemptDiagnostics` is the app’s in-memory timing model.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:259)
  Derived durations convert event timestamps into performance segments.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:405)
  Successful transcription updates transcript counts and backend timing metadata.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:435)
  Failed transcription paths retain transport and network timing context when available.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:555)
  Insertion completion is timestamped explicitly, enabling end-to-insert measurement.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:2066)
  `makePersistentAttemptRecord` serializes the in-memory timing and insertion context into the persisted attempt schema.

### Human-readable in-app diagnostics
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:803)
  Builds the full plain-text diagnostics report for copy/export.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:839)
  Emits the recording timing report, including request, insertion, and transport metadata.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift:884)
  Includes release-time and insert-time insertion routing details so timing outliers can be tied to execution context.

### OpenAI transport timing capture
- [Sources/HeadCanon/Transcription/TranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/TranscriptionBackend.swift:9)
  Defines request modes, transport failure stages, success metadata, and failure context for transcription timing.
- [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift:110)
  Streaming path measures time to response headers and preserves failure stage information.
- [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift:177)
  Standard completed-recording path measures response-header timing for the default bounded path.
- [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift:248)
  Request construction is pushed off-main, which is both a performance choice and a measurable boundary.
- [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift:284)
  Response metadata captures `x-request-id`, `openai-processing-ms`, content type, and header timing.
- [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift:366)
  `elapsedMilliseconds` is the shared helper for response-header timing measurement.
- [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift:397)
  Failure contexts preserve transport stage and network error details for slow or failed requests.

### Settings UI diagnostics surface
- [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift:345)
  Hosts the diagnostics panel.
- [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift:407)
  Shows the latest recording-attempt metrics in the app.
- [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift:420)
  Shows insertion routing context beside timing data.
- [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift:625)
  Renders each timing and backend field directly, including response-header timing and OpenAI processing time.

### Repo-local terminal tooling
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:79)
  Reads the same persistent diagnostics directory used by the installed app.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:98)
  Loads recent attempts from rotated JSONL files.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:129)
  Calculates percentiles for timing rollups.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:199)
  Produces summary blocks with attempts, failures, fallbacks, request timings, header timings, and release-to-insert timings.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:219)
  Prints a latest-attempt snapshot with timing, backend, failure, and clipboard-recovery context.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:313)
  Groups summary output by app class.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:337)
  Groups summary output by failure class.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:357)
  Exposes a stable CLI surface: `latest`, `recent`, `summary`, `summary-by-model`, `summary-by-app-class`, `summary-by-failure`.

### Tests that verify the measurement pipeline
- [Tests/HeadCanonTests/HeadCanonTests.swift](/Users/worldbuilder/Desktop/Head%20Canon/Tests/HeadCanonTests/HeadCanonTests.swift:848)
  Verifies a successful dictation writes a full diagnostic trail, including timing fields and persisted insertion context.
- [Tests/HeadCanonTests/HeadCanonTests.swift](/Users/worldbuilder/Desktop/Head%20Canon/Tests/HeadCanonTests/HeadCanonTests.swift:899)
  Verifies the concrete diagnostics store writes `latest.json` and `attempts.jsonl`, then clears them cleanly.
- [Tests/HeadCanonTests/HeadCanonTests.swift](/Users/worldbuilder/Desktop/Head%20Canon/Tests/HeadCanonTests/HeadCanonTests.swift:927)
  Verifies the timeout path records transcription timing and cancels the in-flight request.
- [Tests/HeadCanonTests/HeadCanonTests.swift](/Users/worldbuilder/Desktop/Head%20Canon/Tests/HeadCanonTests/HeadCanonTests.swift:959)
  Verifies transport failure diagnostics preserve response-header timing and network error fields.

### Product docs and historical benchmark artifacts
- [docs/V1_SPEC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/V1_SPEC.md:180)
  States the top-level performance goals and latency posture for `v1`.
- [docs/CURRENT_CHECKPOINT.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/CURRENT_CHECKPOINT.md:23)
  Summarizes the current installed-app evidence, baseline metrics, and next latency questions.
- [docs/EXECUTION_PLAN.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/EXECUTION_PLAN.md:19)
  Defines the measurement protocol, latency budgets, and regression gates for future performance work.
- [docs/USABILITY_CHECKLIST.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/USABILITY_CHECKLIST.md:172)
  Keeps the release-to-insert usability goals visible.
- [D-Bug/artifacts/installed-app-baseline-2026-05-21.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/artifacts/installed-app-baseline-2026-05-21.md:1)
  Historical installed-app baseline artifact that predates the newest Latency workspace audit.
- [D-Bug/logs/checkpoints.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/logs/checkpoints.md:1)
  Captures the previous debugging checkpoint and confirms insertion is the dominant live failure.
- [D-Bug/MEMORY.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/MEMORY.md:1)
  Stores durable observations that installed-app evidence matters more than green unit tests at this stage.

## Audit
- The measurement story is stronger than I expected: the repo can already explain most slow or failed turns without guessing.
- The biggest observability strength is the combination of timing data with insertion-routing context. That prevents us from mislabeling "failed quickly" and "succeeded slowly" as the same problem.
- The main weakness is historical sprawl. The measurement surfaces are spread across source, docs, and `D-Bug/`, which is why this `Latency/` inventory now exists.

## Next Recommended Steps
- Keep using [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:357) as the fast terminal truth source for timing passes.
- Save future installed-app benchmark summaries directly in [Latency/artifacts](/Users/worldbuilder/Desktop/Head%20Canon/Latency/artifacts) so latency history stops fragmenting across agent folders.
- If we really are near peak bounded-path performance, the next highest-signal work is tail cleanup:
  - `Codex` insertion safety-block rate
  - hard timeout handling
  - app-class-specific p95 behavior
