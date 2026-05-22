# D-Bug Checkpoints

## 2026-05-21
- Audited the repo and existing agent folders.
- Confirmed `swift test` passes locally.
- Confirmed installed-app diagnostics currently show insertion-stage failures as the dominant live issue.
- Confirmed additional planner and tooling drift:
  - app-only opaque routes can be planned before real focused-target evidence exists
  - strong AX opaque editors are intentionally kept off direct insertion
  - the focused-target analyzer script is more optimistic than runtime behavior
  - current planner tests encode some of the paste-oriented routing now under suspicion
- Implemented first-pass runtime fixes:
  - app-level paste no longer self-blocks purely because AX focus metadata is unavailable
  - offline and DNS transcription failures now fail fast instead of retrying
  - runtime and analyzer strategy descriptions were updated to match the new app-level paste behavior
- Re-ran `swift test`; all `77` tests passed on 2026-05-21.
- Captured a fresh installed-app baseline artifact in [installed-app-baseline-2026-05-21.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/artifacts/installed-app-baseline-2026-05-21.md).
- Aligned app-only context modeling so known opaque apps no longer claim a focused editable field when none was actually observed.
- Fixed the diagnostics summary helper to recognize `nativeAXStrong` correctly.
- Added focused equivalence hardening for known opaque text targets:
  - stable DOM or AX identifiers still preserve identity
  - conflicting stable identifiers still block equivalence
  - weak text-target fallback only applies when the app is classified as an opaque editor
- Added regression tests for focus identity churn and weak-equivalence boundaries.
- Installed the updated signed app bundle to `/Applications/HeadCanon.app`.
- Verified the installed bundle is signed by `HeadCanon Local Signing` with timestamp `2026-05-21 17:36:30 -0700`.
- After user reported transcripts appeared in the interface but not consistently in text boxes, diagnosed app-level paste as a likely false-positive path:
  - `appClipboardPaste` had no AX readback when app-only context was used
  - paste was sent with `postToPid`
  - clipboard restoration happened after only `120 ms`
- Updated app-level paste to:
  - send Cmd+V through the frontmost HID event tap while the target app remains frontmost
  - keep the clipboard injected for `450 ms` before restoration on true app-level paste
- Re-ran `swift test`; all `82` tests passed on 2026-05-21.
- Reinstalled the updated signed app bundle to `/Applications/HeadCanon.app`.
- Verified the installed bundle is signed by `HeadCanon Local Signing` with timestamp `2026-05-21 17:42:01 -0700`.

Audit:
- Repo health is better than app health.
- The installed app appears to be failing mainly after successful transcription, especially in `Codex`.
- The next pass must change routing behavior and tests together, or the suite will preserve the regression.
- The codebase now reflects the first safety-preserving runtime fix, but installed-app validation in `Codex` is still outstanding.
- Runtime and repo-local tooling are closer together now, but the remaining uncertainty is still real installed-app behavior after the new app-only paste change.
- Automated verification is complete through unit tests, diagnostics tooling, signing inspection, and installation.
- A fresh spoken `Codex` dictation turn still requires interactive input; no post-install attempt has been recorded yet.
- The most important next signal is whether the new frontmost paste plus longer clipboard hold makes the transcript land in the real text box, not merely whether diagnostics reports `inserted`.

Next steps:
- run a post-install `Codex` dictation turn and compare the resulting diagnostics against the saved baseline
- if insertion still fails, classify whether it is paste dispatch, paste verification, or a genuine focus change

## 2026-05-21 18:06 -0700
- User reported transcription was no longer working at all.
- Audited installed-app diagnostics:
  - latest two attempts timed out in `transcription`
  - both stopped at the app-level 30-second timeout
  - previous successful attempts used `Standard Completed Recording` with streaming fallback metadata
- Identified the active risk in `OpenAIBoundedTranscriptionBackend`:
  - bounded dictation attempted streaming first
  - fallback to standard transcription only ran when streaming failed quickly
  - a hanging streaming preflight consumed the app timeout before fallback could execute
- Changed bounded transcription to call standard completed-recording transcription directly.
- Added a regression test that captures the outbound request and asserts:
  - one request is sent
  - `Accept` is `text/plain`
  - multipart body omits `stream`
  - metadata reports `Standard Completed Recording`
  - `fellBackFromStreaming` is false
