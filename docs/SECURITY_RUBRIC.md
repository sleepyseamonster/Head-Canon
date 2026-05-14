# Voice Flow Security Rubric

## Purpose
Use this rubric before calling the app "secure enough" for daily use.

This is not a generic enterprise checklist.
It is a practical rubric for this repo and this product:

- local macOS menu bar app
- microphone access
- accessibility-based text insertion
- optional off-device transcription
- local-first single-user use

This rubric is a release and review tool, not a creativity limiter.

- use it to judge merged behavior, user-facing flows, and trusted builds
- do not use it to block fast experiments, throwaway spikes, or local exploration
- exploratory work is allowed as long as risky behavior is clearly marked and not misrepresented as trusted or production-ready

## Rating
Score each category from `0` to `2`.

- `0`: not implemented, misleading, or unsafe by default
- `1`: partially implemented, but still has meaningful gaps
- `2`: implemented, verified, and acceptable for `v1`

Maximum score: `12`

Suggested interpretation:

- `0-4`: not safe enough for regular use
- `5-7`: usable prototype, but still security-weak
- `8-10`: good personal-use baseline
- `11-12`: strong `v1` posture for this app class

## Hard Gates
If any hard gate fails, the app does not pass review no matter what the total score is.

1. The app must not silently record in the background.
2. The app must not silently send audio off-device.
3. The app must not insert dictated text into secure/password fields.
4. Paste fallback must fail closed if focus changes.
5. API keys must not be stored in plaintext settings.
6. Release builds must not be treated as trusted unless signing verification passes.

These hard gates apply to reviewed behavior, shared branches, and release candidates.
They do not forbid short-lived local spikes, but any spike that violates them must stay clearly experimental and must not be presented as secure.

## Categories

### 1. Permissions And Activation
Goal: only ask for the minimum required privileges, and make them obvious.

Score `0`

- permission state is unclear or misleading
- app asks for more permissions than needed
- app can appear ready while blocked

Score `1`

- microphone and accessibility are handled
- setup is understandable
- some edge cases still produce confusing states

Score `2`

- only microphone and accessibility are requested
- blocked state is obvious and actionable
- app never pretends to be ready when permissions are missing
- onboarding clearly explains why each permission is needed

Evidence

- verify onboarding and settings copy
- verify missing permission states in the running app
- verify the app does not request `Input Monitoring`

### 2. Secrets And Credentials
Goal: keep the API key out of plaintext storage and avoid accidental disclosure.

Score `0`

- API key is in `UserDefaults`, files, logs, or UI in plaintext after entry

Score `1`

- API key is in Keychain
- storage or replacement behavior is not explicitly hardened

Score `2`

- API key is stored in Keychain only
- Keychain accessibility is explicitly set
- UI only exposes presence and validation state
- logs and errors do not echo secrets

Evidence

- inspect [APIKeyStore.swift](/Users/worldbuilder/Desktop/Voice%20Flow/Sources/VoiceFlow/Security/APIKeyStore.swift)
- search the repo for secret logging patterns
- validate key add, replace, remove, and invalid-key flows

### 3. Audio And Transcript Privacy
Goal: dictated content should live for as short a time as possible.

Score `0`

- raw audio or transcript text is retained unexpectedly
- privacy settings do not match actual behavior

Score `1`

- temporary audio is cleaned up on normal paths
- transcript retention is limited, but behavior is still incomplete or unclear

Score `2`

- stale temp audio is cleaned up on startup and failure paths
- transcript retention behavior matches the UI copy
- `Never store` actually disables retained transcript state
- user can immediately clear retained transcript text
- implemented retention behavior is also consistent with the current `v1` spec, or the spec has been explicitly amended

Evidence

- inspect [AudioCaptureService.swift](/Users/worldbuilder/Desktop/Voice%20Flow/Sources/VoiceFlow/Audio/AudioCaptureService.swift)
- inspect [VoiceFlowModel.swift](/Users/worldbuilder/Desktop/Voice%20Flow/Sources/VoiceFlow/App/VoiceFlowModel.swift)
- inspect settings and menu-bar transcript actions
- force-quit during recording and check for leftover app recording files
- compare implemented retention behavior against [V1_SPEC.md](/Users/worldbuilder/Desktop/Voice%20Flow/docs/V1_SPEC.md)

### 4. Text Insertion Safety
Goal: never send dictated text somewhere surprising or unsafe.

Score `0`

- insertion can reach secure fields
- paste fallback can hit the wrong target after a focus change

Score `1`

- direct insertion works safely
- paste fallback still has unresolved edge cases across apps

Score `2`

- secure text fields are blocked
- paste fallback re-checks focus before posting events
- insertion failures leave the transcript recoverable when policy allows
- common target apps have been manually validated
- target-by-target validation results are recorded, not just summarized

Evidence

- inspect [TextInsertionService.swift](/Users/worldbuilder/Desktop/Voice%20Flow/Sources/VoiceFlow/Insertion/TextInsertionService.swift)
- manually test:
  - password field
  - TextEdit
  - Notes
  - Terminal
  - Slack composer
  - Chrome or Safari textarea
