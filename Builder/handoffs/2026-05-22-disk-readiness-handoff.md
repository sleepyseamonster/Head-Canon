# Builder Handoff: Disk-Space Readiness And Recording Failure Clarity

Date: 2026-05-22 09:00 MST  
From: D-Bug  
To: Builder  
Repo: `/Users/worldbuilder/Desktop/Head Canon`  
Runtime target: `/Applications/HeadCanon.app`

## Executive Summary

The user reported "transcription errors suddenly." Live diagnostics showed this was not a transcription outage. Head Canon was failing before transcription started because recording finalization returned `Disk Full`.

The machine's Data volume had dropped to roughly `635 MiB` free and `100%` capacity. After clearing only regenerable developer/package caches and repo build output, free space recovered to roughly `16 GiB`. The app still needs a product-level guardrail so this failure is obvious and actionable next time.

Your job is to implement disk-space readiness checks and diagnostics so low disk space is classified as a recording/system-readiness problem, not confused with transcription.

## Current Runtime Facts

- Installed app path: `/Applications/HeadCanon.app`
- Installed bundle identifier: `local.headcanon.app`
- Current installed CDHash from last D-Bug install: `1022e255cdb3a6deddca5a2ac0a62111f29cbebd`
- Current app uses `gpt-4o-mini-transcribe` via `Standard Completed Recording`.
- Current app has:
  - stuck-recording watchdogs
  - fresh per-request transcription sessions
  - one retry for empty `200 OK` transcription responses
  - `Paste Last Transcript` and `Copy Last Transcript`
  - live diagnostics via `Scripts/diagnostics.swift live`

## Accepted Limitation

Do not try to "fix" successful Codex `unverifiedInsert` as part of this task.

Codex is an opaque target and does not expose reliable AX text readback. The user explicitly accepted that successful Codex paste attempts may remain `unverifiedInsert`. Only investigate Codex insertion if text is actually missing or diagnostics show a failed truth state.

## Evidence From The Disk Failure

Commands D-Bug ran:

```sh
./Scripts/diagnostics.swift live
./Scripts/diagnostics.swift latest
./Scripts/diagnostics.swift recent 25
df -h / /tmp "$TMPDIR" "$HOME"
du -sh "$TMPDIR" "$HOME/Library/Application Support/HeadCanon" .build dist
```

Key diagnostics:

- `Workflow: Needs Attention (failed)`
- `Ready: Yes`
- `Audio Capture Recording: No`
- `Last Failure Stage: recordingStop`
- `Last Truth State: recordingFailed`
- `Last Error: Disk Full`
- `Transcription Started: Unknown`
- Recent failures: `recordingFailed`, not `transcriptionFailed`

Disk evidence before cleanup:

- `/System/Volumes/Data`: about `904 GiB` used, about `635 MiB` available, `100%` capacity
- Head Canon app support: about `1.2 MiB`
- Head Canon repo build output: about `355 MiB`
- Head Canon temp folder: tiny compared with system pressure

Disk evidence after cleanup:

- `/System/Volumes/Data`: about `889 GiB` used, about `16 GiB` available, `99%` capacity
- A `25 MiB` write test to `$TMPDIR` passed.

Caches D-Bug cleared:

```sh
swift package clean
rm -f "$TMPDIR"/headcanon-transcription-cancel-*.m4a
rm -rf "$HOME/.npm/_cacache" \
       "$HOME/.npm/_npx" \
       "$HOME/Library/Caches/pip" \
       "$HOME/Library/Caches/ms-playwright" \
       "$HOME/Library/Caches/ms-playwright-go" \
       "$HOME/Library/Caches/Homebrew" \
       "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"
```

Do not add automatic deletion of user files, Desktop folders, Adobe caches, Ableton caches, Telegram caches, or app data. If you add any cleanup command, keep it report-only by default unless it only touches Head Canon-owned scratch files.

## Implementation Goal

Make disk pressure a first-class readiness signal.

When free space is dangerously low, Head Canon should tell the user before recording starts, and diagnostics should clearly say `recordingFailed` or `setupBlocked/system readiness`, not leave the user thinking transcription broke.

## Required Work

1. Add a disk-space/readiness service.
   - Suggested location: `Sources/HeadCanon/Diagnostics/` or a new `Sources/HeadCanon/SystemReadiness/`.
   - It should report free bytes for the volume that contains `AudioCaptureService.recordingsDirectoryURL`.
   - It should expose thresholds:
     - warning below `10 GiB`
     - block recording below `2 GiB`
   - Keep thresholds testable/injectable.

