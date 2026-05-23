# Head Canon Execution Plan

## Objective
Make the installed app at `/Applications/HeadCanon.app` feel ambient for short dictation while preserving the current safety and reliability bar.

The next plan has three priorities, in this order:

1. lock the current bounded path as the stable baseline
2. fix the two concrete failure clusters without weakening insertion safety
3. decide from evidence whether bounded dictation is done enough or whether a larger backend experiment is justified

The repo is no longer blocked on “can it ever transcribe and insert?”
The next phase is hardening and decision-making, not first-principles latency discovery.

## Current Audit
Already landed:

- installed app runtime at `/Applications/HeadCanon.app`
- permission onboarding and readiness UI
- bounded audio capture
- `gpt-4o-mini-transcribe` backend
- standard completed-recording transcription as the current default path
- direct AX insertion for strong native targets
- clipboard-first insertion support for known opaque editors such as `Codex`
- release-time versus insert-time insertion diagnostics
- immediate processing-state transition on hotkey release
- no microphone refresh on the hotkey path
- trimmed recording finalization before request start
- off-main transcription request construction plus backend and transport metadata in diagnostics
- reduced paste-path fixed wait versus the earlier `900ms` hold
- persistent local diagnostics under `~/Library/Application Support/HeadCanon/diagnostics/`
- repo-local diagnostics reader at `Scripts/diagnostics.swift`
- disk readiness thresholds, warning copy, and pre-start blocking before recording begins
- a reclaimable cache-space reserve so the installed app can keep a recording buffer on disk

Current measured evidence from the installed app:

- recent `20`-attempt run on `gpt-4o-mini-transcribe` shows:
  - failures: `8`
  - `request -> response p50`: `1751 ms`
  - `request -> response p95`: `30158 ms`
  - `release -> inserted p50`: `1719 ms`
  - `release -> inserted p95`: `2498 ms`
- the current path is materially faster and more stable than the older `4-7s` pattern
- the success path is still strong:
  - failure-free turns in the recent sample show about `1386 ms` `request -> response p50`
  - and about `1719 ms` `release -> inserted p50`
- the failure profile is now split into two distinct classes:
  - `transcription`: hard `30s` timeout failures
  - `insertion`: `Codex` safety blocks after successful transcription when focus changes before paste completes
- the strongest recent benchmark evidence is still warm-turn and `Codex`-heavy, not yet a full app-class matrix
- the diagnostics reader now supports rollups by app class, failure reason, and response-header timing, so the next gap is root-cause fixing rather than observability
- one guarded retry for transient transport failures is already in the repo; it does not address the hard timeout path or `Codex` focus-drift path
- `AGENTS.md` still names `gpt-4o-transcribe` as the initial implementation priority, but the currently healthy default is `gpt-4o-mini-transcribe`

## Working Rules
- test only `/Applications/HeadCanon.app`
- do not test `dist/HeadCanon.app`
- do not reinstall unless intentionally updating
- preserve one known-good bounded snapshot so regressions can be rolled back quickly
- preserve the working `TextEdit` path while improving `Codex` and other opaque editors
- track `TextEdit`, `Codex`, and browser targets separately; do not hide latency differences behind one overall average
- treat the local diagnostics log as the source of truth, not screenshots of the Settings UI
- do not log raw transcript text by default
- optimize for `p95` and failure rate now, not only `p50`
- do not add broad fallback trees or loose paste heuristics just to make more turns appear successful
- keep the stable bounded path separate from any larger experiments
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
- short-phrase `release -> inserted`:
  - `p50`: usually under about `2-3s`
  - `p95`: keep under about `3s` if practical on the bounded path
- diagnostics persistence overhead: negligible relative to the dictation loop and never user-visible

## Measurement Protocol
Use one explicit benchmark routine for every latency pass:

- label each benchmark series with:
  - app class
  - model
  - request mode
  - cold versus warm
  - short phrase versus multi-sentence
- measure one cold turn after launch
- measure at least `10` warm short-phrase turns in `Codex`
- measure at least `5` warm short-phrase turns in `TextEdit`
- measure at least `5` warm short-phrase turns in one browser textarea
- record `p50`, `p95`, and failure rate for each app class
- record a simple transcript-quality note when comparing models or retries
- record one multi-sentence turn in each app class being evaluated
- store each attempt as one local persistent diagnostics record
- use repo-local tooling to inspect the latest attempt rather than relying on screenshots

Do not call a latency phase complete based on one fast anecdotal run.

## Regression Gates
Every performance or hardening change must preserve all of the following:

- no wrong-target insertion
- no secure-field insertion
- no silent transcript loss
- no obvious transcript-quality regression accepted only for speed
- `TextEdit` remains solid
- failure recovery still works through last transcript or manual paste
- diagnostics writing failure never blocks dictation
- default logs do not retain raw transcript text
- the app never shows `Ready` while disk readiness is blocked
- warning-only low disk never hides a harder setup blocker
- pre-start readiness blocks persist to diagnostics instead of disappearing from history

If a change regresses one of these, revert to the locked baseline before continuing.

## Phase 1: Lock The Stable Baseline
Question:
What is the supported fast path for the next round of testing and hardening?

Lock these defaults together:

- app bundle: `/Applications/HeadCanon.app`
- transcription model: `gpt-4o-mini-transcribe`
- request mode: `Standard Completed Recording`
- opaque-editor insertion route: current clipboard-first `Codex` path
- diagnostics source of truth: persistent local file-backed attempt log