- Re-ran `swift test`; all `83` tests passed.
- Built and signed a fresh distribution bundle.
- `install_app.sh` still failed only at local Gatekeeper assessment for the self-signed bundle.
- Installed the fresh signed bundle with `install_dist_app.sh`.
- Verified `/Applications/HeadCanon.app`:
  - authority `HeadCanon Local Signing`
  - timestamp `2026-05-21 18:05:57 -0700`
  - CDHash `0f1d3a9564ee20de0e80b17c0a4014086b94efd4`
  - running process started at `2026-05-21 18:06:01 -0700`

Audit:
- This addresses the immediate transcription outage without changing the insertion route.
- The fix aligns runtime behavior with the documented current checkpoint: bounded dictation should use standard completed-recording transcription.
- Streaming helper code remains present but is no longer on the active bounded dictation path.
- The remaining live risk is now back to `Codex` text-box insertion consistency after transcription succeeds.

Next steps:
- Run a fresh installed-app dictation attempt in `Codex`.
- If transcription succeeds but text still does not land in the text box, continue with paste verification and app-level insertion diagnostics.

## 2026-05-21 18:33 -0700
- User reported the recording UI was stuck in the bottom-right corner while not intentionally recording, and transcription appeared completely broken.
- Reviewed latest diagnostics:
  - post-standard-mode attempts were succeeding again
  - latest completed attempt used `Standard Completed Recording`
  - latest request completed in `847 ms`
  - no newer completed failed attempt was persisted after the stuck-HUD screenshot
- Diagnosed the live failure as a likely stuck `recording` workflow state:
  - if modifier-hold release is missed, the app keeps recording
  - `workflowStatus.blocksNewDictation` then ignores future presses
  - no transcription request is started, making transcription appear dead
- Implemented hotkey hardening:
  - modifier-hold shortcuts now start a watchdog while pressed
  - the watchdog polls the real combined-session modifier state every `100 ms`
  - if the required modifiers are no longer down, it synthesizes a release with source `Modifier State Watchdog`
- Implemented model-level safety:
  - recordings now have a default `90 s` maximum duration
  - if the app is still recording after the limit, it finalizes automatically with source `Recording Duration Limit`
  - leaving the `recording` state cancels the duration-limit task
- Preserved transcription cancellation behavior:
  - standard transcription still maps URLSession cancellation to `CancellationError`
  - cancellation test waits briefly for URLProtocol stop propagation instead of assuming same-tick delivery
- Added regression coverage:
  - missed-release recording safety limit finalizes, transcribes, inserts, and clears `isRecording`
  - cancellation of bounded transcription still cancels the in-flight URLSession task
- Re-ran `swift test`; all `85` tests passed.
- Built and signed a fresh app bundle.
- `install_app.sh` again failed only at self-signed Gatekeeper assessment.
- Installed the fresh signed bundle with `install_dist_app.sh`.
- Verified `/Applications/HeadCanon.app`:
  - authority `HeadCanon Local Signing`
  - timestamp `2026-05-21 18:32:47 -0700`
  - CDHash `9371d2899705c39bf2fbaab14c1bbb65249205cf`
  - running process started at `2026-05-21 18:32:56 -0700`

Audit:
- The stuck-HUD failure should no longer permanently block transcription after a missed release.
- The immediate recording UI was cleared by replacing the running app process during install.
- Standard transcription is still the active bounded path.
- Remaining live risk is text insertion reliability in Codex after transcription succeeds.

Next steps:
- Run one fresh Codex dictation attempt against the installed app.
- If HUD clears and diagnostics show `inserted` but text does not appear, continue with insertion verification and Codex paste delivery.
- If HUD sticks again, inspect whether the stop trigger was `Modifier State Watchdog`, `Recording Duration Limit`, or missing entirely.

## 2026-05-21 19:14 -0700
- User reported the UI still gets stuck in recording mode and releasing the hotkey does not start transcription.
- Checked diagnostics:
  - latest persisted attempt still showed successful standard transcription and insertion at `19:09:05`
  - no new failed transcription record was persisted for the stuck live state
  - this reinforced that the app was stuck before recording finalization, not in the transcription backend
- Implemented a stronger app-model release watchdog:
  - `HotkeyShortcut` can now read whether its configured shortcut is physically pressed in the current session
  - supports modifier-hold and Control+Option+Space shortcut styles
  - `HeadCanonModel` starts a recording release watchdog after recording begins
  - after a short `150 ms` grace period, it polls every `75 ms`
  - if the configured hotkey is no longer down while the app is still recording, it finalizes with stop trigger `Recording Release Watchdog`