- record each result as:
  - direct insertion works
  - paste fallback works
  - blocked by policy
  - unsupported / failed

### 5. Network And Disclosure
Goal: off-device behavior must be explicit and minimal.

Score `0`

- app sends audio or transcript data without clear disclosure
- network backend behavior is hidden or ambiguous

Score `1`

- OpenAI use is disclosed
- backend behavior is visible, but not enforced through enough UX surfaces

Score `2`

- network-backed transcription is clearly disclosed in onboarding and settings
- app does not transmit before explicit user action
- only expected endpoints are used
- failure states clearly distinguish auth, network, and local insertion errors
- first-run validation proves the user sees off-device disclosure before the first possible upload

Evidence

- inspect [OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Voice%20Flow/Sources/VoiceFlow/Transcription/OpenAIBoundedTranscriptionBackend.swift)
- inspect onboarding/settings copy
- inspect error handling in [VoiceFlowModel.swift](/Users/worldbuilder/Desktop/Voice%20Flow/Sources/VoiceFlow/App/VoiceFlowModel.swift)
- validate first-run flow in the running app:
  - user sees off-device disclosure
  - user cannot reasonably miss disclosure before first transcription
  - first transcription still requires explicit user action

### 6. Packaging, Provenance, And Verification
Goal: users should know whether the app is actually trustworthy to run.

Score `0`

- app is shipped from debug output
- signing state is implicit
- verification is not checked

Score `1`

- app is built from release
- signing behavior is explicit
- verification exists, but the machine is not yet able to produce a trusted build

Score `2`

- release build requires a real signing identity
- hardened runtime is enabled when identity signing is used
- `codesign` verification passes
- Gatekeeper assessment passes
- signing evidence confirms the expected Developer ID identity or Team ID, not just any passing signature

Evidence

- inspect [build_app_bundle.sh](/Users/worldbuilder/Desktop/Voice%20Flow/Scripts/build_app_bundle.sh)
- inspect [verify_dist_app.sh](/Users/worldbuilder/Desktop/Voice%20Flow/Scripts/verify_dist_app.sh)
- run:

```bash
swift test
VOICEFLOW_CODESIGN_IDENTITY="Developer ID Application: <Name>" Scripts/build_app_bundle.sh
Scripts/verify_dist_app.sh
```

- record:
  - expected signing identity
  - actual signing identity from `codesign -dv`
  - expected Team ID
  - actual Team ID from `codesign -dv`

## Review Process
Run this before any "secure enough" claim:

1. Score all 6 categories.
2. Check all hard gates.
3. Write down evidence for each `2`.
4. Treat every `0` as a blocker.
5. Treat any failed hard gate as an immediate stop.

## Security Versus Spec
This rubric does not override the product spec.

- A feature can be relatively safe and still fail `v1` expectations.
- A reviewer must separately note any spec deviation that affects privacy, retention, disclosure, insertion behavior, or release trust.
- Do not award a `2` when the implementation is only "safe for now" but still materially narrower than the current spec promise.

## Creative Development
Use these rules to preserve momentum:

1. Spikes are allowed.
2. Temporary shortcuts are allowed during exploration.
3. Creative UX or architecture changes are allowed even if the final security shape is not decided yet.

Conditions:

- clearly label the work as experimental
- do not claim the spike is secure or release-ready
- do not silently widen permissions or off-device behavior
- do not merge known security regressions without documenting them
- before trusting or shipping the result, run the rubric normally

## Current v1 Target
Minimum acceptable personal-use bar:

- no hard gate failures
- total score at least `8/12`
- category `4` must be at least `1`
- category `6` must be at least `1` for local dev use
- category `6` must be `2` before calling a release build trusted

## Security Review Template
Copy this into a PR, issue, or checkpoint note.

```md
# Security Review

Date:
Reviewer:
Commit:

## Hard Gates
- No silent background recording: pass/fail
- No silent off-device transmission: pass/fail
- No secure-field insertion: pass/fail
- Paste fallback fails closed on focus change: pass/fail
- API key not stored in plaintext: pass/fail
- Release trust only claimed after signing verification: pass/fail

## Scores
- Permissions And Activation: 0/1/2
- Secrets And Credentials: 0/1/2
- Audio And Transcript Privacy: 0/1/2
- Text Insertion Safety: 0/1/2
- Network And Disclosure: 0/1/2
- Packaging, Provenance, And Verification: 0/1/2

Total:

## Spec Deviations
- none

## Evidence
- 

## Insertion Validation Matrix
- Password field:
- TextEdit:
- Notes:
- Terminal:
- Slack composer:
- Chrome or Safari textarea:

## Release Identity Verification
- Expected signing identity:
- Actual signing identity:
- Expected Team ID:
- Actual Team ID:

## First-Run Disclosure Verification
- Disclosure shown before first possible upload: pass/fail
- Settings disclosure present: pass/fail
- Notes:

## Findings
- 

## Decision
- pass
- pass with caveats
- fail
```
