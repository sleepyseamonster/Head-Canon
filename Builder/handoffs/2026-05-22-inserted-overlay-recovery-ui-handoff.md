# Builder Handoff: Inserted Overlay Re-Entry And Recovery Transcript UI Regression

Date: 2026-05-22 19:50 MST  
From: D-Bug  
To: Builder  
Repo: `/Users/worldbuilder/Desktop/Head Canon`  
Runtime target: `/Applications/HeadCanon.app`  
Branch expectation: `main`

## Executive Summary

The user's latest theory is plausible: a new hotkey press appears to have been accepted while Head Canon was still showing the green `Inserted` checkmark/status. One failed attempt at 19:37:20 has an abnormal `pressToRecordingStartDurationMS` of `11046 ms`, then produced an 11.1 second clip that was only `32772` bytes and received an OpenAI `400`. That is not the normal failure shape.

The current runtime is not stuck. Live diagnostics after the report showed `Workflow: Inserted`, `Audio Capture Recording: No`, `Hotkey Physically Pressed: No`, and continued successful `unverifiedInsert` attempts. The issue to harden is re-entry/state timing after `Inserted`, not a continuously stuck recorder.

There is also a real recovery UI regression risk. The source still has "Recovery Transcript" panels and `Copy Last Transcript`, but the panels are conditional on `model.lastTranscript` being non-empty. If a transcription fails, the app relaunches, privacy retention is off, or `lastTranscript` is cleared, the large copyable text area disappears entirely. The UI should always show a "Last Transcript" recovery surface with an empty/off/available state so the user can trust where recovery will be.

## Current Runtime Facts

- Installed app path: `/Applications/HeadCanon.app`
- Installed bundle identifier: `local.headcanon.app`
- Installed runtime has disk readiness/reserve diagnostics.
- Live disk state during this audit: about `49.75 GB` free, disk readiness `Healthy`, reserve `Reserved`.
- Current branch during the audit: `main`.
- Recent successful Codex insertions are expected to be `unverifiedInsert`; the user accepted this limitation because Codex does not expose reliable AX text readback.

## Diagnostics Run

Commands used:

```sh
git status --short --branch
./Scripts/diagnostics.swift live
./Scripts/diagnostics.swift latest
./Scripts/diagnostics.swift recent 20
./Scripts/diagnostics.swift recent 60
./Scripts/diagnostics.swift summary 50
./Scripts/diagnostics.swift summary-by-failure 50
defaults read local.headcanon.app
```

The live state after the user-reported green-check observation:

- `Workflow: Inserted (inserted)`
- `Audio Capture Recording: No`
- `Hotkey Physically Pressed: No`
- `Last Truth State: unverifiedInsert`
- `Last Error: None`
- Last attempt completed at `19:41:50` with `162` chars from `16.90s`
- Stop trigger was `recordingReleaseWatchdog`

Recent 50-attempt summary:

- `Attempts: 50`
- `Unverified Inserts: 48`
- `Failures: 2`
- `Request -> Response p50: 2027 ms`
- `Request -> Response p95: 3425 ms`
- `Release -> Inserted p50: 2648 ms`
- `Release -> Inserted p95: 4077 ms`

## Issue A: Green Check / Inserted-State Re-Entry Timing

The strongest anomalous record is:

```text
Completed: 2026-05-23T02:37:20Z / 2026-05-22 19:37:20 MST
Attempt: 8D6DDB85-5AED-4624-8AC5-C23A68ECA999
Terminal state: failed
Truth state: transcriptionFailed
Failure: The transcription service returned status code 400.
HTTP status: 400
Request ID: req_4762eb71fc8c4813a6c3f6e76046c053
Clip duration: 11108 ms
Recorded file size: 32772 bytes
Hotkey pressed: 19:37:08
Recording started: 19:37:19
Hotkey released: 19:37:19
Press to recording start: 11046 ms
Stop trigger: globalModifierMonitor
```

Why this matters:

- Normal recent `pressToRecordingStartDurationMS` values are usually around `60-80 ms`.
- This attempt waited about `11 seconds` between observed hotkey press and recorded start.
- The file size is far too small for the reported duration compared with nearby successful clips.
- The OpenAI `400` is likely downstream of a bad/invalid audio capture, not the root cause.
- The attempt happened immediately after a successful `19:37:08` `unverifiedInsert`, matching the user's "green check still visible, then I pressed again" suspicion.