- Lowered the model-level hard recording duration fuse from `90 s` to `30 s`.
- Added regression coverage for the new model-level release watchdog:
  - simulates press without release callback
  - flips physical hotkey state to released
  - verifies recording finalizes, transcribes, inserts, clears `isRecording`, and records stop trigger `recordingReleaseWatchdog`
- Re-ran `swift test`; all `87` tests passed.
- Built and signed a fresh app bundle.
- `install_app.sh` still failed only at self-signed Gatekeeper assessment.
- Installed the fresh signed bundle with `install_dist_app.sh`.
- Verified `/Applications/HeadCanon.app`:
  - authority `HeadCanon Local Signing`
  - timestamp `2026-05-21 19:14:22 -0700`
  - CDHash `9f2e2959cad55231bfd62e992f04c5e99b752253`
  - running process started at `2026-05-21 19:14:28 -0700`

Audit:
- Release-to-finalization no longer depends solely on the hotkey manager delivering a release callback.
- If the UI sticks again, the next suspect is physical key-state polling returning stale pressed state.
- The hard fuse remains as a privacy backstop but should no longer be the primary recovery path.

Next steps:
- Try one fresh dictation in Codex and check whether the stop trigger is a normal monitor release or `Recording Release Watchdog`.
- If it still sticks, add a visible manual cancel/finalize command and diagnostics for the live hotkey physical-state poll value.

## 2026-05-21 19:20 -0700
- User asked to stop patching and zoom out because recording still gets stuck and transcription never starts.
- Ran Latency tooling:
  - `Latency/bin/capture_latency_snapshot.sh stuck-recording-audit`
  - saved `Latency/artifacts/benchmark-2026-05-21T19-17-48-0700-stuck-recording-audit.md`
- Audited installed app and diagnostics:
  - app process `/Applications/HeadCanon.app/Contents/MacOS/HeadCanon`
  - pid `9022`
  - started `2026-05-21 19:14:28 -0700`
  - installed CDHash `9f2e2959cad55231bfd62e992f04c5e99b752253`
  - latest persisted attempt still completed at `2026-05-21 19:09:05 -0700`
  - latest persisted attempt was successful standard transcription and insertion
- Found evidence outside persisted attempts:
  - leftover `.m4a` under temp `HeadCanon/Recordings`
  - modified `2026-05-21 19:15:37 -0700`
  - playable via `afinfo`
  - duration about `0.424 s`
  - no matching persisted attempt
- Root conclusion:
  - the stuck-recording failure is currently before persisted-attempt diagnostics
  - `Scripts/diagnostics.swift latest` is misleading for this class because it reports the previous terminal attempt
  - strongest suspect is recording lifecycle/finalization/live-state observability, not OpenAI transcription
- Saved root-cause audit:
  - `D-Bug/artifacts/root-cause-audit-2026-05-21-stuck-recording.md`

Audit:
- Previous hotkey/watchdog patches were plausible but insufficiently instrumented.
- The repo needs live-state diagnostics before more behavior patches.
- Tests use instant audio stubs and do not reproduce real `AVCaptureAudioFileOutput` finalization hangs.

Next steps:
- Add live-state diagnostics and `Scripts/diagnostics.swift live`.
- Add visible `Cancel Recording` / `Finalize Recording Now` recovery.
- Add tests for pending/hung `stopRecording()` and stuck pre-persistence states.
- Then decide whether the root fix is hotkey mode, recording finalization timeout, or state-machine ownership.

## 2026-05-21 19:28 -0700
- Continued the whole-repo audit without changing product behavior.
- Captured the live overlay and confirmed it is Head Canon's red recording HUD (`mic.fill`), not the finalizing or transcribing HUD.
- Checked physical key state with `CGEventSource.flagsState(.combinedSessionState)`; Control, Option, Command, Shift, and Space all reported released.
- Repeated `stat` checks showed the orphan `.m4a` from `19:15:37` was static at `36383` bytes.
- `lsof` showed no open `.m4a` for `HeadCanon`, which argues against an actually active file recording.
- macOS unified logs showed CoreAudio/CMIO teardown for the Head Canon microphone graph at `19:15:37`, exactly matching the orphan recording timestamp.

