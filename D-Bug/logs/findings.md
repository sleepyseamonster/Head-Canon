# D-Bug Findings

## 2026-05-21
- Recent installed-app evidence shows `Codex` failures are primarily insertion-stage, not transcription-stage.
- There is a recent strategy shift from `customEditorPaste` attempts to `appClipboardPaste` attempts in `Codex`.
- The current app-only paste safety path appears capable of blocking insertion by design when no stable focused AX text target can be recovered.
- Strong AX targets in opaque apps are still intentionally routed away from direct insertion, increasing dependence on brittle paste paths.
- App-only context modeling currently infers editability from app classification alone for known opaque editors.
- `Scripts/analyze_focused_target.swift` does not fully model the runtime safety gates, so its predicted route can be more optimistic than the app's real behavior.
- Some unit tests currently assert the paste-oriented routing behavior for strong AX opaque editors, so test updates will need to land with planner changes.
- First implementation pass changed the app-only paste behavior so lack of AX focus metadata now skips focused cleanup instead of blocking the route outright.
- First implementation pass also removed retry-once behavior for offline and DNS transcription failures.
- Runtime app-only capability modeling now reports `editable: false` when no focused field evidence exists, while still allowing the bounded app-level paste route for known opaque editors.
- Focus-equivalence hardening now allows known opaque text targets to survive AX object identity churn when there are no conflicting stable identifiers.
- The updated signed app bundle has been installed at `/Applications/HeadCanon.app`, but no post-install spoken dictation attempt has been captured yet.
- Later diagnostics showed a separate transcription-stage outage: the active bounded backend could hang in a streaming preflight long enough for the app-level 30-second timeout to fire before standard fallback ran.
- Bounded dictation now uses standard completed-recording transcription directly; streaming should not return to this path without explicit timeout isolation and installed-app diagnostics.
