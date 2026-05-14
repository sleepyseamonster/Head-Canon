# Voice Flow v1 Spec

## Summary
`Voice Flow v1` is a local macOS menu bar app for personal dictation.

Security review for this repo should use [SECURITY_RUBRIC.md](/Users/worldbuilder/Desktop/Voice%20Flow/docs/SECURITY_RUBRIC.md).
The rubric is intended to gate reviewed behavior and trusted builds, not to suppress creative development spikes.

Primary loop:

1. Hold a global hotkey.
2. Speak.
3. Release the hotkey.
4. Audio is transcribed.
5. The transcript is inserted into the currently focused app.

`v1` optimizes for a dependable bounded dictation workflow, not full Wispr Flow feature parity.

## Product Goal
Ship a usable first version that feels fast enough to become a daily tool on one local Mac.

Success means:

- hotkey activation is reliable
- permissions are understandable
- transcript quality is high
- insertion works in common desktop apps
- failure states are obvious and recoverable

Creative exploration is encouraged during development, especially around interaction design, local architecture, and latency experiments.
The constraint is simple: experimental work must not be confused with secure, trusted, or release-ready behavior until it passes review.

## Target Environment
- platform: `macOS`
- minimum supported version: `macOS 14`
- device target: `Apple Silicon`
- distribution: local-only
- user count: one user
- network: allowed for initial transcription backend

## Core User Story
As the only user, I want to hold a shortcut anywhere on my Mac, speak naturally, release the shortcut, and have polished text appear where my cursor already is.

## v1 In Scope
- menu bar app
- settings window
- first-run onboarding
- microphone permission flow
- accessibility permission flow
- OpenAI API key onboarding and validation
- global push-to-talk hotkey
- bounded audio capture while hotkey is held
- transcription via `gpt-4o-transcribe`
- transcript insertion into the focused app
- paste fallback when direct insertion fails
- lightweight recording/transcribing status UI
- microphone selection
- paste last transcript
- local settings persistence
- local transcript history with simple retention controls

## v1 Out Of Scope
- account system
- sync across devices
- team features
- command mode
- rewrite/edit AI transformations
- always-on passive listening
- wake word
- hands-free double-tap dictation mode
- live partial transcript rendering during speech
- translation mode
- mobile clients
- browser extension

## Product Decisions
### Interaction model
Use `hold-to-talk` only in `v1`.

Reason:

- simpler mental model
- simpler implementation
- avoids premature session management complexity
- aligns well with bounded request-based transcription

### Initial transcription backend
Default backend: `OpenAI gpt-4o-transcribe`

Reason:

- strongest implementation-speed to quality tradeoff for `v1`
- simpler than Realtime streaming
- supports bounded recordings naturally
- good stepping stone before adding a fully local backend
- avoids pulling local model packaging into `v1`

### Backend architecture
Transcription must be backend-pluggable from the start.

Planned backends:

- `OpenAIBoundedTranscriptionBackend` for `v1`
- `WhisperCppTranscriptionBackend` for local/offline follow-up
- `OpenAIRealtimeTranscriptionBackend` for later live streaming mode

## Functional Requirements
### App shell
- App launches as a menu bar utility.
- App can stay resident without a dock icon unless debugging requires otherwise.
- Menu includes:
  - current status
  - start onboarding or fix permissions
  - open settings
  - paste last transcript
  - quit

### Permissions
- App checks and surfaces:
  - microphone permission
  - accessibility permission
- If a required permission is missing, the app must explain why it is needed and deep-link or guide the user to the correct macOS settings area.
- The app must not pretend to be ready while required permissions are missing.
- `v1` must not request `Input Monitoring`.

### Hotkey
- One configurable global hotkey.
- Default shortcut must avoid known problematic modifier-only combinations.
- Default hotkey: `Control + Option + Space`
- On hotkey down:
  - begin recording if app is ready
- On hotkey up:
  - stop recording
  - send audio for transcription

### Audio capture
- Capture mono microphone audio suitable for transcription.
- Show live level feedback while recording.
- Support user-selected microphone input.
- Persist the preferred input device.

### Transcription
- `v1` sends the completed recording to `gpt-4o-transcribe`.
- Transcription request should support optional prompt context for later vocabulary tuning, but `v1` does not require a custom prompt editor.
- App stores the final transcript and exposes it as the “last transcript”.
- The app must require a valid OpenAI API key before enabling transcription.
- API keys must be stored in the macOS Keychain, not in plaintext settings files.
- On first setup, the app must validate the key with a lightweight connectivity/auth check before showing the app as ready.
- If the API key is missing or invalid, the app must remain usable for permissions and settings, but dictation must stay blocked with a clear remediation path.