2. Check disk space before starting recording.
   - In `HeadCanonModel.handleHotkeyPressed()`, before `audioCaptureService.startRecording(...)`, block if free space is below the hard threshold.
   - Set a clear error message, for example:
     - `Head Canon needs at least 2 GB free to record safely. Free up disk space and try again.`
   - Persist a diagnostic attempt or live event with an explicit stage.
   - Prefer truth state `.recordingFailed` unless you add a more specific truth state. Do not misclassify as transcription.

3. Improve recording-stop error copy.
   - If `audioCaptureService.stopRecording()` throws a disk-full/out-of-space error, translate it into the same clear user-facing copy.
   - Preserve underlying error detail in diagnostics if practical.
   - Existing raw `Disk Full` is accurate but not actionable enough.

4. Add a repo-local disk health script.
   - Suggested path: `Scripts/disk_health.sh`
   - It should be read-only/report-only by default.
   - Include:
     - `df -h / "$HOME" "$TMPDIR"`
     - free-space status relative to Head Canon thresholds
     - size of `$TMPDIR/HeadCanon`
     - size of `~/Library/Application Support/HeadCanon`
     - size of repo `.build` and `dist`
     - top cache candidates under `~/Library/Caches` and selected developer caches
   - It must not delete anything unless a future explicit flag is added.

5. Surface disk status in UI.
   - Minimal acceptable UI: show disk warning/blocker in settings/status summary.
   - Better UI: add a small "System Readiness" row that includes disk, microphone, accessibility, API key, and last failure.
   - Keep UI utilitarian; avoid adding a dashboard.

6. Add tests.
   - Test that low disk below hard threshold blocks recording before `AudioCapturing.startRecording`.
   - Test that warning threshold does not block recording.
   - Test that disk-full recording-stop errors become actionable copy.
   - Test diagnostics truth state/stage stays recording/system readiness, not transcription.

## Suggested Design

Use a protocol so tests can inject disk states:

```swift
protocol DiskSpaceChecking: Sendable {
    func freeBytes(for url: URL) throws -> Int64
}
```

Possible production implementation:

```swift
let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
```

Fallback to `.volumeAvailableCapacityKey` if important usage is unavailable.

Suggested policy struct:

```swift
struct DiskSpacePolicy {
    let warningThresholdBytes: Int64
    let minimumRecordingBytes: Int64
}
```

Keep formatting helper deterministic for tests: `2 GB`, `10 GB`, etc.

## Files To Inspect First

- `Sources/HeadCanon/App/HeadCanonModel.swift`
- `Sources/HeadCanon/Audio/AudioCaptureService.swift`
- `Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift`
- `Sources/HeadCanon/Diagnostics/LiveDiagnosticsRecord.swift`
- `Sources/HeadCanon/UI/MenuBarContentView.swift`
- `Sources/HeadCanon/UI/SettingsRootView.swift`
- `Scripts/diagnostics.swift`
- `Tests/HeadCanonTests/HeadCanonTests.swift`

## Verification Checklist

Run:

```sh
swift test
./Scripts/disk_health.sh
./Scripts/diagnostics.swift live
./Scripts/diagnostics.swift recent 10
```

If you install:

```sh
./Scripts/build_app_bundle.sh
./Scripts/install_dist_app.sh dist/HeadCanon.app
codesign -dv --verbose=4 /Applications/HeadCanon.app 2>&1 | awk -F= '/CDHash|Authority|Timestamp|Identifier/ {print}'
./Scripts/diagnostics.swift live
```

Only test `/Applications/HeadCanon.app`, not `dist/HeadCanon.app`.

## Non-Goals

- Do not implement automatic cleanup of broad system/user caches.
- Do not delete personal files.
- Do not change transcription provider/model.
- Do not re-open the accepted Codex `unverifiedInsert` limitation.
- Do not add realtime transcription or `whisper.cpp`.

## Work Prompt For Builder

You are Builder working in `/Users/worldbuilder/Desktop/Head Canon`. Implement disk-space readiness for Head Canon. The immediate user-facing bug is that low system disk space causes audio recording finalization to fail with `Disk Full`, which the user experiences as "transcription broke." Add a testable disk-space checker and policy, block recording before start when free space is below the hard threshold, show warning/readiness information when free space is low, translate disk-full recording-stop failures into actionable copy, and add a read-only `Scripts/disk_health.sh` diagnostic helper. Preserve existing transcription and insertion behavior. Treat successful Codex `unverifiedInsert` as accepted and do not try to mark it verified. Verify with `swift test`, the new disk health script, and live diagnostics. If installing, install only to `/Applications/HeadCanon.app` and record the installed CDHash.

