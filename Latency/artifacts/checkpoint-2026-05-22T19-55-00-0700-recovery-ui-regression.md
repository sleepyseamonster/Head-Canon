# Latency Checkpoint: Recovery UI Visibility Regression

Date: 2026-05-22 19:55 MST  
Actor: D-Bug  
Scope: Latency coordination, recovery UI safety net  
Repo: `/Users/worldbuilder/Desktop/Head Canon`

## Summary

The user suspects recent latency work introduced a UI regression: the copyable "last transcription" text box no longer appears reliably. Source audit confirmed the likely regression mechanism. The recovery panel still existed, but both menu and Settings only rendered it when `model.lastTranscript` was non-empty.

That conditional behavior makes the safety net disappear after a transcription failure, relaunch, privacy clearing, manual clear, or any other state where there is no retained transcript. For a latency-focused workflow this is risky because faster UI/status work can accidentally remove the user's visible recovery path.

## Fix Applied

The UI now keeps the recovery surface visible in both places:

- `Sources/HeadCanon/UI/MenuBarContentView.swift`
- `Sources/HeadCanon/UI/SettingsRootView.swift`

The panel is now labeled `Last Transcript` and shows one of three states:

- retained transcript available and selectable
- `No retained transcript yet.`
- `Transcript retention is off.`

The copy/paste/clear controls remain disabled when no transcript is available, but the user no longer has to guess where the recovery box went.

## Latency Lesson

This is a user-perceived latency/reliability issue, not just a UI polish issue. When insertion is unverified or fails, the time-to-recovery includes whether the user can immediately find and copy the last transcript. Hiding the recovery surface improves visual compactness but worsens perceived reliability and makes failures feel like data loss.

Future latency work should treat the visible recovery path as part of the performance budget:

- do not hide the recovery surface to reduce UI noise
- measure and optimize the primary path without removing fallback affordances
- preserve "fast failure recovery" alongside activation-to-insert latency

## Next Check

After the next install, verify manually:

1. Launch `/Applications/HeadCanon.app`.
2. Open the menu bar popover before any dictation.
3. Confirm `Last Transcript` is visible with `No retained transcript yet.`
4. Complete a successful dictation.
5. Confirm the panel shows selectable transcript text.
6. Clear the transcript.
7. Confirm the panel remains visible with the empty state.
8. Set retention to `Never store`.
9. Confirm the panel remains visible and explains retention is off.
