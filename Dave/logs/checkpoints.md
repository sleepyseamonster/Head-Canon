# Dave Checkpoints

## 2026-05-21
- Workspace created.
- Initial observed security scope documented from current source layout.
- Next step: review clipboard fallback, diagnostics retention, and hosted-transcription disclosure for v1.

## 2026-05-21 Security Workspace Organization Checkpoint
- Work completed:
  - added a repo-wide security inventory
  - added a threat model and risk register
  - added playbooks for clipboard, diagnostics, and release-trust review
  - added local-machine guardrails for Keychain, TCC, signing, and installed-app handling
- Audit:
  - security ownership is now centralized in `Dave/` without moving working source files out of their normal build locations
  - the workspace now covers app code, runtime scripts, release verification, and machine-trust procedures
  - no code behavior changed yet, so app security posture is better organized but not yet materially hardened
- Next recommended steps:
  - review clipboard fallback against the existing spec promise to preserve and restore clipboard contents
  - verify diagnostics redaction against actual persisted JSON fields
  - review local code-signing identity setup for least-surprising machine impact before treating it as the default trusted path
