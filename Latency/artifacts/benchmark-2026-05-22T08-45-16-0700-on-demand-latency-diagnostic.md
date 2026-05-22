date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: on-demand-latency-diagnostic

# Latency Snapshot

Captured: `2026-05-22T08:45:16-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: BAF300AA-86A4-4BDC-91B2-39567D3C14DD
Completed: May 22, 2026 at 8:44:55 AM
State: failed
Truth State: recordingFailed
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: Unknown
Release -> Inserted: Unknown
Transcript Characters: Unknown
Transcript Words: Unknown
Backend: Unknown
Mode: Unknown
Fallback: No
HTTP Status: Unknown
Request ID: Unknown
OpenAI Processing: Unknown
Content Type: Unknown
Response Headers Received: Unknown
Transport Failure Stage: Unknown
Network Error Domain: Unknown
Network Error Code: Unknown
Network Error Code Name: Unknown
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
Failure Stage: recordingStop
Failure Message: Disk Full
```

## Live State
Command:
```bash
swift Scripts/diagnostics.swift live
```

Observed:
```text
Updated: May 22, 2026 at 8:44:55 AM
Session: A6CFD72F-2159-4939-99D8-8520352EA024
Current Attempt: None
Workflow: Needs Attention (failed)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: Yes
Active Transcription: None
Last Failure Stage: recordingStop
Last Truth State: recordingFailed
Last Error: Disk Full
Recording Started: 8:44:54 AM
Hotkey Released: Unknown
Finalizing Shown: Unknown
Recording Finalized: Unknown
Transcription Started: Unknown
Insertion Completed: Unknown
Stop Trigger: Unknown
Last Event: Disk Full
Last Event Stage: recordingStop
Last Event Failed: Yes
Last Event At: 8:44:55 AM
Recent Events:
- 8:44:55 AM | recordingStop | failure | Disk Full
- 8:44:54 AM | recordingStart | info | Recording started from the global hotkey.
- 8:44:54 AM | hotkey | info | Observed hotkey press.
- 8:44:46 AM | recordingStop | failure | Disk Full
- 8:44:46 AM | recordingStart | info | Recording started from the global hotkey.
- 8:44:46 AM | hotkey | info | Observed hotkey press.
- 8:44:42 AM | recordingStop | failure | Disk Full
- 8:44:42 AM | recordingStart | info | Recording started from the global hotkey.
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
Unverified Inserts: 14
Failures: 6
Streaming Fallbacks: 0
Request -> Response p50: 1514 ms
Request -> Response p95: 2489 ms
Request -> Headers p50: 1477 ms
Request -> Headers p95: 2451 ms
Release -> Inserted p50: 2110 ms
Release -> Inserted p95: 3076 ms
Transcript Characters p50: 108
Transcript Characters p95: 240
Transcript Words p50: 19
Transcript Words p95: 45
```

## Recent 50 Summary By Model
Command:
```bash
swift Scripts/diagnostics.swift summary-by-model 50
```

Observed:
```text
Unknown
  Attempts: 6
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 6
  Streaming Fallbacks: 0
  Request -> Response p50: Unknown
  Request -> Response p95: Unknown
  Request -> Headers p50: Unknown
  Request -> Headers p95: Unknown
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 44
  Verified Inserts: 0
  Unverified Inserts: 44
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1493 ms
  Request -> Response p95: 2792 ms
  Request -> Headers p50: 1461 ms
  Request -> Headers p95: 2752 ms
  Release -> Inserted p50: 2074 ms
  Release -> Inserted p95: 3412 ms
  Transcript Characters p50: 49
  Transcript Characters p95: 240
  Transcript Words p50: 9
  Transcript Words p95: 45
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
  Unverified Inserts: 44
  Failures: 6
  Streaming Fallbacks: 0
  Request -> Response p50: 1493 ms
  Request -> Response p95: 2792 ms
  Request -> Headers p50: 1461 ms
  Request -> Headers p95: 2752 ms
  Release -> Inserted p50: 2074 ms
  Release -> Inserted p95: 3412 ms
  Transcript Characters p50: 49
  Transcript Characters p95: 240
  Transcript Words p50: 9
  Transcript Words p95: 45
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
recordingFailed
  Attempts: 6
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 6
  Streaming Fallbacks: 0
  Request -> Response p50: Unknown
  Request -> Response p95: Unknown
  Request -> Headers p50: Unknown
  Request -> Headers p95: Unknown
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
8:42:54 AM | unverifiedInsert | req 1429 ms | hdr 1392 ms | total 2096 ms | chars 240 | Codex | Codex | appClipboardPaste | net -
8:43:28 AM | unverifiedInsert | req 1417 ms | hdr 1378 ms | total 2000 ms | chars 108 | Codex | Codex | appClipboardPaste | net -
8:43:44 AM | unverifiedInsert | req 1304 ms | hdr 1233 ms | total 1938 ms | chars 53 | Codex | Codex | appClipboardPaste | net -
8:44:20 AM | unverifiedInsert | req 1630 ms | hdr 1595 ms | total 2211 ms | chars 118 | Codex | Codex | appClipboardPaste | net -
8:44:37 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:40 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:40 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:42 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:46 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:55 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
```
