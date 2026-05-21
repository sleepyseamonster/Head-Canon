# Head Canon v1 Spec

## Summary
`Head Canon v1` is a local macOS dictation utility for personal use.

Security review for this repo should use [SECURITY_RUBRIC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/SECURITY_RUBRIC.md).
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
- transcription via `gpt-4o-mini-transcribe`
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
Default backend: `OpenAI gpt-4o-mini-transcribe`

Reason:

- current latency-first default for `v1`
- simpler than Realtime streaming
- supports bounded recordings naturally
- good stepping stone before adding a fully local backend
- avoids pulling local model packaging into `v1`
- `gpt-4o-transcribe` remains the higher-quality comparison path and should stay selectable until the app has enough live evidence to lock one default permanently

### Backend architecture
Transcription must be backend-pluggable from the start.

Planned backends:

- `OpenAIBoundedTranscriptionBackend` for `v1`
- `WhisperCppTranscriptionBackend` for local/offline follow-up
- `OpenAIRealtimeTranscriptionBackend` for later live streaming mode

## Functional Requirements
### App shell
- App launches as a lightweight macOS utility app.
- During development, a Dock-visible build is acceptable if it improves launch/debug/permission stability.
- The release profile may stay resident without a Dock icon once system integration is proven stable.
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
- Modifier-only shortcuts are allowed only if they are proven reliable in the installed app build.
- Default development hotkey should prefer reliability over cleverness.
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
- `v1` sends the completed recording to `gpt-4o-mini-transcribe`.
- Transcription request should support optional prompt context for later vocabulary tuning, but `v1` does not require a custom prompt editor.
- App stores the final transcript and exposes it as the “last transcript”.
- The app must require a valid OpenAI API key before enabling transcription.
- API keys must be stored in the macOS Keychain, not in plaintext settings files.
- On first setup, the app must validate the key with a lightweight connectivity/auth check before showing the app as ready.
- If the API key is missing or invalid, the app must remain usable for permissions and settings, but dictation must stay blocked with a clear remediation path.

### Insertion
- Direct accessibility-based text insertion remains the preferred path for strong native text targets.
- Clipboard paste is a first-class insertion transport for partial-AX and opaque editors.
- The app must not require a focused AX text element as a hard precondition for every insertion path.
- Clipboard-based insertion must preserve and restore the user’s clipboard contents whenever feasible.
- If insertion confidence is too low, the app must refuse to insert rather than risk wrong-app text delivery.
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
- broad app coverage must not come at the cost of silent wrong-target insertion

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
This area is the highest-risk subsystem in the app.

### Insertion context
The app should capture insertion context at hotkey release, but final transport selection should happen after transcription completes.

The captured context may include:

- a focused AX editor target when available
- the frontmost application identity
- the frontmost process identifier
- the frontmost window identity when detectable
- placeholder or secure-field signals when available

The app must not collapse all insertion modes into one requirement such as “focused AX element exists right now.”

### Transport order
Insertion should be attempted in this order:

1. capture release-time insertion context
2. after transcription, re-evaluate the current insertion context
3. if a high-confidence AX text target is still valid, use direct AX replacement
4. otherwise, if the app still has sufficient same-app confidence, use clipboard + simulated paste
5. verify the insertion outcome when feasible
6. preserve transcript and show failure state if confidence is too low or delivery fails

### Insertion safety policy
The app must bias toward safe failure over wrong-target insertion.

- If the target appears secure, block insertion.
- If the frontmost app changed between hotkey release and insertion time, block insertion by default.
- If the app cannot establish enough context to choose a safe transport, block insertion and preserve the transcript.
- If verification is limited, the app should report that honestly instead of claiming certain success.

### Focus drift policy
The default insertion policy is:

- same application required between release time and insertion time
- same window preferred when detectable
- same AX element required only for direct AX replacement
- application mismatch blocks insertion
- ambiguous focus drift blocks insertion rather than pasting blindly

