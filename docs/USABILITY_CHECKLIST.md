# Head Canon Usability Checklist

This checklist is intentionally narrow.
It is for proving the installed app is actually usable for real dictation before broader release claims.

## Test Discipline
- [ ] Test only `/Applications/HeadCanon.app`
- [ ] Do not test `dist/HeadCanon.app`
- [ ] Do not switch bundle paths during the checkpoint
- [ ] Track `TextEdit`, `Codex`, and browser targets separately during latency work
- [ ] Lock one bounded baseline before comparing anything else
- [ ] Preserve one known-good bounded snapshot for rollback
- [ ] For any failure, classify exactly one stage:
  - `permission/readiness`
  - `hotkey delivery`
  - `recording start`
  - `recording finalization`
  - `transcription request`
  - `transcription quality`
  - `insertion context`
  - `insertion transport`
  - `safety policy block`

## Setup Readiness
- [ ] The installed app launches and opens normally
- [ ] The app path shown in settings is `/Applications/HeadCanon.app`
- [ ] Microphone access is granted
- [ ] Accessibility access is granted to the installed app bundle
- [ ] After relaunch, the app itself reports both permissions accurately
- [ ] The app does not show `Ready` while permissions are missing
- [ ] The app does not show `Ready` while disk readiness is blocked
- [ ] Low-disk warning copy does not hide a harder blocker such as permissions or API key setup
- [ ] If the cache reserve feature is enabled, the app reports the reserve truthfully in live diagnostics or settings

## Backend Readiness
- [ ] An OpenAI API key is stored
- [ ] The API key validates successfully
- [ ] The app reports the key as valid
- [ ] The app makes it explicit that this backend sends audio to OpenAI
- [ ] The current bounded baseline is known before the run starts:
  - model
  - request mode
  - insertion path

## Input Readiness
- [ ] The current hotkey mode is known before the test starts
- [ ] The microphone is set to `System Default` for the first smoke test
- [ ] The first hotkey comparison notes whether it used modifier-hold or non-modifier push-to-talk

## Latency Instrumentation
- [ ] The app records hotkey press time
- [ ] The app records hotkey release time
- [ ] The app records the first visible processing-state transition after key-up
- [ ] The app records recording finalized time
- [ ] The app records transcription request start time
- [ ] The app records transcription response complete time
- [ ] The app records insertion complete time
- [ ] The app records clip duration and file size
- [ ] The app records transcript length
- [ ] The app records backend identifier
- [ ] The app records request IDs and available OpenAI processing metadata
- [ ] The app records request mode, fallback usage, status code, and response content type
- [ ] Detailed timing can be enabled without permanently bloating the normal fast path

## Persistent Diagnostics
- [ ] Each completed or failed dictation attempt is written to a local diagnostics log
- [ ] Pre-start readiness blocks are written to the same local diagnostics log
- [ ] The diagnostics log survives app relaunch
- [ ] The latest attempt can be read from the terminal without opening Settings
- [ ] The latest attempt is also available through a fast-path artifact such as `latest.json`
- [ ] The latest attempt includes request mode, fallback usage, status, request ID, and processing metadata
- [ ] The latest attempt or live state includes disk readiness status and free-space context when available
- [ ] Each record includes a schema version and session identifier
- [ ] Default diagnostics do not retain raw transcript text
- [ ] Diagnostics writing failure does not block dictation
- [ ] A clear action exists for the persistent diagnostics log
- [ ] A repo-local script exists to inspect the latest attempt or recent attempts
- [ ] The repo-local script can print latency summaries by model and over recent attempts
- [ ] The repo-local script can summarize by app class and failure reason
- [ ] The repo-local script can include request-to-headers timing when that field exists
- [ ] The repo-local script can cleanly separate transcription failures from insertion safety failures
- [ ] The repo-local script is treated as ready for soak-pass analysis, not a pending tooling task

## Perceived Responsiveness
- [ ] The UI leaves `recording` immediately on key-up
- [ ] The app does not appear idle between key-up and actual transcription work
- [ ] The status copy makes it clear whether the app is finalizing, transcribing, or inserting

## Short-Phrase Latency Pass
- [ ] Run one short-phrase turn in `TextEdit`
- [ ] Run one short-phrase turn in `Codex`
- [ ] Run repeated warm turns in both apps, not just one sample
- [ ] Label the benchmark series with app, model, request mode, and cold versus warm
- [ ] Record `p50`, `p95`, and failure rate
- [ ] Compare `key-up -> visible processing state`
- [ ] Compare `key-up -> recording finalized`
- [ ] Compare `request start -> response complete`
- [ ] Compare `response complete -> inserted`
- [ ] Record whether `Codex` is slower because of local insertion cost or backend time
- [ ] Record whether request time remained dominant after the local hot-path cuts already in the repo

