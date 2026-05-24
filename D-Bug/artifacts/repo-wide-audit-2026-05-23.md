# Repo-Wide Audit - 2026-05-23

Owner: D-Bug
Branch: `main`
Repo: `/Users/worldbuilder/Desktop/Head Canon`

## Current Health

- Checkout is `main` and aligned with `origin/main` at `37ee5df`; the worktree is dirty with app, diagnostics, latency, browser-companion, docs, and artifact changes.
- `swift test` passes: `116 tests in 15 suites`.
- Installed app live diagnostics are clean: no active recording, no active transcription, ready state is `Yes`, disk readiness is `Healthy`, and the latest live workflow reached `Inserted`.
- Recent diagnostics are much healthier than the earlier stuck-recording windows. The latest 20 attempts are all inserted/unverified-in-Codex, with request-to-response p50 around `2163 ms`, release-to-inserted p50 around `2879 ms`, and response-to-inserted p50 around `626 ms`.
- Disk is currently healthy. The app reserve is present, `$TMPDIR/HeadCanon` is empty, app support is small, and Head Canon cache is dominated by the intentional reserve.

## Audit Findings

1. Live transcription is not currently broken.
   The newest window has no transcription failures. Earlier failures were mostly HTTP `200` responses with empty text bodies, and current source now classifies those as `noSpeechDetected` instead of generic `transcriptionFailed`.

2. The latency analyzer was still able to misclassify `noSpeechDetected`.
   I updated `Latency/bin/latency_decision_support.swift` so no-speech or too-short turns are excluded from transport/body-read degradation counts and shown separately as `No Speech / Too Short Turns`.

3. The successful path still has a network/pre-response tail.
   Most elapsed transcription time is before response body arrival, not after transcript receipt. Insertion overhead is currently small. This supports watching network/API responsiveness rather than rewriting insertion for the current symptom.

4. Codex insertion is still honestly `unverifiedInsert`.
   This remains accepted behavior because Codex does not expose reliable AX text readback. The app should preserve `Paste Last Transcript` and `Copy Last Transcript`; it should not pretend Codex insertion is verified.

5. The Last Transcript recovery regression appears fixed in source.
   `SettingsRootView` and `MenuBarContentView` both keep a visible `Last Transcript` recovery panel with selectable text plus copy/paste/clear actions. Tests cover retained transcript copy, paste, clear, and never-store behavior.

6. The worktree has several large streams mixed together.
   Dirty files include bounded transcription reliability, diagnostics schema v4/browser context, latency tooling, Browser Companion scaffolding, docs, and saved artifacts. This is manageable, but it is now the largest repo-level risk because source, installed app, docs, and experimental browser work can drift.

7. Browser Companion is promising but should be treated as an experimental boundary.
   It adds browser target classification, an unpacked Chromium extension, native messaging scripts, fixtures, and tests. Before productizing it, Builder should review host permissions, native-message trust boundaries, extension install flow, and whether it should remain opt-in developer tooling.

8. Diagnostics schema moved to v4.
   `DictationAttemptRecord` now includes browser metadata. Tests pass, including legacy decode tests, but any external tooling that reads attempts should be checked before relying on v4 artifacts broadly.

## Recommended Fix Plan

1. Stabilize the current reliability patch set on `main`.
   Keep the no-speech classification, too-short local guard, dynamic timeout for longer clips, and URLSession timeout changes together. Do not split these apart without rerunning the full diagnostic window.

2. Cleanly checkpoint the dirty worktree.
   Separate logical commits or handoff chunks: transcription reliability, diagnostics/latency tooling, Browser Companion scaffold, docs/artifacts. This will make future regressions much easier to bisect.

3. Keep the latency decision helper as the source of truth for "is transcription degraded?"
   After another failure, run:
   ```bash
   swift Latency/bin/latency_decision_support.swift --window 20
   ./Scripts/diagnostics.swift latest
   ./Scripts/diagnostics.swift summary-by-failure 50
   ```

4. Add a small synthetic diagnostic fixture for no-speech.
   Feed a saved attempt record with `truthState: noSpeechDetected` into the latency analyzer so future changes do not accidentally count no-speech as response-body instability again.

5. Keep recovery UI visible in both Settings and menu bar.
   Treat any change that hides `Last Transcript`, disables text selection, or removes copy/paste/clear as a regression unless the user explicitly asks for a new recovery UX.

6. Treat Browser Companion as opt-in until reviewed.
   Keep it out of the default app path unless the user intentionally installs/configures it. Review extension permissions before expanding host matches beyond local fixtures and specific supported domains.

7. Continue disk hygiene but do not chase disk as the current failure cause.
   The long-term reserve design is working right now. The practical next improvement is automated stale artifact/cache reporting rather than reducing the app reserve.

## Verification Run

- `swift test`: passed, `116 tests in 15 suites`.
- `./Scripts/diagnostics.swift live`: ready, no active recording, no active transcription, latest workflow inserted.
- `./Scripts/diagnostics.swift recent 12`: all 12 latest records are `unverifiedInsert` successes in Codex.
- `swift Latency/bin/latency_decision_support.swift --window 20`: `Assessment: healthy`, `Failures: 0`, `No Speech / Too Short Turns: 0`.
- `./Scripts/disk_health.sh`: healthy, app reserve present, `$TMPDIR/HeadCanon` empty.

## Bottom Line

The root issue from earlier stuck-recording windows is not present in the current live state. The next fixable repo-wide risks are diagnostic truthfulness, dirty-worktree discipline, and keeping the recovery UI and browser-companion experiments from regressing the now-healthy bounded dictation loop.

## 2026-05-23 18:45 Follow-Up

- The two reported post-build failures were not transcription failures. Diagnostics classified both as `recordingFailed` with `recordingStop` message `Head Canon could not find the recorded audio file.`
- Root-shaped cause: AVFoundation could report recording completion before the expected `.m4a` was visible at the output URL, so Head Canon could fail before transcription was ever attempted.
- Fix applied: audio finalization now waits briefly for the output file, accepts only non-empty files, and can recover the newest matching recording file from the recording directory before tearing down the capture session.
- Related test/tooling fix: Browser Companion native host now honors the process `HOME` environment when writing app-support snapshots, keeping its artifact test isolated.
- Verification: `swift test` passed with `120 tests in 16 suites`; rebuilt and installed `/Applications/HeadCanon.app` with CDHash `4eaf0a1bf28e9572271810bb19280a4f1ea018c9`.

## 2026-05-23 18:55 Disk Full Follow-Up

- A later `Disk Full` failure was not real storage exhaustion. `df` showed about `42 GiB` free, Head Canon disk readiness was `Healthy`, and the reserve was still present.
- The attempt lasted about `30s` with no hotkey release recorded, then failed at `recordingStop` before transcription. This points to a stuck/missed modifier-release recording reaching an AVFoundation recorder failure cliff.
- Fix applied: default missed-release safety finalization is now `25s` instead of `90s`, so the app should finalize and transcribe before the recorder reaches that failure window.
- Fix applied: if the recorder reports a disk-space style error while Head Canon disk readiness is healthy, the user-facing copy now treats it as an audio-capture/session failure instead of instructing the user to free disk space.
- Verification: `swift test` passed with `121 tests in 16 suites`; rebuilt and installed `/Applications/HeadCanon.app` with CDHash `71b6b2055cb0a995fc0d18ab48744b146dee6130`; live diagnostics after relaunch show `Ready`, `Audio Capture Recording: No`, `Hotkey Physically Pressed: No`, and disk readiness `Healthy`.