Pass:
- one stable baseline is defined
- future tests do not change multiple variables at once

## Phase 2: Benchmark The Baseline Properly
Question:
How good is the current bounded path in repeated real use?

Actions:
- preserve one known-good benchmark snapshot before each behavioral change
- run a cold-turn benchmark
- run at least `30-50` warm short-phrase turns in `Codex`
- run at least `10` turns in `TextEdit`
- run at least `5` turns in one browser target
- record:
  - success rate
  - `request -> response p50`
  - `request -> response p95`
  - `release -> inserted p50`
  - `release -> inserted p95`
  - dominant failure reason if any

Pass:
- the current bounded path has a truthful before/after baseline
- `Codex` and non-`Codex` behavior are no longer being inferred from anecdotes or model-only aggregates
- one known-good benchmark snapshot is recorded before any hardening or model switch
- each checkpoint includes the installed app's current disk readiness and free-space context

## Phase 3: Timeout Cancellation
Question:
What causes the remaining hard `30s` transcription failures?

Actions:
- cancel the in-flight transcription request when the app timeout fires
- keep timeout as one explicit failure path instead of allowing overlapping or zombie request behavior
- do not add broad retry behavior around the timeout path
- re-run the bounded benchmark after the cancellation fix

Pass:
- hard timeout failures become rarer or at least cleaner and more explainable
- the bounded path stays simple

Do not proceed if:
- timeout handling becomes more stateful or less predictable

## Phase 4: Codex Focus-Drift Hardening
Question:
Why do some successful transcriptions still fail before paste completes in `Codex`?

Actions:
- record the focused target identity at:
  - response complete
  - paste dispatch
  - safety-block failure
- tighten paste timing only if it reduces false safety blocks
- keep wrong-target protection strict
- do not weaken safety rules just to force more turns through

Pass:
- `Codex` insertion safety blocks become rarer
- the app still refuses to paste into the wrong target

Do not proceed if:
- the fix relies on blind paste behavior
- the safety policy becomes ambiguous

## Phase 5: Strengthen Diagnostics Summaries
Question:
Can the team answer “what failed and how often?” from the terminal in under a minute?

Actions:
- keep `latest`, `recent`, and summary tooling healthy
- add or maintain summaries by:
  - app
  - model
  - failure reason
  - request-to-headers timing when available
- keep one comparison artifact per major pass with:
  - app
  - model
  - success rate
  - `p50`
  - `p95`
  - notable failure mode

Pass:
- slow or failed turns are explainable without opening the Settings UI
- benchmarking does not depend on ad hoc manual interpretation

## Phase 6: Model Comparison
Question:
Is `gpt-4o-mini-transcribe` still the best bounded default once the current path is stable?

Actions:
- keep the current bounded baseline intact
- run a controlled comparison between:
  - `gpt-4o-mini-transcribe`
  - `gpt-4o-transcribe`
- compare by app class using the same test discipline
- decide based on:
  - failure rate
  - `request -> response p50`
  - `request -> response p95`
  - transcript quality

Pass:
- the default bounded model is an explicit product decision, not inherited repo drift
- the chosen default is justified by both latency and transcript quality

## Phase 7: Architecture Decision Gate
Question:
Is the bounded path now good enough, or is a larger architecture experiment justified?

Decision rules:
- if the bounded path meets the usability bar, harden it and stop tuning
- if median speed is good but tail latency remains too high, prototype realtime transcription
- if network dependence remains the main pain, prototype a local backend such as `whisper.cpp`

Do not start architecture experiments until:

- the bounded baseline is benchmarked
- the current path has been hardened
- the model comparison is complete or deliberately waived

At this gate, produce one short decision artifact with:

- current bounded baseline
- success rate
- `p50`
- `p95`
- known failure mode
- transcript-quality tradeoff if any

## Experiment Track
If the bounded path is not good enough after hardening, use a separate experiment track for:

- realtime transcription sessions
- `whisper.cpp` local/offline backend

Do not destabilize the bounded default while running those experiments.

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

## Phase 8: Lock Defaults
Question:
What should be considered the supported fast path for `v1`?

Decisions to lock:

- default hotkey
- whether modifier-only hold remains supported
- default transcription model
- default request mode
- default insertion path by editor class
- whether performance diagnostics stay hidden behind debug mode

These decisions must update together:

- `/Users/worldbuilder/Desktop/Head Canon/docs/V1_SPEC.md`
- `/Users/worldbuilder/Desktop/Head Canon/docs/USABILITY_CHECKLIST.md`
- runtime diagnostics copy
- settings copy

Before locking defaults, run one post-hardening audit:

- what improved
- what regressed or stayed risky
- whether the bounded path is good enough to freeze

## Definition Of Usable
Call the app usable only when all of these are true:

- `/Applications/HeadCanon.app` launches normally
- readiness is reported truthfully
- the supported default hotkey works reliably
- recording start and stop are reliable
- short phrases usually land in about `1-3s`
- `TextEdit` succeeds `10/10`
- `Codex` is usable under the supported policy
- failures are rare, explicit, and recoverable
- latency differences between editor classes are explainable with evidence
- `p95` is stable enough that the app still feels trustworthy in normal use

## Checkpoint Template
Use this exact template after every meaningful pass:

- what was changed
- what was measured
- what actually happened
- what that rules out
- next highest-signal step
