# AGENTS.md

## Mission
Build a local-first macOS voice dictation app with the same core user experience category as Wispr Flow:

- invoke with a global hotkey
- capture microphone audio quickly
- transcribe with low latency
- insert text into the currently focused app
- keep the UX fast enough to feel ambient

This project is for local personal use first, not multi-user SaaS.

## Product Priorities
1. Fast activation-to-text latency.
2. Reliable text insertion into arbitrary macOS apps.
3. Clear permission handling for microphone and accessibility.
4. Local-first app behavior, explicit privacy boundaries, and simple local setup.
5. Small, understandable architecture before adding polish.

## Default Technical Direction
Unless the user explicitly redirects the stack, prefer a native macOS app:

- language: Swift
- UI: SwiftUI
- target: macOS 14+
- hardware target: Apple Silicon first

Reasoning:

- system-wide hotkeys, accessibility APIs, event taps, and focused-text insertion are core to the product
- native macOS APIs are a better fit than Electron/Tauri for the first working version
- local-only distribution removes the need for cross-platform compromises

## MVP Scope
Build in this order:

1. App shell with menu bar presence and settings window.
2. Permission onboarding for microphone and accessibility.
3. Global push-to-talk hotkey.
4. Audio capture pipeline.
5. Speech-to-text pipeline.
6. Insert transcript into the focused text field.
7. Lightweight visual feedback while recording/transcribing.
8. Basic settings for hotkey, microphone, API key state, history, and paste fallback behavior.

## Non-Goals For Early Iterations
- cloud sync
- team features
- auth
- billing
- cross-platform support
- perfect parity with any commercial product
- broad plugin architecture before the core loop works

## Speech Recognition Direction
Use a backend-pluggable transcription layer.

Initial implementation priority:

1. `gpt-4o-transcribe` for bounded push-to-talk dictation
2. `whisper.cpp` as the local/offline fallback backend
3. `gpt-realtime-whisper` only after the bounded dictation loop is solid

Reasoning:

- bounded dictation is the fastest path to a high-quality usable product
- OpenAI request-based transcription is simpler than a live Realtime session
- `whisper.cpp` remains important for local/offline control and privacy
- the transcription provider must not be hard-coded into app logic

Selection criteria:

- activation-to-text latency
- transcript quality in real desktop conditions
- implementation complexity
- privacy and offline story
- packaging and local setup cost

## Architecture Guidelines
Keep the codebase split by responsibility:

- `App`: lifecycle, menus, windows, dependency wiring
- `Permissions`: microphone/accessibility state
- `Hotkeys`: global shortcut registration and handling
- `Audio`: recording and buffering
- `Transcription`: STT backend abstraction and implementations
- `Insertion`: accessibility-driven text insertion and paste fallback
- `Overlay`: recording/transcribing status UI
- `Settings`: persisted local configuration

Prefer protocol-backed boundaries where a subsystem may later swap implementations, especially transcription and text insertion.

Transcription should expose one app-facing interface with multiple backends behind it.

## UX Requirements
- Recording must only begin from an explicit user action such as a hotkey.
- The app must make permission state obvious.
- Failures must surface actionable next steps, not silent no-ops.
- UI should stay minimal and utilitarian; this is a tool, not a dashboard.
- Latency matters more than visual flourish.

## Privacy And Safety Guardrails
- Do not continuously record in the background without explicit user direction.
- Do not implement general keylogging behavior.
- Never transmit audio or transcripts off-device silently.
- If a configured backend sends data off-device, make that explicit in onboarding and settings.
- Keep logs minimal and avoid storing raw audio unless needed for a user-approved debug mode.
- Preserve a clean path to a fully local backend even if `v1` starts with a network-backed backend.

## Coding Rules For Agents
- Prefer the simplest working native approach over abstraction-heavy design.
- Validate assumptions against actual macOS API constraints before building wrappers.
- When adding dependencies, justify why the standard library or Apple frameworks are insufficient.
- Keep files readable; avoid premature frameworking.
- Add tests where practical, but do not block core platform integration work on test purity.

## Checkpoint Discipline
At each meaningful implementation checkpoint, do all of the following before moving on:

1. Audit the work that was just completed.
2. Identify any issues, contradictions, regressions, missing verification, or scope drift introduced by that work.
3. State the next steps based on:
   - the current implementation state
   - what the audit found
   - the highest-risk remaining work

Do not treat a checkpoint summary as complete unless it includes both:

- a short audit of the work just done
- the next recommended steps from that exact state

## Execution Strategy
When the repo is otherwise empty, start with:

1. Write and maintain the `v1` product spec.
2. Xcode project or Swift Package layout decision.
3. Minimal app shell.
4. Permission flow.
5. Global hotkey spike.
6. Focused-app text insertion spike.
7. Bounded audio capture plus `gpt-4o-transcribe`.
8. Only after that, explore local and live-streaming backends.

The main risk is not UI. The main risk is dependable system integration and text insertion reliability. Optimize early work around proving that.