Likely root-shaped hypothesis:

Head Canon can accept a new hotkey edge while the workflow is still visually/semantically in the success overlay path. The state machine then records a hotkey press timestamp but audio does not actually begin promptly. When release is finally observed, the app finalizes a suspicious audio artifact and misclassifies the result as a transcription failure because the first terminal error is the provider `400`.

This should be treated as a re-entry/state-timing bug plus bad-audio classification gap, not a model/provider outage.

## Issue B: Empty 200 Transcription Responses Still Appear

Two recent failures were empty/undecodable `200 OK` transcription responses:

```text
2026-05-23T01:33:50Z
Failure: The transcription response was empty or could not be decoded.
HTTP: 200 text/plain
Transport failure stage: readingResponseBody
Clip: 3686 ms, 60017 bytes
Request ID: req_bc0ff4e3d73f4b6ebf54705df4de23fa
```

```text
2026-05-23T02:22:55Z
Failure: The transcription response was empty or could not be decoded.
HTTP: 200 text/plain
Transport failure stage: readingResponseBody
Clip: 2131 ms, 48373 bytes
Request ID: req_c5bd87b6532c47c6b9dbad8e3bd12461
```

Earlier work intended to add one retry for empty `200 OK` responses. Builder should verify whether the installed CDHash includes that retry and whether diagnostics preserve the final attempt only or the first failed try. If retry is present, the app should record `retryCount`, `firstFailure`, and `finalFailure` so D-Bug can tell whether the retry fired.

## Issue C: Recovery Transcript UI Regression

Source audit:

- `Sources/HeadCanon/UI/MenuBarContentView.swift` renders the recovery panel only inside:
  - `if let lastTranscript = model.lastTranscript, !lastTranscript.isEmpty`
- `Sources/HeadCanon/UI/SettingsRootView.swift` does the same.
- Both UIs use selectable `Text` in a `ScrollView`, not a real text-box-looking `TextEditor`.
- Buttons for `Paste Last Transcript`, `Copy Last Transcript`, and `Clear Last Transcript` still exist but are disabled when `lastTranscript` is empty.
- `HeadCanonModel.retainTranscriptIfAllowed(_:)` only keeps the transcript when `preferences.historyRetentionMode != .neverStore`.
- `defaults read local.headcanon.app` did not show `historyRetentionMode`, so default retention should be active unless changed in-app.

Why the user can experience this as "the text box disappeared":

- A failed transcription never calls `retainTranscriptIfAllowed`, so the panel may vanish or remain absent.
- A relaunch loses the in-memory `lastTranscript`.
- Privacy mode `.neverStore` clears it.
- The current UI hides the entire recovery surface instead of showing an empty/off state.
- The surface is not visually a text box; it is a scroll area with selectable text, so it can look absent or non-copyable.

This should be fixed as a UX reliability issue. The recovery area is part of the safety net and should be visible even when empty.

## Builder Implementation Plan

1. Harden new-dictation re-entry from `Inserted`.
   - Add an explicit transition path from `.inserted` to `.recording`.
   - Ensure the overlay updates immediately when a new recording starts.
   - Consider a short post-insert debounce, around `300-500 ms`, only if a press arrives while the green inserted overlay is still being dismissed.
   - Do not make the app feel sluggish; prefer "ignore clearly stale duplicate edge" over a broad delay.

2. Add recording-start latency guardrails.
   - Persist and surface a warning if `pressToRecordingStartDurationMS > 500 ms`.
   - Treat `pressToRecordingStartDurationMS > 1000 ms` as abnormal.
   - If audio start is delayed beyond the threshold, fail as `recordingFailed` or `recordingStartDelayed` before sending bad audio to transcription.
   - Add a diagnostic event like: `Recording start was delayed after hotkey press; canceled before transcription to avoid bad audio.`

3. Improve bad-audio classification before transcription.
   - Add a sanity check for file size versus duration after recording finalizes.
   - If the ratio is implausible, classify as recording/audio-capture failure, not transcription failure.
   - Preserve bytes, duration, selected microphone, stop trigger, and press-to-start timing in persisted diagnostics.

4. Preserve better OpenAI error diagnostics.
   - For non-2xx responses, persist response body bytes, trimmed body character count, and a redacted short body preview if safe.
   - For empty `200 OK`, persist retry count and whether the retry fired.
   - Do not log raw transcript or raw audio.

