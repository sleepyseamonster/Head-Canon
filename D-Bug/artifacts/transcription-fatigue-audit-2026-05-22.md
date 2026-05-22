date: 2026-05-22
status: complete
owner: D-Bug
scope: installed app diagnostics, latency snapshot, macOS unified logs, transcription backend

# Transcription Fatigue Audit

## User Symptom
- After roughly 10 or more dictation turns, recording and transcription appear to stop working.
- The app can look like it is recording or blocked, but no new transcript arrives.

## Commands Run
```bash
./Scripts/diagnostics.swift live
./Scripts/diagnostics.swift recent 80
./Scripts/diagnostics.swift summary 120
./Scripts/diagnostics.swift summary-by-failure 120
./Scripts/diagnostics.swift summary-by-model 120
./Scripts/diagnostics.swift summary-by-app-class 120
./Latency/bin/capture_latency_snapshot.sh transcription-fatigue-audit
/usr/bin/log show --style compact --last 3h --predicate 'process == "HeadCanon"'
lsof -p 31873
swift test
./Scripts/build_app_bundle.sh
./Scripts/install_dist_app.sh
```

## Key Evidence
- Live diagnostics before the fix showed `Workflow: Needs Attention (failed)`, `Audio Capture Recording: No`, and `Last Truth State: transcriptionTimedOut`.
- The last two attempts timed out at about `30076 ms` and `30081 ms`, both after recording had already finalized and transcription had started.
- Recent history showed normal successful attempts followed by long hosted transcription requests and then 30 second timeouts.
- `summary 120` showed `Request -> Response p95: 23051 ms`; `summary-by-failure 120` showed `5` `transcriptionTimedOut` attempts clustered at about `30.1 s`.
- The final failed attempts had valid audio metadata:
  - `30.105 s`, `266502 bytes`
  - `14.214 s`, `142660 bytes`
- `lsof` showed no active `.m4a` recording file at the time of audit, which argues against an ongoing microphone capture hang.
- macOS logs at the timeout showed CFNetwork reusing `Connection 23` for the transcription request, then reporting a 30 second task failure with `response_status=200`, `reused=1`, `response_bytes=0`.
- Shortly after, macOS network logs reported QUIC blackhole detection and repeated `Operation timed out` reads for the same connection.

## Root Cause
Highest-confidence root cause: the standard completed-recording transcription path was using a long-lived `URLSession`, allowing CFNetwork to reuse a stale QUIC/HTTP3 connection after many requests. When that transport path degraded, the audio clip had already finalized, but the transcription request hung until Head Canon's app-level 30 second timeout fired.

This explains the "after every 10 or so transcriptions" pattern better than an audio-capture leak:
- the audio graph was not still recording
- clip sizes and durations were present
- timeouts happened after transcription request start
- the system log pointed directly at reused network transport failure

## Secondary Bugs Found
- Late physical hotkey releases after watchdog finalization could overwrite the original stop trigger and release timestamp, producing negative timing values such as `releaseToFinalizedDurationMS: -29421`.
- Live diagnostics could show a ghost `activeTranscriptionAttemptID` after a failed terminal state because live-state writes were launched asynchronously and could land out of order.
- Codex insertion remains mostly `unverifiedInsert` because app-level paste into an opaque editor has no reliable AX readback; that is separate from this transcription timeout root cause.

## Fix Applied
- Changed standard bounded transcription POSTs to use a fresh per-request `URLSession`.
- Invalidated the per-request session after each transcription to avoid keeping stale CFNetwork transport state alive across many dictation turns.
- Kept bounded dictation on `Standard Completed Recording`; streaming remains off the active path.
- Disabled URL cache use for transcription sessions and limited per-host connection count to reduce stale transport reuse.
- Stopped late non-recording hotkey-release events from mutating the previous attempt's release timing.
- Serialized live diagnostics writes so cleanup state is not overwritten by older async live-state writes.

## Verification
- `swift test` passed with `94` tests.
- Built and installed `/Applications/HeadCanon.app`.
- Installed app signing:
  - authority: `HeadCanon Local Signing`
  - timestamp: `May 22, 2026 at 6:38:50 AM`
  - CDHash: `649008ef7d45f7182ba4171cfef3d823caa36c9b`
- Post-install live diagnostics:
  - initially `Workflow: Ready (ready)`
  - `Ready: Yes`
  - `Audio Capture Recording: No`
  - `Hotkey Physically Pressed: No`
  - `Active Transcription: None`
- Fresh post-install attempts at `6:39 AM` and `6:40 AM` succeeded through transcription and insertion classification:
  - latest `request -> response`: `2594 ms`
  - latest `release -> inserted`: `3132 ms`
  - latest truth state: `unverifiedInsert`
  - backend: `openai.gpt-4o-mini-transcribe`
  - request mode: `Standard Completed Recording`
- Follow-up snapshot saved at `Latency/artifacts/benchmark-2026-05-22T06-40-34-0700-post-cleanup-live-check.md`.
- Continued audit through `6:45 AM` found `11` post-install completed attempts:
  - failures: `0`
  - request p50: `1647 ms`
  - request p95: `3524 ms`
  - all request modes: `Standard Completed Recording`
  - all truth states: `unverifiedInsert`
- Post-install CFNetwork logs for pid `16531` showed each transcription using a new connection (`1`, `3`, `5`, `7`, `9`, `11`, `13` observed), succeeding, then cleaning up the connection. No post-fix blackhole or operation-timeout entries were observed in the checked window.
- Additional snapshot saved at `Latency/artifacts/benchmark-2026-05-22T06-45-33-0700-post-fix-11-turn-audit.md`.

## Remaining Risk
- A longer real repeated-dictation soak beyond the first `11` post-install attempts is still useful.
- If timeouts continue, the next likely fixes are automatic one-time retry after app-level timeout and explicit HTTP/3 avoidance if Foundation exposes a stable control for this target.
- Insertion verification in Codex remains a separate reliability track.
- A harmless-but-noisy release race remains: the recording release watchdog can finalize first, then the normal global release arrives milliseconds later and logs `without an active recording`.
- The `30 s` recording duration safety fuse can finalize intentionally long dictation turns; this is safer than getting stuck, but may need clearer UI copy if the user expects longer hold-to-talk sessions.