Audit:
- The strongest current root cause is a state-machine split:
  - audio capture ended or was torn down
  - `HeadCanonModel.workflowStatus` stayed `.recording`
  - release/watchdog paths did not repair the state
  - persisted diagnostics stayed pointed at the previous successful attempt

- This explains why transcription never starts: the app never reaches the release/finalization/transcription pipeline.

Next steps:
- Add live-state diagnostics so a stuck in-progress attempt is visible without relying on terminal `latest.json`.
- Add audio lifecycle reconciliation between `AudioCaptureService` and `HeadCanonModel` for unexpected capture completion.
- Add tests for capture finishing before `stopRecording()`, `isRecording` dropping while workflow remains `.recording`, and `stopRecording()` never resuming.
- Add a manual Cancel/Finalize escape hatch after instrumentation proves the state transitions.

## 2026-05-21 19:34 -0700
- User confirmed the red recording HUD was still stuck on screen.
- Captured final live evidence before changing behavior:
  - Head Canon process was still pid `9022`, launched `19:14:28`
  - AX still showed the `44x44` bottom-right overlay plus Settings
  - `CGEventSource` reported no Control, Option, Command, Shift, or Space press
  - only the static orphan `.m4a` from `19:15:37` remained
- Implemented audio lifecycle reconciliation:
  - `AudioCapturing` now has an unexpected-completion callback
  - `AudioCaptureService` reports delegate completion when no `stopRecording()` continuation is pending
  - successful unexpected completion is handed to `HeadCanonModel` as a finalized `BoundedAudioInput`
  - failed unexpected completion clears the stale recording state and persists a recording-stop failure
- Implemented stale recording-state cleanup:
  - the model recording release watchdog no longer exits silently when `audioCaptureService.isRecording == false`
  - it fails the current attempt, clears `.recording`, and dismisses the HUD instead of leaving the user stuck
- Added regression coverage:
  - unexpected audio completion recovers and starts transcription
  - watchdog clears stale recording state when audio has already stopped
- Ran `swift test`; all `90` tests passed.
- Built, signed, installed, and launched the fresh app:
  - installed path `/Applications/HeadCanon.app`
  - pid `28695`
  - CDHash `c4493975a71a345c6cf230f45c07d75bc69cf4df`
  - timestamp `2026-05-21 19:33:52 -0700`
- Verified the stuck HUD cleared after install:
  - AX now shows only `Head Canon Settings`
  - no temp `HeadCanon/Recordings` files remain

Audit:
- This is the first fix that directly targets the observed root split: audio ended but model stayed `.recording`.
- The app now has two recovery paths for that split:
  - continue with the finalized clip when AVFoundation produced one
  - fail cleanly and clear HUD when audio is already stopped without a usable completion
- The current installed app is ready for one fresh dictation attempt.

Next steps:
- Test a fresh short dictation in Codex.
- If it succeeds, check whether insertion lands in the text box and whether diagnostics persist the current attempt.
- If it fails or sticks, inspect current diagnostics for `recordingStop` failure, unexpected-completion recovery, or insertion failure.

## 2026-05-21 19:40 -0700
- Continued from the audio-lifecycle root fix into observability and user recovery.
- Added privacy-safe live diagnostics:
  - new `LiveDiagnosticsRecord`
  - `DiagnosticsStore.persistLiveState(_:)`
  - persisted file: `~/Library/Application Support/HeadCanon/diagnostics/live-state.json`
  - includes workflow status, current attempt ID, audio capture recording flag, hotkey physical state, active transcription ID, last failure/truth state, recent events, and timing stamps
  - does not include raw audio or transcript text
- Added `Scripts/diagnostics.swift live`.
- Added menu/settings recovery controls:
  - `Finalize Recording Now`
  - `Cancel Current Dictation`
- Added model methods:
  - `finalizeCurrentRecordingNow()`
  - `cancelCurrentDictation()`
  - `canFinalizeCurrentRecording`
  - `canCancelCurrentDictation`
- Added tests:
  - live diagnostics capture an in-progress recording state
  - manual finalize completes an active recording
  - manual cancel clears an active recording
- Ran `swift test`; all `93` tests passed.
- Built, signed, installed, and launched the fresh app:
  - installed path `/Applications/HeadCanon.app`
  - pid `31873`
  - CDHash `77604e4317dc70fa061f0aa1e3e2de747dca700c`
  - timestamp `2026-05-21 19:39:43 -0700`