5. Restore a persistent recovery UI surface.
   - Always show "Last Transcript" in menu and Settings.
   - When available, show the transcript in a clearly copyable text-box-like surface.
   - When empty, show `No retained transcript yet`.
   - When privacy mode is `.neverStore`, show `Transcript retention is off`.
   - Keep `Copy`, `Paste`, and `Clear` visible; disable with explanatory text when unavailable.
   - Add an accessibility identifier if practical so this panel can be checked in UI diagnostics.

6. Add tests.
   - Test that `.inserted` does not block a legitimate next recording.
   - Test that delayed recording start is classified before transcription.
   - Test that suspicious file-size/duration audio fails as recording/audio, not transcription.
   - Test that last transcript retention remains nil in `.neverStore`.
   - Test that successful transcription stores `lastTranscript` before insertion.

## Files To Inspect First

- `Sources/HeadCanon/App/HeadCanonModel.swift`
- `Sources/HeadCanon/UI/StatusOverlayController.swift`
- `Sources/HeadCanon/UI/MenuBarContentView.swift`
- `Sources/HeadCanon/UI/SettingsRootView.swift`
- `Sources/HeadCanon/Audio/AudioCaptureService.swift`
- `Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift`
- `Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift`
- `Sources/HeadCanon/Diagnostics/LiveDiagnosticsRecord.swift`
- `Scripts/diagnostics.swift`
- `Tests/HeadCanonTests/HeadCanonTests.swift`

## Verification Checklist

Run source checks:

```sh
swift test
./Scripts/diagnostics.swift live
./Scripts/diagnostics.swift recent 20
./Scripts/diagnostics.swift summary 50
./Scripts/diagnostics.swift summary-by-failure 50
```

Manual repro:

1. Dictate a short phrase into Codex.
2. While the green inserted checkmark is still visible, press and hold the hotkey again.
3. Expected result: either the press is safely ignored as too soon with an explicit diagnostic, or the UI immediately transitions to recording and `pressToRecordingStartDurationMS` stays below `500 ms`.
4. Release the hotkey.
5. Expected result: no provider `400`, no tiny/invalid audio artifact, no stuck green check.

Recovery UI verification:

1. Complete one successful transcription.
2. Open Head Canon menu and Settings.
3. Confirm a "Last Transcript" recovery surface is visible and copyable.
4. Clear the transcript.
5. Confirm the recovery surface remains visible with an empty state.
6. Set retention to never store.
7. Confirm the surface explains retention is off.
8. Relaunch.
9. Confirm no stale transcript is shown unless explicit persistence is later added.

Runtime install verification, only if changing app code:

```sh
./Scripts/build_app_bundle.sh
./Scripts/install_dist_app.sh dist/HeadCanon.app
codesign -dv --verbose=4 /Applications/HeadCanon.app 2>&1 | awk -F= '/CDHash|Authority|Timestamp|Identifier/ {print}'
./Scripts/diagnostics.swift live
```

Only test `/Applications/HeadCanon.app`, not `dist/HeadCanon.app`.

## Non-Goals

- Do not change the transcription model/provider as part of this fix.
- Do not attempt to mark Codex insertions verified.
- Do not add realtime transcription.
- Do not persist raw audio.
- Do not silently persist transcripts across relaunch unless the user explicitly approves that privacy tradeoff.
- Do not auto-delete broad caches or user files.

## Work Prompt For Builder

You are Builder working in `/Users/worldbuilder/Desktop/Head Canon` on `main`. The user observed that pressing the hotkey while the green inserted checkmark was visible may have caused Head Canon to fail. Audit and harden the post-insert re-entry path. The key diagnostic anomaly is attempt `8D6DDB85-5AED-4624-8AC5-C23A68ECA999`, completed at `2026-05-23T02:37:20Z`: `pressToRecordingStartDurationMS` was `11046 ms`, the clip claimed `11108 ms` but was only `32772` bytes, and OpenAI returned `400`. Treat this as a recording/state-machine bug that leaks into transcription, not a provider outage. Add guardrails for delayed recording start and suspicious audio duration/size before transcription, improve diagnostics for empty `200 OK` retry behavior and non-2xx response bodies, and restore the Last Transcript recovery UI so it is always visible with available/empty/privacy-off states. Preserve the accepted Codex `unverifiedInsert` limitation. Verify with `swift test`, live diagnostics, and the manual green-check re-entry repro against `/Applications/HeadCanon.app`.
