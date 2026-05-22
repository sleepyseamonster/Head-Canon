date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: post-cleanup-live-check

# Latency Snapshot

Captured: `2026-05-22T06:40:34-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 6F19BAF4-53F3-4966-BFE7-6ADC13A6B791
Completed: May 22, 2026 at 6:40:14 AM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 2594 ms
Release -> Inserted: 3132 ms
Transcript Characters: 93
Transcript Words: 16
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_0b6a370d11624f138822957be1c4cba0
OpenAI Processing: 1306 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 2561 ms
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
```

## Live State
Command:
```bash
swift Scripts/diagnostics.swift live
```

Observed:
```text
Updated: May 22, 2026 at 6:40:14 AM
Session: 225B23E3-7C48-4F3A-AB46-CE0E2D3C85E5
Current Attempt: None
Workflow: Inserted (inserted)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: None
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 6:39:55 AM
Hotkey Released: 6:40:11 AM
Finalizing Shown: 6:40:11 AM
Recording Finalized: 6:40:11 AM
Transcription Started: 6:40:11 AM
Insertion Completed: 6:40:14 AM
Stop Trigger: globalModifierMonitor
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 6:40:14 AM
Recent Events:
- 6:40:14 AM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 6:40:13 AM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 93 chars · 16 words from 15.42s.
- 6:40:11 AM | transcription | info | Transcription request started with a 30 second timeout.
- 6:40:11 AM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 15.42s · 152 KB. Starting transcription.
- 6:40:11 AM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 6:39:55 AM | recordingStart | info | Recording started from the global hotkey.
- 6:39:55 AM | hotkey | info | Observed hotkey press.
- 6:39:36 AM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
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
Unverified Inserts: 17
Failures: 3
Streaming Fallbacks: 0
Request -> Response p50: 1769 ms
Request -> Response p95: 30076 ms
Request -> Headers p50: 1594 ms
Request -> Headers p95: 1993 ms
Release -> Inserted p50: 2324 ms
Release -> Inserted p95: 3132 ms
Transcript Characters p50: 74
Transcript Characters p95: 185
Transcript Words p50: 14
Transcript Words p95: 32
```

## Recent 50 Summary By Model
Command:
```bash
swift Scripts/diagnostics.swift summary-by-model 50
```

Observed:
```text
Unknown
  Attempts: 5
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 5
  Streaming Fallbacks: 0
  Request -> Response p50: 30076 ms
  Request -> Response p95: 30081 ms
  Request -> Headers p50: 1286 ms
  Request -> Headers p95: 1286 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 45
  Verified Inserts: 0
  Unverified Inserts: 45
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1276 ms
  Request -> Response p95: 8940 ms
  Request -> Headers p50: 1073 ms
  Request -> Headers p95: 1993 ms
  Release -> Inserted p50: 1912 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 59
  Transcript Characters p95: 224
  Transcript Words p50: 12
  Transcript Words p95: 38
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
  Unverified Inserts: 45
  Failures: 5
  Streaming Fallbacks: 0
  Request -> Response p50: 1315 ms
  Request -> Response p95: 21301 ms
  Request -> Headers p50: 1073 ms
  Request -> Headers p95: 1993 ms
  Release -> Inserted p50: 1912 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 59
  Transcript Characters p95: 224
  Transcript Words p50: 12
  Transcript Words p95: 38
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
recordingFailed
  Attempts: 1
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 1
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
transcriptionFailed
  Attempts: 2
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 2
  Streaming Fallbacks: 0
  Request -> Response p50: 1315 ms
  Request -> Response p95: 1315 ms
  Request -> Headers p50: 1286 ms
  Request -> Headers p95: 1286 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
transcriptionTimedOut
  Attempts: 2
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 2
  Streaming Fallbacks: 0
  Request -> Response p50: 30081 ms
  Request -> Response p95: 30081 ms
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
6:21:55 AM | unverifiedInsert | req 909 ms | hdr 867 ms | total 1502 ms | chars 15 | Codex | Codex | appClipboardPaste | net -
6:22:30 AM | unverifiedInsert | req 1487 ms | hdr 1452 ms | total 2061 ms | chars 185 | Codex | Codex | appClipboardPaste | net -
6:25:07 AM | transcriptionTimedOut | req 30076 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:25:59 AM | transcriptionTimedOut | req 30081 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:34:51 AM | unverifiedInsert | req 1857 ms | hdr 1821 ms | total 2423 ms | chars 13 | Codex | Codex | appClipboardPaste | net -
6:35:26 AM | unverifiedInsert | req 913 ms | hdr 876 ms | total 1685 ms | chars 23 | Codex | Codex | appClipboardPaste | net -
6:37:03 AM | unverifiedInsert | req 1779 ms | hdr 1744 ms | total 2345 ms | chars 23 | Codex | Codex | appClipboardPaste | net -
6:39:14 AM | unverifiedInsert | req 1595 ms | hdr 1549 ms | total 2747 ms | chars 39 | Codex | Codex | appClipboardPaste | net -
6:39:36 AM | unverifiedInsert | req 1616 ms | hdr 1581 ms | total 2200 ms | chars 51 | Codex | Codex | appClipboardPaste | net -
6:40:14 AM | unverifiedInsert | req 2594 ms | hdr 2561 ms | total 3132 ms | chars 93 | Codex | Codex | appClipboardPaste | net -
```