- Verified current live state:
  - `Scripts/diagnostics.swift live` reports `Workflow: Ready (ready)`
  - `Audio Capture Recording: No`
  - `Hotkey Physically Pressed: No`
  - latest event: `Registered hotkey: Hold Control + Option`
  - AX shows only `Head Canon Settings`, no bottom-right HUD window

Audit:
- This closes the major diagnostic blind spot found in the zoom-out audit: a stuck in-progress attempt now has a live state file.
- The app also now has an explicit user escape hatch if the HUD or workflow state gets wedged again.
- Remaining live risk is actual post-install dictation behavior in Codex: recording should no longer stick, but insertion still needs a fresh observed attempt.

Next steps:
- Run one fresh short Codex dictation.
- If it fails, immediately run `Scripts/diagnostics.swift live` and `Scripts/diagnostics.swift latest`.
- Use `live` to diagnose current stuck states and `latest` for completed/failed terminal attempts.
- Updated `Latency/bin/capture_latency_snapshot.sh` so latency snapshots include `Scripts/diagnostics.swift live`.
- Verified the updated Latency helper:
  - saved `Latency/artifacts/benchmark-2026-05-21T19-41-14-0700-live-state-postfix.md`

## 2026-05-21 19:45 -0700
- Did a public reference pass on Wispr Flow docs to compare reliability patterns, not to clone product behavior.
- Saved notes:
  - `D-Bug/artifacts/wispr-flow-reference-2026-05-21.md`
- Useful patterns confirmed:
  - separate transcription failure from insertion failure
  - expose paste/copy last transcript recovery
  - document stuck listening/no-audio as a distinct failure mode
  - treat hotkey drops/delays as their own class
  - test app-specific insertion behavior instead of assuming one universal paste path

Audit:
- Head Canon is now aligned with the important reliability themes:
  - live-state diagnostics for stuck states
  - terminal attempt diagnostics for completed attempts
  - explicit cancel/finalize controls
  - paste-last-transcript recovery
  - insertion verification/truth states

Next steps:
- Add a visible `Copy Last Transcript` button if user testing shows paste recovery is not enough.
- Run the app/text-box matrix with `Scripts/diagnostics.swift live` captured immediately after any stuck or failed state.

## 2026-05-21 19:48 -0700
- User asked to zoom out and audit the issues again.
- Re-inventoried the installed app:
  - pid `31873`
  - CDHash `77604e4317dc70fa061f0aa1e3e2de747dca700c`
  - signed by `HeadCanon Local Signing`
- Ran current diagnostics:
  - `Scripts/diagnostics.swift live`
  - `Scripts/diagnostics.swift latest`
  - `Scripts/diagnostics.swift recent 12`
  - `Scripts/diagnostics.swift summary 30`
  - `Scripts/diagnostics.swift summary-by-failure 50`
  - `Scripts/diagnostics.swift summary-by-app-class 50`
- Key observation:
  - current recording/transcription loop completed
  - latest attempt was `inserted`
  - truth state was `unverifiedInsert`
  - app was `Codex`
  - strategy was `appClipboardPaste`
  - verification was `unverified`
- Verified the visible overlay dismissed normally after its inserted-state timeout.
- Ran `swift test`; all `93` tests passed.
- Saved zoom-out audit:
  - `D-Bug/artifacts/zoom-out-audit-2026-05-21.md`

Audit:
- The previous stuck-recording class is not currently active in diagnostics.
- The current highest-risk active issue is Codex insertion proof/reliability.
- App-only Codex records have `target: Unknown`, `valueReadable: false`, and `selectedTextRangeReadable: false`, so the app cannot distinguish successful paste from no-op paste.
- Live diagnostics also exposed a smaller diagnostic issue: `activeTranscriptionAttemptID` can still appear in live state immediately after `workflowStatus == inserted`.

Next steps:
- Clear `activeTranscriptionAttemptID` before terminal workflow live-state persistence, or persist live state again after the defer clears it.
- Add visible `Copy Last Transcript` recovery for `unverifiedInsert`.
- Strengthen `appClipboardPaste` diagnostics with explicit reason for unverifiability.
- Run the text-box matrix before inventing a Codex-specific insertion path.

## 2026-05-22 06:39 -0700
- User reported a repeated-use failure: after about 10 transcriptions, recording/transcription stops working.
- Ran live diagnostics, recent attempt history, failure/model/app summaries, Latency snapshot tooling, `lsof`, codesign inspection, and macOS unified logs.
- Captured new Latency artifact:
  - [benchmark-2026-05-22T06-30-02-0700-transcription-fatigue-audit.md](/Users/worldbuilder/Desktop/Head%20Canon/Latency/artifacts/benchmark-2026-05-22T06-30-02-0700-transcription-fatigue-audit.md)
