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
- Current installed app is ad-hoc signed, not signed with a stable identity

## Current Working State
- Source builds cleanly with `swift build`
- Tests pass with `swift test`
- App launches from `/Applications/HeadCanon.app`
- Microphone permission has been reported as granted in the UI
- OpenAI API key has been reported as valid in the UI
- Diagnostics and setup-action improvements were added to source
- `Relaunch` was patched in source to use `/usr/bin/open -na <app>`

## Current Broken State
- Accessibility is still not reaching a granted state in the installed app
- The app repeatedly hits TCC checks and remains in `Pending Approval`
- The installed runtime has not yet proven end-to-end dictation in `TextEdit`
- Hotkey, recording, transcription, and insertion are not yet proven live in the installed app

## High-Signal Constraints
- Do not test `dist/HeadCanon.app`
- Do not mix bundle paths during one checkpoint
- Do not expand beyond `TextEdit` until the core loop is proven there
- Reinstalling the ad-hoc app can reset trust and muddy TCC results

## Known Failure Taxonomy
- `permission/readiness`
- `hotkey`
- `recording start`
- `recording stop`
- `transcription`
- `insertion`

## Builder Heuristics Learned
- Runtime state and source state must be logged separately
- macOS trust bugs can dominate all later debugging if not isolated first
- If a button appears dead in the UI, verify the implementation path before assuming user error
- Add in-app diagnostics early when external system state is ambiguous