### Insertion
- Primary path: direct accessibility-based text insertion into the focused UI element.
- Secondary path: replace via selection-aware paste when direct insertion is unavailable.
- Clipboard fallback must preserve and restore the user’s clipboard contents whenever feasible.
- If insertion fails, the transcript must remain available for manual paste.

### Status UI
- Show clear transient states:
  - idle
  - permission blocked
  - recording
  - transcribing
  - inserted
  - failed
- The status UI should be small and not dashboard-like.

### History and retention
- Store recent transcripts locally by default.
- Default retention policy: keep history enabled and auto-delete entries after `30 days`.
- Support at least:
  - keep history
  - auto-delete after a retention window
  - never store history

## Non-Functional Requirements
### Performance
- hotkey activation should feel immediate
- audio recording start should be effectively instant to the user
- end-to-insert latency should be minimized for short dictation turns

### Reliability
- insertion behavior matters more than UI polish
- failures must degrade safely to copy/paste or paste-last-transcript

### Privacy
- no passive background recording
- no cloud sync
- no silent off-device transmission
- the app must explicitly disclose that `v1` uses an OpenAI-hosted transcription backend
- keep local logs minimal

## UX Requirements
- First run should make it obvious why permissions are needed.
- The app should always communicate whether it is:
  - ready
  - blocked
  - recording
  - working
- The user should never lose dictated text silently.
- If insertion fails, the app should say so and preserve the transcript.

## Technical Architecture
### Modules
- `AppShell`
- `Permissions`
- `Hotkeys`
- `AudioCapture`
- `Transcription`
- `TextInsertion`
- `Overlay`
- `History`
- `Settings`

### Suggested protocols
- `TranscriptionBackend`
- `TextInsertionStrategy`
- `HotkeyManaging`
- `AudioCapturing`
- `APIKeyStoring`

### Initial backend shape
`TranscriptionBackend` should accept a bounded audio payload and return:

- final transcript text
- timing or duration metadata when available
- backend identifier
- raw response metadata only if needed for debugging

## Text Insertion Strategy
Insertion should be attempted in this order:

1. identify the focused accessibility element
2. attempt direct value or selection replacement through accessibility APIs
3. snapshot clipboard contents, then fall back to clipboard + simulated paste
4. preserve transcript and show failure state if both paths fail

This area is the highest-risk subsystem in the app.

## Error Handling
The app must explicitly handle:

- missing microphone permission
- missing accessibility permission
- no focused writable target
- network failure during transcription
- OpenAI authentication failure
- unsupported or unavailable microphone
- insertion rejection by target app

Each error must map to a user-facing message with one clear next action.

## OpenAI Credentials
- `v1` requires a user-supplied OpenAI API key.
- The key must be entered in onboarding or settings.
- The key must be stored in the macOS Keychain.
- The app should expose only key presence and validation state in settings, not the full secret.
- The app must provide:
  - missing key state
  - invalid key state
  - network unavailable state
  - ready state

## Settings Surface
`v1` settings should include:

- hotkey
- microphone input device
- OpenAI API key state and replace/remove actions
- store history on/off
- retention behavior
- paste fallback behavior toggle if needed

Do not add low-value settings in `v1`.

## Verification Matrix
`v1` acceptance testing must explicitly cover these targets:

- `TextEdit`
- `Notes`
- `Slack` message composer
- `Google Docs` or a standard `textarea` in `Chrome`
- `Terminal`
- one Electron app if `Slack` is not the chosen Electron test target

The expected result for each target must be recorded as one of:

- direct insertion works
- paste fallback works
- unsupported in `v1`

## Acceptance Criteria
`v1` is acceptable when all of the following are true:

- app can launch and remain active in the menu bar
- app can obtain required permissions with clear user guidance
- app can collect, store, validate, and replace an OpenAI API key through a user-facing flow
- global hotkey starts and stops recording reliably
- spoken dictation is transcribed with acceptable quality
- text insertion behavior has been verified against the `v1` verification matrix
- transcript is recoverable when insertion fails
- clipboard fallback does not permanently clobber the user clipboard during normal operation
- last transcript can be pasted from the menu

## Immediate Build Order
1. App shell and menu bar presence
2. Permissions service and onboarding UI
3. Hotkey registration
4. Focused-element insertion spike
5. Audio capture service
6. `gpt-4o-transcribe` integration
7. Overlay/status feedback
8. Settings and history

## Open Questions
- whether to keep dock icon during early development
- whether clipboard paste fallback should be silent or explicitly indicated
