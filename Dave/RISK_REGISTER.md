# Security Risk Register

Status values:
- `open`
- `in progress`
- `mitigated`
- `accepted`

## Active Risks

### R1. Clipboard transcript exposure
- Status: `open`
- Surface:
  - [Sources/HeadCanon/Insertion/TextInsertionService.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Insertion/TextInsertionService.swift)
  - [Sources/HeadCanon/App/ClipboardWriter.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/ClipboardWriter.swift)
  - [docs/V1_SPEC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/V1_SPEC.md)
- Why it matters:
  - paste fallback can expose dictated text through the system pasteboard
  - the current spec expects preserve-and-restore behavior whenever feasible
- Current evidence:
  - clipboard fallback exists
  - security workspace has not yet verified clipboard preservation and restoration behavior end to end
- Next action:
  - compare implementation against spec and document exact behavior

### R2. Diagnostics redaction drift
- Status: `open`
- Surface:
  - [Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift)
  - [Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift)
  - [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift)
- Why it matters:
  - local diagnostics are intentionally persistent
  - if sensitive content leaks into the schema later, retention turns a debugging aid into a privacy problem
- Current evidence:
  - schema currently records transcript length, not transcript text
  - no fresh audit has been recorded for every persisted field and reader output
- Next action:
  - run a field-by-field diagnostics redaction review and record the result

### R3. Off-device disclosure drift
- Status: `open`
- Surface:
  - [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift)
  - [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift)
  - [Sources/HeadCanon/UI/MenuBarContentView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/MenuBarContentView.swift)
- Why it matters:
  - network-backed transcription is acceptable only if the user cannot reasonably miss it
- Current evidence:
  - disclosure copy exists in settings and menu-bar UI
  - first-run enforcement has not been captured as a formal security checkpoint
- Next action:
  - verify first-transcription path against the security rubric and document the result

### R4. Local machine trust side effects
- Status: `open`
- Surface:
  - [Scripts/setup_local_codesign_identity.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/setup_local_codesign_identity.sh)
  - [Scripts/build_app_bundle.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/build_app_bundle.sh)
  - [Scripts/verify_dist_app.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/verify_dist_app.sh)
- Why it matters:
  - local code-signing setup alters the login Keychain trust configuration
  - that is a machine-security decision, not just an app-build detail
- Current evidence:
  - the script creates and trusts a root-like local code-signing certificate in the login Keychain
  - this behavior is not yet captured in a dedicated machine-impact note outside the script itself
- Next action:
  - document machine impact and define when this path is appropriate versus when a real Developer ID flow is required

### R5. Permission trust ambiguity across bundle paths
- Status: `open`
- Surface:
  - [docs/LOCAL_RUNTIME.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/LOCAL_RUNTIME.md)
  - [Sources/HeadCanon/Permissions/PermissionsManager.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Permissions/PermissionsManager.swift)
  - [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift)
- Why it matters:
  - TCC behavior can look safe or broken for the wrong bundle and mislead testing
- Current evidence:
  - repo docs already warn against mixing `dist/` and installed runtime testing
  - security workspace has not yet turned that into a machine-safety playbook
- Next action:
  - keep installed-bundle discipline explicit in machine guardrails and future checkpoints
