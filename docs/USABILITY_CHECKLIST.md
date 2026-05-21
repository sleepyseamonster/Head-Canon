# Head Canon Usability Checklist

This checklist is intentionally narrow.
It is for proving the installed app is actually usable for real dictation before broader release claims.

## Test Discipline
- [ ] Test only `/Applications/HeadCanon.app`
- [ ] Do not test `dist/HeadCanon.app`
- [ ] Do not switch bundle paths during the checkpoint
- [ ] Track `TextEdit` and `Codex` separately during latency work
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

## Backend Readiness
- [ ] An OpenAI API key is stored
- [ ] The API key validates successfully
- [ ] The app reports the key as valid
- [ ] The app makes it explicit that this backend sends audio to OpenAI

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
- [ ] The diagnostics log survives app relaunch
- [ ] The latest attempt can be read from the terminal without opening Settings
- [ ] The latest attempt is also available through a fast-path artifact such as `latest.json`
- [ ] The latest attempt includes request mode, fallback usage, status, request ID, and processing metadata
- [ ] Each record includes a schema version and session identifier
- [ ] Default diagnostics do not retain raw transcript text
- [ ] Diagnostics writing failure does not block dictation
- [ ] A clear action exists for the persistent diagnostics log
- [ ] A repo-local script exists to inspect the latest attempt or recent attempts
- [ ] The repo-local script can print at least a basic latency summary

## Perceived Responsiveness
- [ ] The UI leaves `recording` immediately on key-up
- [ ] The app does not appear idle between key-up and actual transcription work
- [ ] The status copy makes it clear whether the app is finalizing, transcribing, or inserting

## Short-Phrase Latency Pass
- [ ] Run one short-phrase turn in `TextEdit`
- [ ] Run one short-phrase turn in `Codex`
- [ ] Run repeated warm turns in both apps, not just one sample
- [ ] Record at least `p50` and the slowest observed result
- [ ] Compare `key-up -> visible processing state`
- [ ] Compare `key-up -> recording finalized`
- [ ] Compare `request start -> response complete`
- [ ] Compare `response complete -> inserted`
- [ ] Record whether `Codex` is slower because of local insertion cost or backend time
- [ ] Record whether the slow turn used streaming or standard request mode
- [ ] Record whether streaming fallback was used
- [ ] Record whether request time remained dominant after the local hot-path cuts already in the repo

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
- [ ] The result is explainable without guessing
- [ ] The insertion path does not impose a large unexplained fixed wait

## Failure Safety
- [ ] If setup is incomplete, the app shows a specific blocker
- [ ] If transcription fails, the app shows a clear error instead of silently doing nothing
- [ ] If insertion fails, the transcript remains available for manual recovery
- [ ] Dictated text is never lost silently
- [ ] Secure targets remain blocked
- [ ] Performance changes do not weaken wrong-target protections
- [ ] Logging changes do not store raw transcript text by default

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
- [ ] Short-phrase `release -> inserted` is usually under about `2-3s`
- [ ] `Codex` is not paying a large avoidable local delay compared with `TextEdit`
- [ ] The loop feels ambient enough for normal short dictation

## Minimum Usable Definition
- [ ] The installed app at `/Applications/HeadCanon.app` captures full short and multi-sentence utterances reliably
- [ ] The loop is reliable enough to repeat without guesswork
- [ ] The app reports readiness truthfully
- [ ] `TextEdit` remains solid while broader editor support is improved
- [ ] `Codex` is usable under the supported policy
- [ ] The app provides a clear recovery path when something fails
- [ ] A slow or failed turn can be explained from the local diagnostics log without screenshots

## Not Part Of This Checklist Yet
These are important, but they come after the current latency pass:

- offline backend validation
- signing stability across updates
- broader release hardening
- realtime transcription as the default path