- Saved root-cause audit:
  - [transcription-fatigue-audit-2026-05-22.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/artifacts/transcription-fatigue-audit-2026-05-22.md)
- Root finding:
  - audio capture was not stuck during the final failure
  - finalized clip metadata existed
  - transcription requests timed out at the app-level 30 second guard
  - CFNetwork reused a stale QUIC connection that later reported blackhole detection and operation timeouts
- Implemented the highest-confidence fix:
  - standard bounded transcription now creates and invalidates a fresh URLSession per transcription request
  - transcription session config disables URL cache and limits per-host connection count
  - late non-recording hotkey releases no longer corrupt the previous attempt timing
  - live diagnostics writes are serialized to reduce stale live-state races
- Verification:
  - `swift test` passed with `94` tests
  - built and signed `dist/HeadCanon.app`
  - installed `/Applications/HeadCanon.app`
  - installed CDHash: `649008ef7d45f7182ba4171cfef3d823caa36c9b`
  - post-install live diagnostics show `Workflow: Ready`, `Audio Capture Recording: No`, and `Active Transcription: None`
  - fresh post-install dictation attempts at `6:39 AM` and `6:40 AM` completed transcription and reached `unverifiedInsert`; latest request completed in `2594 ms`
  - follow-up snapshot saved at [benchmark-2026-05-22T06-40-34-0700-post-cleanup-live-check.md](/Users/worldbuilder/Desktop/Head%20Canon/Latency/artifacts/benchmark-2026-05-22T06-40-34-0700-post-cleanup-live-check.md)
  - continued audit through `6:45 AM` found `11` post-install completed attempts, `0` failures, request p50 `1647 ms`, request p95 `3524 ms`
  - CFNetwork logs for pid `16531` showed fresh per-request connections and cleanup after success; no post-fix blackhole or operation-timeout entries were found in the checked window
  - longer snapshot saved at [benchmark-2026-05-22T06-45-33-0700-post-fix-11-turn-audit.md](/Users/worldbuilder/Desktop/Head%20Canon/Latency/artifacts/benchmark-2026-05-22T06-45-33-0700-post-fix-11-turn-audit.md)

Audit:
- This fix matches the observed system logs and avoids adding more hotkey/audio patches to a transport failure.
- The first attempted delegate-based standard request path caused the cancellation test to hang; it was simplified before release to per-request `URLSession.data(for:)`.
- Unit coverage is green, but a real repeated-dictation soak test is still needed because CFNetwork fatigue is runtime/environmental.
- A first real post-fix soak is encouraging, but still short of a full long-run reliability pass.
- Codex insertion remains `unverifiedInsert`; that is now the main unresolved reliability class after transcription transport stabilized.
- There is a benign release-race cleanup item: the release watchdog can finalize first and the global release can arrive afterward as a noisy no-active-recording event.

Next steps:
- Extend the installed-app dictation soak to 20+ turns and watch `Scripts/diagnostics.swift recent 25`.
- If any transcription timeout remains, add one automatic retry after app-level timeout using a new per-request session before surfacing failure.
- Clean up duplicate release event logging so watchdog/global release races do not confuse future diagnostics.
- Continue the separate Codex insertion reliability track after transcription stability is confirmed.

## 2026-05-22 06:52 -0700
- User asked to fix all remaining audited issues.
- Implemented the actionable fixes from the current audit:
  - late duplicate hotkey releases after watchdog finalization now return silently instead of adding noisy `without an active recording` diagnostics
  - if workflow status is still `.recording` but audio is already stopped, hotkey release now clears the stale state through the stale-recording failure path
  - production maximum recording duration was raised from `30 s` to `90 s`
  - duration-limit diagnostic copy now states that auto-finalization prevents a stuck recording
  - unverified insertion detail now tells the user to use Paste or Copy Last Transcript if text is missing
  - menu bar UI now has `Copy Last Transcript`
  - Settings `Last Transcript` section now has Paste and Copy recovery actions plus explanatory copy
- Added regression tests:
  - late release after watchdog finalization does not add noisy diagnostics
  - user can copy retained transcript for manual recovery
