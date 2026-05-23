date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: post-instrumentation-live-diagnostic

# Latency Snapshot

Captured: `2026-05-22T19:38:01-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: F0778B73-66AB-4D1E-956E-A72D7C4FBC01
Completed: May 22, 2026 at 7:37:50 PM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 1351 ms
Release -> Inserted: 1979 ms
Transcript Characters: 42
Transcript Words: 9
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_c8432804bd1e4738b2966f26557d61e9
OpenAI Processing: 737 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1319 ms
Transport Failure Stage: Unknown
Network Error Domain: Unknown
Network Error Code: Unknown
Network Error Code Name: Unknown
Response Body Bytes: Unknown
Response Body UTF-8 Decodable: Unknown
Response Body Trimmed Characters: Unknown
Response Content Length: Unknown
Release-Time Target App: Codex
Release-Time Target: Unknown
Release-Time Planned Strategy: appClipboardPaste
Target App: Codex
Target: Unknown
Planned Strategy: appClipboardPaste
Applied Strategy: appClipboardPaste
Verification: unverified
Placeholder Present: No
Placeholder Likely Active: No
Placeholder Ambiguous Value: No
Placeholder Handling: noneNeeded
```

## Live State
Command:
```bash
swift Scripts/diagnostics.swift live
```

Observed:
```text
Updated: May 22, 2026 at 7:37:50 PM
Session: 43E0FA2D-9783-4AAD-91E4-05D2FBE1DB48
Current Attempt: None
Workflow: Inserted (inserted)
Ready: Yes
Disk Readiness: Healthy
Disk Free Space: 49.83 GB
Disk Reserve: Reserved
Disk Reserved Space: 2.15 GB
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: transcription
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 7:37:40 PM
Hotkey Released: 7:37:48 PM
Finalizing Shown: 7:37:48 PM
Recording Finalized: 7:37:48 PM
Transcription Started: 7:37:48 PM
Insertion Completed: 7:37:50 PM
Stop Trigger: modifierStateWatchdog
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 7:37:50 PM
Recent Events:
- 7:37:50 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 7:37:49 PM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 42 chars · 9 words from 7.76s.
- 7:37:48 PM | transcription | info | Transcription request started with a 30 second timeout.
- 7:37:48 PM | recordingStop | info | Recording finalized via Modifier State Watchdog. Clip 7.76s · 93 KB. Starting transcription.
- 7:37:48 PM | hotkey | info | Hotkey released via Modifier State Watchdog. Moving into recording finalization.
- 7:37:40 PM | recordingStart | info | Recording started from the global hotkey.
- 7:37:40 PM | hotkey | info | Observed hotkey press.
- 7:37:37 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
```

## Recent 20 Summary
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Verified Inserts: 0
Unverified Inserts: 18
Failures: 2
Streaming Fallbacks: 0
Request -> Response p50: 2171 ms
Request -> Response p95: 3418 ms
Request -> Headers p50: 2088 ms
Request -> Headers p95: 3381 ms
Release -> Inserted p50: 2781 ms
Release -> Inserted p95: 4071 ms
Transcript Characters p50: 110
Transcript Characters p95: 604
Transcript Words p50: 22
Transcript Words p95: 112
```

## Recent 50 Summary By Model
Command:
```bash
swift Scripts/diagnostics.swift summary-by-model 50
```

Observed:
```text
Unknown
  Attempts: 3
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 2926 ms
  Request -> Response p95: 3476 ms
  Request -> Headers p50: 1468 ms
  Request -> Headers p95: 1959 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 47
  Verified Inserts: 0
  Unverified Inserts: 47
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1866 ms
  Request -> Response p95: 3633 ms
  Request -> Headers p50: 1831 ms
  Request -> Headers p95: 3600 ms
  Release -> Inserted p50: 2505 ms
  Release -> Inserted p95: 4239 ms
  Transcript Characters p50: 56
  Transcript Characters p95: 441
  Transcript Words p50: 10
  Transcript Words p95: 84
```

## Recent 50 Summary By App Class
Command:
```bash
swift Scripts/diagnostics.swift summary-by-app-class 50
```

Observed:
```text
Codex
  Apps: Codex
  Attempts: 50
  Verified Inserts: 0
  Unverified Inserts: 47
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 1960 ms
  Request -> Response p95: 3633 ms
  Request -> Headers p50: 1831 ms
  Request -> Headers p95: 3600 ms
  Release -> Inserted p50: 2505 ms
  Release -> Inserted p95: 4239 ms
  Transcript Characters p50: 56
  Transcript Characters p95: 441
  Transcript Words p50: 10
  Transcript Words p95: 84
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
transcriptionFailed
  Attempts: 3
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 2926 ms
  Request -> Response p95: 3476 ms
  Request -> Headers p50: 1468 ms
  Request -> Headers p95: 1959 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
```

## Recent 10 Timeline
Command:
```bash
swift Scripts/diagnostics.swift recent 10
```

Observed:
```text
7:23:43 PM | unverifiedInsert | req 1365 ms | hdr 1333 ms | total 2006 ms | chars 33 | Codex | Codex | appClipboardPaste | net -
7:31:16 PM | unverifiedInsert | req 3418 ms | hdr 3381 ms | total 4071 ms | chars 635 | Codex | Codex | appClipboardPaste | net -
7:31:55 PM | unverifiedInsert | req 2124 ms | hdr 2088 ms | total 2759 ms | chars 327 | Codex | Codex | appClipboardPaste | net -
7:34:05 PM | unverifiedInsert | req 1584 ms | hdr 1545 ms | total 2216 ms | chars 65 | Codex | Codex | appClipboardPaste | net -
7:34:39 PM | unverifiedInsert | req 2437 ms | hdr 2401 ms | total 3082 ms | chars 215 | Codex | Codex | appClipboardPaste | net -
7:36:24 PM | unverifiedInsert | req 2664 ms | hdr 2627 ms | total 3316 ms | chars 441 | Codex | Codex | appClipboardPaste | net -
7:37:08 PM | unverifiedInsert | req 2838 ms | hdr 2803 ms | total 3444 ms | chars 251 | Codex | Codex | appClipboardPaste | net -
7:37:20 PM | transcriptionFailed | req 631 ms | hdr 594 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
7:37:37 PM | unverifiedInsert | req 1712 ms | hdr 1673 ms | total 2332 ms | chars 110 | Codex | Codex | appClipboardPaste | net -
7:37:50 PM | unverifiedInsert | req 1351 ms | hdr 1319 ms | total 1979 ms | chars 42 | Codex | Codex | appClipboardPaste | net -
```
