date: 2026-05-21
status: audit
owner: D-Bug
scope: stuck recording mode, no transcription start

# Root Cause Audit: Stuck Recording Before Transcription

## User-Visible Failure
The user reports that the bottom-right recording UI stays in recording mode after releasing the hotkey, and transcription never starts.

This is not the same failure as a slow or failed OpenAI transcription request. In the stuck case, the app appears to remain before transcription request start.

## Evidence Collected
- Ran the Latency snapshot helper:
  - `Latency/bin/capture_latency_snapshot.sh stuck-recording-audit`
  - output artifact: `Latency/artifacts/benchmark-2026-05-21T19-17-48-0700-stuck-recording-audit.md`
- Latest persisted diagnostic attempt is still:
  - completed at `2026-05-21 19:09:05 -0700`
  - terminal state `inserted`
  - request mode `Standard Completed Recording`
  - request -> response `1804 ms`
  - stop trigger `globalModifierMonitor`
- No persisted attempt exists after the user's later stuck-recording report.
- Installed app process under test:
  - path `/Applications/HeadCanon.app/Contents/MacOS/HeadCanon`
  - pid `9022`
  - started `2026-05-21 19:14:28 -0700`
  - CDHash `9f2e2959cad55231bfd62e992f04c5e99b752253`
- A leftover recording file exists after the current app launch:
  - `/private/var/folders/7f/5zt87nls393b3bglyz_m50t80000gn/T/HeadCanon/Recordings/head-canon-9F1D23B2-491C-4F4D-9590-ECA2E7302E05.m4a`
  - modified `2026-05-21 19:15:37 -0700`
  - size `36383` bytes
  - playable according to `afinfo`
  - estimated duration `0.424 s`
- `lsof` did not show that file open by `HeadCanon` at audit time.
- The default hotkey preference is not explicitly stored, so the app resolves to `Hold Control + Option`.
- A screenshot crop of the live overlay showed the red `mic.fill` recording state, not the orange finalizing state.
- `CGEventSource.flagsState(.combinedSessionState)` reported no Command, Control, Option, Shift, or Space key pressed while the overlay remained visible.
- Repeated `stat` checks showed the orphan `.m4a` was not growing.
- macOS unified logs showed CoreAudio/CMIO teardown for `HeadCanon` at `2026-05-21 19:15:37 -0700`, exactly matching the orphan file timestamp.

## What The Current Diagnostics Can Explain
The current persisted diagnostics are good for completed attempts:
- hotkey press/release timestamp
- recording start/finalized timestamp
- transcription request/response timing
- insertion timing and route
- backend metadata
- failure class after an attempt persists

The current diagnostics cannot explain an attempt that never reaches persistence.

If the app gets stuck while recording or finalizing, `Scripts/diagnostics.swift latest` still reports the previous completed attempt. That made several prior reads misleading.

## Current State Machine Trace
The active path is:

1. `HotkeyManager` observes press.
2. `HeadCanonModel.handleHotkeyPressed()` starts `AudioCaptureService`.
3. `workflowStatus` becomes `.recording`.
4. Overlay shows recording.
5. Release should call `HeadCanonModel.handleHotkeyReleased()`.
6. `workflowStatus` becomes `.finalizingRecording`.
7. `AudioCaptureService.stopRecording()` waits for `AVCaptureFileOutputRecordingDelegate`.
8. On delegate completion, transcription starts.
9. Only after terminal success/failure is an attempt persisted.

Stuck recording can occur if any of these fail:
- the release callback is never delivered
- the model-level release watchdog never fires
- the watchdog sees the hotkey as still physically pressed forever
- `handleHotkeyReleased()` runs but `stopRecording()` never resumes
- the overlay remains visible from stale UI state even after recording stopped
- an error path exits without clearing overlay/status or persisting live-state evidence

## Strongest Root-Cause Hypotheses
1. **Audio capture can end outside the model's normal stop path, leaving workflow status stuck at `.recording`.**
   - Evidence: the visible overlay is red recording, but no recording file is open or growing.
   - Evidence: macOS logs show audio graph teardown at the orphan `.m4a` timestamp.
   - Evidence: the physical hotkey state is not pressed, so the watchdog should have finalized if it still considered audio active.
   - Code path: `AudioCaptureService.handleRecordingFinished()` can clean up capture state when `pendingStopContinuation == nil`, but the model has no callback to leave `.recording`.
   - Code path: the model release watchdog exits silently if `audioCaptureService.isRecording == false` while `workflowStatus == .recording`.

2. **Diagnostics blind spot is masking the real failure stage.**
   - Evidence: no persisted attempt after the stuck report.
   - Impact: terminal diagnostics can falsely suggest transcription is healthy while the live app is stuck before transcription.

