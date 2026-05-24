# Head Canon Execution Plan

## Objective
Make the installed app at `/Applications/HeadCanon.app` feel ambient for short dictation while extending that reliability into browser text boxes with honest verification and rollback-safe architecture.

The next plan has four priorities, in this order:

1. lock the current bounded path as the stable rollback baseline
2. define browser target taxonomy, diagnostics, and protocol before adding browser heuristics
3. build a Chromium companion plus local browser fixtures before claiming browser support
4. return to timeout/Codex hardening only after browser evidence capture is strong enough

The repo is no longer blocked on “can it ever transcribe and insert?”
The next phase is browser-capable hardening and evidence capture, not first-principles latency discovery.

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
- browser-aware taxonomy types and companion-protocol scaffolding
- browser-aware insertion diagnostics fields for target class, editor family, and verification mode

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
- there is still no browser companion, no browser fixture page, and no site-specific browser matrix evidence

## Working Rules
- test only `/Applications/HeadCanon.app`
- do not test `dist/HeadCanon.app`
- do not reinstall unless intentionally updating
- preserve one known-good bounded snapshot so regressions can be rolled back quickly
- preserve the working `TextEdit` path while browser support lands beside the current AX/paste fallback
- track `TextEdit`, `Codex`, and browser targets separately; do not hide latency differences behind one overall average
- treat the local diagnostics log as the source of truth, not screenshots of the Settings UI
- do not log raw transcript text by default
- optimize for `p95` and failure rate now, not only `p50`
- do not add broad fallback trees or loose paste heuristics just to make more turns appear successful
- keep the stable bounded path separate from browser-companion experiments and larger backend experiments
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
- no browser target is treated as supported unless it ends in one explicit truth state
- companion protocol changes must be versioned and rollback-safe

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

## Browser Architecture Rules
- AX remains the cross-app baseline and rollback path
- browser support should prefer extension-assisted insertion over site-blind AX heuristics
- browser insertion should classify targets as:
  - `plainTextControl`
  - `richEditable`
  - `framedEditable`
  - `appWrappedWebEditor`
  - `unsupportedOrSecure`
- browser insertion should execute in this order:
  - text-control insertion
  - rich-editor range insertion
  - real clipboard paste fallback
- every browser insertion command must carry:
  - protocol version
  - operation id
  - target fingerprint
  - expiry time
- browser verification should prefer:
  - exact readback for plain controls
  - transcript-presence readback for rich editors
  - honest `unverified` when safe readback is unavailable
- no retry may create a duplicate insert into the same browser target

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

## Phase 2: Browser Taxonomy And Diagnostics
Question:
Can the repo describe browser failures precisely before adding browser-specific runtime behavior?

Actions:
- define browser target classes in code and docs
- persist browser context in diagnostics:
  - browser identity
  - target class
  - editor family
  - verification mode
  - origin/title/frame metadata when available
  - operation id and protocol version when available
- keep `latest`, `recent`, and summary tooling healthy enough to expose that context

Pass:
- the team can tell whether a browser miss came from the wrong editor class, weak readback, or missing companion context
- browser diagnostics do not depend on screenshots

## Phase 3: Companion Protocol
Question:
What must the app and browser extension agree on before browser insertion starts?

Actions:
- version the native app ↔ companion protocol
- define message envelopes for:
  - health check
  - focused-target snapshot
  - insert transcript
  - insert result
- require:
  - operation id
  - target fingerprint
  - expiry time
  - explicit inserted/unverified/expired/unsupported outcomes

Pass:
- the companion contract is explicit and testable before extension work begins
- future extension and app builds can fail safely on version drift

## Phase 4: Chromium Companion Scaffold
Question:
Can Head Canon gain browser-aware insertion in Chromium browsers without weakening the current app?

Actions:
- scaffold a Chrome/Chromium companion
- add native messaging host support
- add focused-target detection across ordinary pages, frames, and shadow DOM
- support generic:
  - `input`
  - `textarea`
  - `contenteditable`

Pass:
- the repo has one real browser lane, not only planner heuristics
- the current AX/paste fallback still works when the companion is absent

## Phase 5: Local Browser Fixtures
Question:
Can browser insertion be debugged locally before testing live sites?

Actions:
- create a fixture page set with:
  - plain input
  - textarea
  - contenteditable
  - iframe editor
  - shadow DOM editor
  - secure-field negative case
- add protocol and fixture-driven tests for:
  - target discovery
  - insertion
  - verification
  - expiry
  - duplicate-insert protection

Pass:
- generic browser behavior is measurable before site-specific heuristics begin

## Phase 6: Chromium Evidence Matrix
Question:
Which browser targets actually work once generic support exists?

Actions:
- run the first Chromium matrix on:
  - generic textarea
  - `ChatGPT`
  - `Google Search`
  - `Gmail`
  - one iframe-backed editor
- promote site-specific adapters only when generic support is not enough

Pass:
- browser support claims are evidence-backed
- `Google Docs` remains a hard-target lane unless the evidence says otherwise

## Phase 7: Safari Companion
Question:
Can the same browser model be repeated on Safari without inventing a second product architecture?

Actions:
- mirror the protocol and target taxonomy with a Safari Web Extension
- rerun the generic fixture pass and the browser matrix

Pass:
- Safari support follows the same explicit target and truth-state model

## Phase 8: Return To Fallback Hardening
Question:
What bounded-path work is still worth doing once browser observability is strong?

Actions:
- return to timeout cancellation
- return to `Codex` focus-drift hardening
- run controlled bounded model comparison only after the browser lane is no longer blind

Pass:
- fallback hardening continues with better evidence and clearer product priorities

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

## Phase 9: Lock Defaults
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

## Stop Condition
Keep working until every item below is true or a hard external blocker requires user input:

- `/Applications/HeadCanon.app` includes the browser-lane changes and is the only app under test
- the Chromium companion is integrated with the app strongly enough to provide real extension-driven browser target snapshots
- persisted diagnostics include real browser snapshot fields for supported Chromium targets:
  - browser host
  - origin
  - page title
  - frame path or identifier
  - target fingerprint
  - operation id
  - protocol version
- the installed app can perform companion-driven insertion for generic Chromium targets:
  - `input`
  - `textarea`
  - `contenteditable`
- the local fixture matrix passes for Chromium on:
  - plain input
  - textarea
  - contenteditable
  - iframe editor
  - shadow DOM editor
  - secure-field negative case
- the Chromium installed-app matrix has evidence for:
  - generic textarea
  - `ChatGPT`
  - `Google Search`
  - `Gmail`
  - one iframe-backed editor
- each tested Chromium target is explicitly classified as:
  - `verified`
  - `unverified fallback`
  - `unsupported in v1`
- the Safari companion is implemented enough to run the same generic fixture matrix and use the same truth-state model
- the fallback bounded path remains intact:
  - no silent transcript loss
  - no wrong-target insertion regression
  - `TextEdit` still succeeds
  - `Codex` remains usable under the supported policy
- docs and support policy are updated from evidence, not assumptions

If a checkpoint does not satisfy the full stop condition, the next step is not “done”; it is “continue with the highest-risk remaining unmet item.”

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
