# Builder Memory

## Identity
- Builder is the working name for the coding agent in this repo starting on May 16, 2026.

## Mission
- Build a local-first macOS dictation app with the core loop:
  - invoke with a global hotkey
  - record bounded microphone audio
  - transcribe quickly
  - insert text into the focused app

## Current Runtime Facts
- Real runtime target: `/Applications/HeadCanon.app`
- Throwaway build artifact: `/Users/worldbuilder/Desktop/Head Canon/dist/HeadCanon.app`
- Platform target: macOS 14+, Apple Silicon first
- Current installed app identifier: `local.headcanon.app`
- Current installed app is signed with `HeadCanon Local Signing` in the latest D-Bug pass.
- Last D-Bug-installed CDHash on 2026-05-22 07:02 MST: `1022e255cdb3a6deddca5a2ac0a62111f29cbebd`.

## Current Working State
- Source builds cleanly.
- Tests passed with `swift test` at 97 tests in the latest D-Bug pass.
- App launches from `/Applications/HeadCanon.app`
- Microphone and Accessibility were granted in live diagnostics after the latest install.
- OpenAI API key was usable; recent transcription attempts completed successfully before disk pressure.
- Bounded dictation uses `gpt-4o-mini-transcribe` with `Standard Completed Recording`.
- Successful Codex paste attempts may remain `unverifiedInsert`; the user accepts this as an honest limitation because Codex does not expose reliable AX text readback.
- Live diagnostics are available with `./Scripts/diagnostics.swift live`.
- Recovery actions include `Paste Last Transcript` and `Copy Last Transcript`.

## Current Broken State
- The latest sudden failure was not transcription: recording finalization failed with `Disk Full`.
- Before cleanup, `/System/Volumes/Data` had roughly `635 MiB` free and reported `100%` capacity.
- After D-Bug cleared regenerable developer/package caches, free space recovered to roughly `16 GiB`, but the app still needs disk-space readiness guardrails.
- Disk-space readiness appears to have landed in the current runtime, but Builder should verify source/runtime alignment before treating it as complete.
- A later audit found an inserted-overlay re-entry anomaly: one failed attempt recorded `pressToRecordingStartDurationMS` around `11s`, then sent a suspiciously tiny audio file for transcription and received an OpenAI `400`.
- The recovery transcript UI still exists in source, but its large copyable panel is hidden whenever `lastTranscript` is empty, which makes the safety net appear missing after failures, relaunch, privacy clearing, or transcript clearing.

## High-Signal Constraints
- Do not test `dist/HeadCanon.app`
- Do not mix bundle paths during one checkpoint
- Do not treat successful Codex `unverifiedInsert` as a transcription failure.
- Do not automatically delete user files or broad app caches.
- Keep disk cleanup scripts report-only unless touching Head Canon-owned scratch files.
- Reinstalling can reset trust and muddy TCC results; install only when intentionally updating `/Applications/HeadCanon.app`.

## Known Failure Taxonomy
- `permission/readiness`
- `hotkey`
- `recording start`
- `recording stop`
- `transcription`
- `insertion`
- `system readiness / disk space`

## Builder Heuristics Learned
- Runtime state and source state must be logged separately
- macOS trust bugs can dominate all later debugging if not isolated first
- If a button appears dead in the UI, verify the implementation path before assuming user error
- Add in-app diagnostics early when external system state is ambiguous
- If the user says "transcription broke," check `./Scripts/diagnostics.swift live` before patching transcription. A `recordingStop`/`Disk Full` failure means the request never started.

## Current Builder Assignment
- See [2026-05-22-disk-readiness-handoff.md](/Users/worldbuilder/Desktop/Head%20Canon/Builder/handoffs/2026-05-22-disk-readiness-handoff.md).
- See [2026-05-22-inserted-overlay-recovery-ui-handoff.md](/Users/worldbuilder/Desktop/Head%20Canon/Builder/handoffs/2026-05-22-inserted-overlay-recovery-ui-handoff.md).
- Verify disk-space readiness source/runtime alignment, then prioritize inserted-overlay re-entry hardening and the always-visible Last Transcript recovery UI.