## Soak Test Pass
- [ ] Run `30-50` warm short-phrase turns in `Codex`
- [ ] Run `10` turns in `TextEdit`
- [ ] Run `5` turns in one browser target
- [ ] Do not treat a `Codex`-heavy run as a full app-matrix benchmark
- [ ] Group failures by stage
- [ ] Group results by app class
- [ ] Record the dominant failure reason, if any
- [ ] Preserve one known-good summary artifact before changing the model or retry policy

## Timeout Hardening
- [ ] App-level transcription timeout cancels the in-flight request cleanly
- [ ] Timeout failures are explicit and do not leave zombie request behavior behind
- [ ] Timeout handling does not add a retry maze

## Cold Versus Warm Turn Pass
- [ ] Measure the first dictation turn after app launch
- [ ] Measure at least one warm repeated turn in `TextEdit`
- [ ] Measure at least one warm repeated turn in `Codex`
- [ ] Note whether cold-start overhead is materially different from repeated use

## Multi-Sentence Dictation Pass
- [ ] Run one short-phrase dictation
- [ ] Run one two-to-three sentence dictation
- [ ] If the returned text is short, compare it against clip duration and stop cause
- [ ] The app does not silently reduce a multi-sentence utterance to only the first sentence

## Hotkey Comparison
- [ ] `Hold Control + Option` has been tested explicitly
- [ ] `Control + Option + Space` has been tested explicitly
- [ ] The two modes have been compared for truncation and latency
- [ ] If modifier-hold is worse, that is visible in the checkpoint notes

## Native Insertion Safety
- [ ] Open `TextEdit`
- [ ] Place the cursor in a normal editable text area
- [ ] Run one full dictation loop
- [ ] Transcript text is inserted into `TextEdit`
- [ ] If insertion fails, the transcript remains available for manual recovery

## Opaque-Editor Insertion Diagnostics
- [ ] Run at least one `Codex` dictation turn
- [ ] Record the chosen insertion strategy
- [ ] Record release-time versus insert-time context if diagnostics mode is enabled
- [ ] Record whether the focused target changed between response completion and paste completion
- [ ] The result is explainable without guessing
- [ ] The insertion path does not impose a large unexplained fixed wait

## Failure Safety
- [ ] If setup is incomplete, the app shows a specific blocker
- [ ] If disk space is below the hard threshold, the app blocks recording before start with actionable copy
- [ ] If transcription fails, the app shows a clear error instead of silently doing nothing
- [ ] If insertion fails, the transcript remains available for manual recovery
- [ ] Dictated text is never lost silently
- [ ] Secure targets remain blocked
- [ ] Performance changes do not weaken wrong-target protections
- [ ] Logging changes do not store raw transcript text by default
- [ ] Retry logic, if present, does not create duplicate insertion risk
- [ ] If a speed experiment regresses reliability or quality, the app can revert to the known-good bounded snapshot
- [ ] Insertion safety blocks remain strict when focus genuinely changed

## Recovery Speed
- [ ] If insertion fails, the user can recover the transcript quickly
- [ ] The app still exposes a practical path through last transcript or manual paste

## Repeatability Gate
- [ ] Recording starts `10/10`
- [ ] Recording finalizes `10/10`
- [ ] Multi-sentence dictation is not truncated during ordinary use
- [ ] `TextEdit` insertion succeeds `10/10`
- [ ] No silent failures occur during the run

## Latency Gate
- [ ] Hotkey response feels immediate
- [ ] `key-up -> visible processing state` is under about `100ms`
- [ ] `key-up -> recording finalized` is under about `300ms` on short turns
- [ ] Short-phrase `release -> inserted p50` is usually under about `2-3s`
- [ ] Short-phrase `release -> inserted p95` is acceptable for normal use
- [ ] `Codex` is not paying a large avoidable local delay compared with `TextEdit`
- [ ] The loop feels ambient enough for normal short dictation

## Model Decision
- [ ] The bounded model comparison between `gpt-4o-mini-transcribe` and `gpt-4o-transcribe` has been run or deliberately waived
- [ ] The default model choice is explained by evidence, not inherited from older docs
- [ ] The chosen default did not win on speed alone while materially hurting transcript quality

## Architecture Decision Gate
- [ ] There is an explicit decision whether the bounded path is “done enough”
- [ ] If not, the next experiment is named explicitly:
  - realtime transcription
  - `whisper.cpp`
- [ ] Experiments are kept separate from the stable bounded baseline

## Minimum Usable Definition
- [ ] The installed app at `/Applications/HeadCanon.app` captures full short and multi-sentence utterances reliably
- [ ] The loop is reliable enough to repeat without guesswork
- [ ] The app reports readiness truthfully
- [ ] `TextEdit` remains solid while broader editor support is improved
- [ ] `Codex` is usable under the supported policy
- [ ] The app provides a clear recovery path when something fails
- [ ] A slow or failed turn can be explained from the local diagnostics log without screenshots

## Not Part Of This Checklist Yet
These are important, but they come after the current hardening pass:

- offline backend validation
- signing stability across updates
- broader release hardening
- realtime transcription as the default path
