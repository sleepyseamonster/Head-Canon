# Threat Model

## Product Shape
- local-first single-user macOS menu bar app
- explicit push-to-talk recording only
- Accessibility-based text insertion
- optional off-device transcription in `v1`

## Assets To Protect
- microphone audio
- dictated transcript text
- OpenAI API key
- user clipboard contents
- focused-app context and insertion target
- local diagnostics data
- trust in the installed app bundle and signing identity

## Trust Boundaries

### User Intent Boundary
- recording should begin only after an explicit user action
- transcription should only occur for the audio captured by that action

### macOS Privilege Boundary
- microphone permission grants access to audio capture
- Accessibility permission grants access to focused-app inspection and insertion
- the app should not broaden beyond those permissions for `v1`

### Off-Device Boundary
- OpenAI-hosted transcription sends audio off-device
- this must stay visible in UX and never happen silently

### Cross-App Data Boundary
- insertion into another app is high risk because wrong-target failures are plausible
- clipboard fallback is especially sensitive because it touches system-wide shared state

### Machine Trust Boundary
- installed bundle path, signing identity, Keychain trust, and Gatekeeper verification affect whether the local Mac should treat the app as trustworthy

## Primary Abuse Cases
- dictated text lands in the wrong app after a focus change
- dictated text lands in a secure or password field
- transcript text leaks into the system pasteboard longer than intended
- API key remains in plaintext due to migration or logging mistakes
- diagnostics start retaining more user content than intended
- the app sends audio off-device before the user understands that it will
- ad-hoc or locally trusted builds are mistaken for production-trusted binaries
- local machine trust is weakened by convenience scripts without the impact being obvious

## Hard Security Expectations
- no background recording without explicit user action
- no silent off-device audio transmission
- no insertion into secure text fields
- no plaintext API key storage as the steady-state configuration
- no default diagnostics retention of raw transcript text
- no treating unverifiable builds as trusted release artifacts

## Design Biases
- prefer fail-closed behavior over surprising cross-app insertion
- prefer shorter retention over convenience when sensitive content is involved
- prefer explicit user-facing disclosure over hidden defaults
- prefer machine-local trust changes only when their impact is clearly explained