### Clipboard transport contract
Clipboard insertion is a primary transport for broad editor coverage, not an embarrassing fallback.

Clipboard transaction rules:

- snapshot the current pasteboard contents before mutation
- write only the dictated transcript required for the current insertion
- dispatch paste only while the intended app remains frontmost under the active safety policy
- restore the prior clipboard contents after the paste completes when the pasteboard has not changed independently
- avoid clobbering newer clipboard contents if the user changed the pasteboard during insertion
- preserve at least plain text reliably; richer pasteboard types should be restored when feasible

### Verification and observability
Each insertion attempt should record local-only diagnostics for:

- release-time context
- insertion-time context
- chosen strategy
- rejected strategies
- focus drift result
- clipboard restore result when paste transport is used
- final success or failure classification

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
- insertion compatibility behavior only if needed to de-risk rollout or debugging

Do not add low-value settings in `v1`.

## Verification Matrix
`v1` acceptance testing must explicitly cover these targets:

- `TextEdit`
- `Notes`
- `Slack` message composer
- `Google Docs` or a standard `textarea` in `Chrome`
- `Terminal`
- one Electron app if `Slack` is not the chosen Electron test target
- `Codex`
- one secure text field as a negative test

The expected result for each target must be recorded as one of:

- direct insertion works
- clipboard transport works
- unsupported in `v1`

## Development Profiles
Use two explicit app profiles during development:

- `installed debug profile`
  - app lives at `/Applications/HeadCanon.app`
  - this is the only profile used for permission validation and end-to-end manual testing
  - this profile may show a Dock icon if that improves usability and debugging
- `dist build artifact`
  - produced locally for packaging and install steps
  - do not treat this path as the trusted long-lived runtime location for permission testing

Do not mix permission debugging across multiple bundle paths in the same checkpoint.

## Integration Checkpoints
Before adding polish or new features, the team must prove the following in order:

1. `installed app identity`
   - the app launches from `/Applications/HeadCanon.app`
   - relaunch does not change the tested bundle path
   - microphone and accessibility permissions are granted to this exact installed bundle
2. `hotkey proof`
   - the chosen default hotkey fires in the installed app repeatedly
   - app visibly enters `recording` while the hotkey is held
   - app visibly exits `recording` on release
3. `recording proof`
   - a short recording is successfully captured and finalized to a bounded audio payload
   - the user sees a clear overlay or equivalent transient status while recording/transcribing
4. `transcription proof`
   - the bounded audio payload reaches the configured backend
   - success and failure states are distinguishable in the UI
5. `insertion proof`
   - transcript insertion succeeds in `TextEdit`
   - clipboard transport is visible and recoverable when direct insertion is unavailable
6. `matrix proof`
   - only after `TextEdit` is reliable should testing expand to the rest of the verification matrix

## Acceptance Criteria
`v1` is acceptable when all of the following are true:

- app can launch reliably from an installed `/Applications` bundle
- app can obtain required permissions with clear user guidance
- app can collect, store, validate, and replace an OpenAI API key through a user-facing flow
- global hotkey starts and stops recording reliably in the installed app profile
- recording/transcribing state is visibly obvious while the hotkey workflow is active
- spoken dictation is transcribed with acceptable quality
- `TextEdit` works as the first proven insertion target
- text insertion behavior has been verified against the `v1` verification matrix
- transcript is recoverable when insertion fails
- clipboard transport does not permanently clobber the user clipboard during normal operation
- last transcript can be pasted from the menu

## Immediate Build Order
1. Stable installed app path and permission flow
2. Hotkey proof in installed app
3. Overlay/status feedback for recording/transcribing
4. Audio capture service
5. `gpt-4o-mini-transcribe` integration
6. `TextEdit` insertion proof
7. Verification matrix expansion
8. Settings and history

## Open Questions
- whether to keep dock icon during early development
- whether clipboard transport should be the default path for partial-AX editors or only for explicitly classified opaque editors