3. **Real AVFoundation finalization and unexpected capture completion are under-tested.**
   - Evidence: tests use `StubAudioCaptureService.stopRecording()` that returns immediately.
   - Evidence: there is a leftover playable `.m4a` with no persisted attempt.
   - Risk: `AVCaptureAudioFileOutput` may finish before the model has called `stopRecording()`, producing a file but never advancing the model state.

4. **Modifier-hold hotkey delivery remains fragile, but it is no longer the sole lead.**
   - Evidence: successful persisted attempts use `globalModifierMonitor`.
   - Evidence: failures that never persist cannot tell us whether release was missed.
   - Counter-evidence: live `CGEventSource` state reported no modifier keys pressed while the overlay stayed recording.
   - Risk: `Hold Control + Option` depends on flags-changed delivery and inferred physical state.

5. **Overlay lifecycle is too tightly coupled to in-memory workflow status.**
   - Evidence: overlay has no independent stale-state timeout or live-state reconciliation.
   - Risk: even if audio stopped, a stale `.recording` workflow or panel root view can keep user-facing UI stuck.

6. **There is no user escape hatch.**
   - Evidence: once stuck in `.recording`, new hotkey presses are ignored by `workflowStatus.blocksNewDictation`.
   - Impact: user cannot force finalize/cancel from the UI without relaunching.

## Audit Of Recent Patches
Recent patches improved pieces but did not solve the observability root:
- standard completed-recording transcription fixed the streaming-preflight timeout class
- app-level release watchdog reduced dependence on hotkey manager callbacks
- hard recording duration fuse reduced indefinite recording risk

But these changes still lack:
- a persisted live-state file
- live-state CLI output
- explicit finalization timeout diagnostics
- a test where `stopRecording()` never resumes
- a manual cancel/finalize control

## Recommended Root Fix Plan
Do not add more behavioral patches until Phase 1 is complete.

### Phase 1: Add Live-State Observability
Add a small local `live-state.json` or equivalent under the diagnostics directory, updated on every state transition:
- app launch
- hotkey press observed
- recording start requested
- recording started
- release observed
- release watchdog poll state
- finalizing started
- `stopRecording()` called
- recording delegate completed
- transcription request started
- terminal persisted attempt

Add `Scripts/diagnostics.swift live` to print this state.

This should include no raw transcript and no raw audio.

### Phase 2: Add A User Escape Hatch
Add a menu/settings action for:
- `Cancel Recording`
- optionally `Finalize Recording Now`

This must work when `workflowStatus == .recording` or `.finalizingRecording`.

### Phase 3: Test Real Failure Shapes
Add tests with fake audio services that:
- start recording and never deliver release
- report `isRecording == false` while the model still thinks workflow status is `.recording`
- simulate capture finishing before `stopRecording()` is called
- `stopRecording()` never resumes
- `stopRecording()` throws
- cancel happens while finalization is pending

Current tests do not cover these shapes well enough.

### Phase 4: Make Audio Lifecycle Model-Owned
After live-state instrumentation confirms the sequence, add an explicit audio lifecycle callback or state reconciliation path:
- if audio capture finishes unexpectedly, transition out of `.recording`
- persist an abandoned/interrupted attempt record
- clear the overlay and surface an actionable failure
- keep any usable recording either finalized into transcription or discarded with an explicit reason

This is the highest-confidence behavior fix suggested by the current audit.

### Phase 5: Split Hotkey Modes In A Controlled Test
Compare:
- `Hold Control + Option`
- `Control + Option + Space`

Run a small installed-app matrix and record stop triggers. If `Control + Option + Space` is more reliable, promote it as the default while keeping modifier-hold as experimental.

### Phase 6: Only Then Patch Remaining Behavior
Likely behavior changes after evidence:
- timeout around recording finalization
- durable attempt record for abandoned/incomplete attempts
- stronger state machine ownership for recording lifecycle
- stale overlay self-dismiss only when safe and paired with recovery/cancel

## Immediate Next Diagnostic Question
When the UI gets stuck, run:

```bash
find /private/var/folders -path '*HeadCanon*Recordings*' -type f -ls 2>/dev/null | tail -n 20
lsof -p $(pgrep -x HeadCanon) | rg 'HeadCanon|Recordings|m4a|Audio' || true
stat -f '%Sm %z %N' -t '%Y-%m-%d %H:%M:%S' "$HOME/Library/Application Support/HeadCanon/diagnostics/latest.json"
```

If a new `.m4a` exists without a new `latest.json`, the failure is before attempt persistence.

## Current Conclusion
The root problem is not currently OpenAI transcription. The strongest evidence points to `AudioCaptureService` ending capture outside the release-driven stop path while `HeadCanonModel.workflowStatus` remains `.recording`. The next correct move is live-state instrumentation plus audio-lifecycle reconciliation and a recovery control, not another speculative hotkey patch.