- Verification:
  - `swift test` passed with `96` tests
  - built and signed `dist/HeadCanon.app`
  - installed `/Applications/HeadCanon.app`
  - installed CDHash: `3e70db92db7c71430e8da0258afae235bb4e7c0e`
  - post-install live diagnostics show `Workflow: Ready`, `Audio Capture Recording: No`, and `Active Transcription: None`

Audit:
- The duplicate release race is fixed at the diagnostic-noise layer.
- The duration fuse is less likely to interrupt normal long dictation, while still protecting against indefinite recording.
- Opaque Codex insertion cannot be honestly upgraded from `unverifiedInsert` without readable AX contents or app-specific integration; the current fix makes recovery explicit and one-click.

Next steps:
- Run another real Codex dictation turn and confirm the menu/settings recovery actions are visible when a transcript is retained.
- Continue a 20+ turn soak for transcription stability.
- If user needs true verified insertion in Codex, investigate a Codex-specific integration or a target-side accessibility/readback surface.

## 2026-05-22 06:59 -0700
- User asked to fix all issues after the latest audit pass.
- Implemented a root-level release hardening fix:
  - `HotkeyShortcut.isPressedInCurrentSession()` now checks both `.combinedSessionState` and `.hidSystemState`
  - `HotkeyManager`'s modifier release watchdog now treats the shortcut as released when either state source no longer matches the required modifiers
  - this prevents a stale combined-session modifier flag from keeping the app in recording until the long duration fuse
- Cleaned up diagnostic test hygiene:
  - direct unit-test model constructors now use `NoOpDiagnosticsStore()`
  - `swift test` no longer overwrites the installed app's live diagnostics file
- Verification:
  - `swift test` passed with `96` tests
  - built and signed `dist/HeadCanon.app`
  - installed `/Applications/HeadCanon.app`
  - installed CDHash: `fb25c48192f833e09ace95f558f89864dc78bbf9`
  - post-install live diagnostics showed the installed app at `/Applications/HeadCanon.app`
  - fresh real dictation at `6:58 AM` finalized via `Global Modifier Monitor`, transcribed successfully, inserted as `unverifiedInsert`, and ended with `Audio Capture Recording: No` and `Active Transcription: None`

Audit:
- The previously observed stuck-recording path now has three independent exits: normal release callback, dual-source physical-state watchdog, and duration fuse.
- The repeated-transcription timeout/fatigue path remains addressed by fresh per-request URLSessions and has not recurred in post-fix observed attempts.
- Codex remains `unverifiedInsert`, which is honest for an opaque target without AX-readable text contents.

Next steps:
- Continue the 20+ turn installed-app soak.
- If recording sticks again, compare `Hotkey Physically Pressed`, `Stop Trigger`, and recent events in `Scripts/diagnostics.swift live`.
- If insertion text is missing after `unverifiedInsert`, use `Paste Last Transcript` or `Copy Last Transcript` while we investigate Codex-specific verification/readback options.

## 2026-05-22 07:03 -0700
- Audited the lone recent `transcriptionFailed` record at `6:55 AM`.
- Finding:
  - recording and release were healthy
  - OpenAI returned HTTP `200`
  - response headers arrived in `975 ms`
  - body parsing produced empty text
  - the failure was therefore an empty transcription response, not audio/hotkey/transport fatigue
- Implemented:
  - retry once for empty `200 OK` `text/plain` transcription responses
  - clearer invalid-response copy: "empty or could not be decoded"
  - regression test for empty-response retry
- Verification:
  - `swift test` passed with `97` tests
  - built and signed `dist/HeadCanon.app`
  - installed `/Applications/HeadCanon.app`
  - installed CDHash: `1022e255cdb3a6deddca5a2ac0a62111f29cbebd`
  - post-install live diagnostics show `Workflow: Ready`, `Audio Capture Recording: No`, `Hotkey Physically Pressed: No`, and `Active Transcription: None`

Audit:
- The final installed app now addresses the observed stuck-recording class, stale transport class, empty transcription response class, and recovery/diagnostics clarity issues from this audit thread.
- Remaining issue is not currently a transcription blocker: Codex insertion is still `unverifiedInsert` because the target does not expose reliable AX readback.

Next steps:
- Use the app normally and continue the soak; new failures should be classified by truth state rather than lumped together as "transcription not working."
- If another transcription failure appears, inspect whether it is `transcriptionTimedOut`, `transcriptionTransportFailure`, or `transcriptionFailed` with HTTP `200`.
