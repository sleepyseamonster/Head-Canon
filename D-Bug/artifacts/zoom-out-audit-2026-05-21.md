date: 2026-05-21
status: audit
owner: D-Bug
scope: whole repo reliability after stuck-recording fixes

# Zoom-Out Reliability Audit

## Installed App State
- Target app: `/Applications/HeadCanon.app`
- Running pid: `31873`
- Launch time: `2026-05-21 19:39:44 -0700`
- CDHash: `77604e4317dc70fa061f0aa1e3e2de747dca700c`
- Signing authority: `HeadCanon Local Signing`

## Diagnostics Snapshot
- `Scripts/diagnostics.swift live` showed the current app can report live state.
- A recent fresh attempt completed:
  - state: `inserted`
  - truth state: `unverifiedInsert`
  - app: `Codex`
  - request -> response: `1567 ms`
  - release -> inserted: `2237 ms`
  - backend: `openai.gpt-4o-mini-transcribe`
  - mode: `Standard Completed Recording`
  - stop trigger: `globalModifierMonitor`
  - insertion strategy: `appClipboardPaste`
  - verification: `unverified`
- The bottom-right overlay was visible briefly after insertion, then dismissed after its normal timeout.
- No active temp recording file remained.
- Physical hotkey state reported not pressed.

## Highest-Risk Findings

### P0: No Current P0 Recording/Transcription Blocker Observed
- Recent attempts completed recording, finalization, transcription, insertion attempt, and persistence.
- The previous stuck-recording root split now has:
  - live-state diagnostics
  - audio unexpected-completion reconciliation
  - stale recording cleanup
  - manual finalize/cancel controls
- Current evidence does not show the app stuck in `.recording`.

### P1: Codex Insertion Is Still Not Strong Enough
- Recent Codex attempts are `unverifiedInsert`.
- Persisted records show:
  - context kind: `appOnly`
  - target: `Unknown`
  - `valueReadable: false`
  - `selectedTextRangeReadable: false`
  - strategy: `appClipboardPaste`
  - verification outcome: `unverified`
- This means Head Canon cannot prove whether text landed in the text box.
- It also means user reports of "transcription appears in UI but not in text box" remain plausible even when the app records `inserted`.

### P1: App-Only Paste Path Needs Better Evidence
- The current `appClipboardPaste` path is intentionally conservative and works when the frontmost app is correct.
- For opaque apps like Codex, AX focus can be unavailable or unreadable, so verification often becomes impossible.
- The app needs a second proof mechanism for app-only paste:
  - observe focused app before and after
  - capture pasteboard ownership/change timing
  - optionally retain a visible retry/copy action for unverified inserts
  - use a focused-target analyzer from the actual target context, not from Codex's own current thread when focus is ambiguous

### P2: Active Transcription ID Can Remain Visible In Live State After Insert
- A live snapshot showed `workflowStatus == inserted` while `activeTranscriptionAttemptID` still had a UUID.
- This is likely because `transcribeAndInsert` clears it in `defer` after setting inserted and persisting live state.
- Impact is diagnostic confusion, not observed product breakage.
- Fix: call `persistLiveState()` after `activeTranscriptionAttemptID` is cleared, or clear the ID before setting terminal workflow state.

### P2: Diagnostics Are Stronger But Need App-Matrix Discipline
- `latest` now captures terminal truth states, and `live` captures in-progress state.
- Remaining need: a repeatable matrix with TextEdit, Codex, browser textarea, Notes, terminal/TUI, secure field.
- Each scenario should capture:
  - `live`
  - `latest`
  - whether user visibly saw text in the target
  - target app and text-field context

## Aggregate Diagnostics
- Recent 30 attempts:
  - verified inserts: `19`
  - unverified inserts: `5`
  - failures: `6`
  - request -> response p50: `2280 ms`
  - release -> inserted p50: `2816 ms`
- Recent Codex records:
  - attempts: `47`
  - verified inserts: `23`
  - unverified inserts: `5`
  - failures: `19`

## Current Root-Cause Map
1. Recording stuck class:
   - Previously active.
   - Now mitigated with audio lifecycle reconciliation and live diagnostics.
2. Transcription timeout class:
   - Previously caused by streaming preflight.
   - Mitigated by standard completed-recording default.
3. Text insertion class:
   - Still active.
   - Main current risk is app-only paste into Codex with no verification readback.

## Recommended Next Fix Order
1. Fix diagnostic cleanup for `activeTranscriptionAttemptID` in terminal live-state snapshots.
2. Add a visible `Copy Last Transcript` button near recovery controls, because unverified inserts need fast manual recovery.
3. Strengthen app-only paste evidence:
   - record whether AX focus was unavailable vs unreadable vs app-only by design
   - persist paste verification failure reason, not only `unverified`
   - preserve current frontmost app name/pid before dispatch and after dispatch
4. Run the app/text-box matrix and classify each result.
5. Only after matrix evidence, decide whether Codex needs a custom insertion strategy beyond `appClipboardPaste`.

## Verification
- Ran `swift test`; all `93` tests passed.
