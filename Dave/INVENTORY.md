# Security Inventory

This file is the repo-wide map of security-relevant ownership.

Rule:
- Files stay in their real working locations.
- `Dave/` tracks why they matter, what security surface they belong to, and where review should start.

## Core Security Ownership

### Secrets And Credentials
- [Sources/HeadCanon/Security/APIKeyStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Security/APIKeyStore.swift)
  Keychain storage, legacy plaintext migration, key removal behavior.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift)
  User-facing save, validate, and remove key flows plus setup-blocking behavior.
- [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift)
  OpenAI key entry, validation, disclosure, and state display.
- [Sources/HeadCanon/UI/MenuBarContentView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/MenuBarContentView.swift)
  Fast-path API key entry and disclosure copy.

### Permissions And Trust Boundaries
- [Sources/HeadCanon/Permissions/PermissionsManager.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Permissions/PermissionsManager.swift)
  Microphone and Accessibility permission reads and prompts.
- [Sources/HeadCanon/Permissions/PermissionDebugging.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Permissions/PermissionDebugging.swift)
  Permission diagnosis, trust-state reasoning, and self-test support.
- [Sources/HeadCanon/UI/OnboardingChecklistView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/OnboardingChecklistView.swift)
  First-run permission UX.
- [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift)
  Runtime identity, permission help, diagnostics visibility.
- [docs/LOCAL_RUNTIME.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/LOCAL_RUNTIME.md)
  Installed-bundle path discipline and TCC behavior.

### Audio, Transcript, And Retention Privacy
- [Sources/HeadCanon/Audio/AudioCaptureService.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Audio/AudioCaptureService.swift)
  Microphone capture, temp-file handling, and cleanup expectations.
- [Sources/HeadCanon/Settings/AppPreferences.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Settings/AppPreferences.swift)
  Transcript retention settings and privacy-facing defaults.
- [Sources/HeadCanon/App/HeadCanonModel.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/HeadCanonModel.swift)
  Last-transcript handling, retention application, clipboard recovery, diagnostics payload assembly.
- [docs/V1_SPEC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/V1_SPEC.md)
  Privacy expectations, transcript retention promises, and clipboard restore requirements.

### Text Insertion And Clipboard Safety
- [Sources/HeadCanon/Insertion/TextInsertionService.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Insertion/TextInsertionService.swift)
  AX-based insertion, secure-target blocking, focus-change safety, paste fallback decisions.
- [Sources/HeadCanon/App/ClipboardWriter.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/ClipboardWriter.swift)
  System pasteboard writes for transcript fallback paths.
- [Scripts/analyze_focused_target.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/analyze_focused_target.swift)
  Manual focused-target analysis for insertion debugging.
- [docs/V1_SPEC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/V1_SPEC.md)
  Clipboard preserve-and-restore expectations and safety requirements.

### Network Disclosure And Hosted Transcription
- [Sources/HeadCanon/Transcription/TranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/TranscriptionBackend.swift)
  App-facing backend contract, error taxonomy, and transport metadata shape.
- [Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift)
  OpenAI request construction, network transport, error mapping, and metadata capture.
- [Sources/HeadCanon/UI/SettingsRootView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/SettingsRootView.swift)
  Explicit disclosure that `v1` uses a network-backed OpenAI transcription path.
- [Sources/HeadCanon/UI/MenuBarContentView.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/UI/MenuBarContentView.swift)
  Menu-bar disclosure and key-validation surface.
- [docs/V1_SPEC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/V1_SPEC.md)
  Off-device disclosure requirements and backend expectations.

### Diagnostics, Logging, And Redaction
- [Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift)
  Local JSONL persistence, permissions, and rotation policy.
- [Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift)
  Persisted field schema for attempt records.
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift)
  Local reader for diagnostics content and failure summaries.
- [docs/USABILITY_CHECKLIST.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/USABILITY_CHECKLIST.md)
  Verification checklist including no raw transcript retention by default.
- [docs/EXECUTION_PLAN.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/EXECUTION_PLAN.md)
  Observability rules and diagnostics discipline.

### Packaging, Provenance, And Local Machine Trust
- [Scripts/build_app_bundle.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/build_app_bundle.sh)
  Release packaging, signing mode, hardened runtime, and failure behavior.
- [Scripts/verify_dist_app.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/verify_dist_app.sh)
  Signing identity verification and Gatekeeper assessment.
- [Scripts/setup_local_codesign_identity.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/setup_local_codesign_identity.sh)
  Creates and trusts a local code-signing identity in the login Keychain.
- [Scripts/install_app.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/install_app.sh)
  Installed-app flow that can affect the trusted runtime path in `/Applications`.
- [docs/LOCAL_RUNTIME.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/LOCAL_RUNTIME.md)
  Trusted bundle path and runtime identity discipline.
- [docs/SECURITY_RUBRIC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/SECURITY_RUBRIC.md)
  Release review gates, scores, and evidence expectations.

## Dave Workspace Ownership
- [README.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/README.md)
  Workspace entry point.
- [MEMORY.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/MEMORY.md)
  Durable security facts and working context.
- [AGENT_INSTRUCTIONS.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/AGENT_INSTRUCTIONS.md)
  Security operating rules.
- [RISK_REGISTER.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/RISK_REGISTER.md)
  Active risk queue.
- [THREAT_MODEL.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/THREAT_MODEL.md)
  Threat framing for the current product.
- [MACHINE_GUARDRAILS.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/MACHINE_GUARDRAILS.md)
  Machine-level trust and safety guardrails.
- [playbooks](/Users/worldbuilder/Desktop/Head%20Canon/Dave/playbooks)
  Security review playbooks.
- [bin/security_inventory.sh](/Users/worldbuilder/Desktop/Head%20Canon/Dave/bin/security_inventory.sh)
  Helper script to regenerate a search-based security surface snapshot.
- [logs](/Users/worldbuilder/Desktop/Head%20Canon/Dave/logs)
  Evidence, checkpoints, and findings.
