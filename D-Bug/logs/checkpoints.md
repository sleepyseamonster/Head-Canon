# D-Bug Checkpoints

## 2026-05-21
- Audited the repo and existing agent folders.
- Confirmed `swift test` passes locally.
- Confirmed installed-app diagnostics currently show insertion-stage failures as the dominant live issue.
- Confirmed additional planner and tooling drift:
  - app-only opaque routes can be planned before real focused-target evidence exists
  - strong AX opaque editors are intentionally kept off direct insertion
  - the focused-target analyzer script is more optimistic than runtime behavior
  - current planner tests encode some of the paste-oriented routing now under suspicion
- Implemented first-pass runtime fixes:
  - app-level paste no longer self-blocks purely because AX focus metadata is unavailable
  - offline and DNS transcription failures now fail fast instead of retrying
  - runtime and analyzer strategy descriptions were updated to match the new app-level paste behavior
- Re-ran `swift test`; all `77` tests passed on 2026-05-21.
- Captured a fresh installed-app baseline artifact in [installed-app-baseline-2026-05-21.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/artifacts/installed-app-baseline-2026-05-21.md).
- Aligned app-only context modeling so known opaque apps no longer claim a focused editable field when none was actually observed.
- Fixed the diagnostics summary helper to recognize `nativeAXStrong` correctly.
- Added focused equivalence hardening for known opaque text targets:
  - stable DOM or AX identifiers still preserve identity
  - conflicting stable identifiers still block equivalence
  - weak text-target fallback only applies when the app is classified as an opaque editor
- Added regression tests for focus identity churn and weak-equivalence boundaries.
- Installed the updated signed app bundle to `/Applications/HeadCanon.app`.
- Verified the installed bundle is signed by `HeadCanon Local Signing` with timestamp `2026-05-21 17:36:30 -0700`.
- After user reported transcripts appeared in the interface but not consistently in text boxes, diagnosed app-level paste as a likely false-positive path:
  - `appClipboardPaste` had no AX readback when app-only context was used
  - paste was sent with `postToPid`
  - clipboard restoration happened after only `120 ms`
- Updated app-level paste to:
  - send Cmd+V through the frontmost HID event tap while the target app remains frontmost
  - keep the clipboard injected for `450 ms` before restoration on true app-level paste
- Re-ran `swift test`; all `82` tests passed on 2026-05-21.
- Reinstalled the updated signed app bundle to `/Applications/HeadCanon.app`.
- Verified the installed bundle is signed by `HeadCanon Local Signing` with timestamp `2026-05-21 17:42:01 -0700`.

Audit:
- Repo health is better than app health.
- The installed app appears to be failing mainly after successful transcription, especially in `Codex`.
- The next pass must change routing behavior and tests together, or the suite will preserve the regression.
- The codebase now reflects the first safety-preserving runtime fix, but installed-app validation in `Codex` is still outstanding.
- Runtime and repo-local tooling are closer together now, but the remaining uncertainty is still real installed-app behavior after the new app-only paste change.
- Automated verification is complete through unit tests, diagnostics tooling, signing inspection, and installation.
- A fresh spoken `Codex` dictation turn still requires interactive input; no post-install attempt has been recorded yet.
- The most important next signal is whether the new frontmost paste plus longer clipboard hold makes the transcript land in the real text box, not merely whether diagnostics reports `inserted`.

Next steps:
- run a post-install `Codex` dictation turn and compare the resulting diagnostics against the saved baseline
- if insertion still fails, classify whether it is paste dispatch, paste verification, or a genuine focus change

## 2026-05-21 18:06 -0700
- User reported transcription was no longer working at all.
- Audited installed-app diagnostics:
  - latest two attempts timed out in `transcription`
  - both stopped at the app-level 30-second timeout
  - previous successful attempts used `Standard Completed Recording` with streaming fallback metadata
- Identified the active risk in `OpenAIBoundedTranscriptionBackend`:
  - bounded dictation attempted streaming first
  - fallback to standard transcription only ran when streaming failed quickly
  - a hanging streaming preflight consumed the app timeout before fallback could execute
- Changed bounded transcription to call standard completed-recording transcription directly.
- Added a regression test that captures the outbound request and asserts:
  - one request is sent
  - `Accept` is `text/plain`
  - multipart body omits `stream`
  - metadata reports `Standard Completed Recording`
  - `fellBackFromStreaming` is false
- Re-ran `swift test`; all `83` tests passed.
- Built and signed a fresh distribution bundle.
- `install_app.sh` still failed only at local Gatekeeper assessment for the self-signed bundle.
- Installed the fresh signed bundle with `install_dist_app.sh`.
- Verified `/Applications/HeadCanon.app`:
  - authority `HeadCanon Local Signing`
  - timestamp `2026-05-21 18:05:57 -0700`
  - CDHash `0f1d3a9564ee20de0e80b17c0a4014086b94efd4`
  - running process started at `2026-05-21 18:06:01 -0700`

Audit:
- This addresses the immediate transcription outage without changing the insertion route.
- The fix aligns runtime behavior with the documented current checkpoint: bounded dictation should use standard completed-recording transcription.
- Streaming helper code remains present but is no longer on the active bounded dictation path.
- The remaining live risk is now back to `Codex` text-box insertion consistency after transcription succeeds.

Next steps:
- Run a fresh installed-app dictation attempt in `Codex`.
- If transcription succeeds but text still does not land in the text box, continue with paste verification and app-level insertion diagnostics.
