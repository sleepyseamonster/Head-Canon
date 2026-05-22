date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: transcription-fatigue-audit

# Latency Snapshot

Captured: `2026-05-22T06:30:02-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: FDD21E1A-A14F-4644-BBF8-2A2D5F7F2A39
Completed: May 22, 2026 at 6:25:59 AM
State: timedOut
Truth State: transcriptionTimedOut
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 30081 ms
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
Failure Stage: transcription
Failure Message: Head Canon stopped waiting for transcription after 30 seconds.
```

## Live State
Command:
```bash
swift Scripts/diagnostics.swift live
```

Observed:
```text
Updated: May 22, 2026 at 6:30:01 AM
Session: 28ECE838-ECED-411B-AFE3-2D376C54A768
Current Attempt: None
Workflow: Ready (ready)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: transcription
Last Truth State: transcriptionTimedOut
Last Error: None
Recording Started: 6:25:15 AM
Hotkey Released: 6:25:59 AM
Finalizing Shown: 6:25:29 AM
Recording Finalized: 6:25:29 AM
Transcription Started: 6:25:29 AM
Insertion Completed: Unknown
Stop Trigger: globalModifierMonitor
Last Event: Head Canon stopped waiting for transcription after 30 seconds.
Last Event Stage: transcription
Last Event Failed: Yes
Last Event At: 6:25:59 AM
Recent Events:
- 6:25:59 AM | transcription | failure | Head Canon stopped waiting for transcription after 30 seconds.
- 6:25:59 AM | hotkey | info | Observed hotkey release from Global Modifier Monitor without an active recording.
- 6:25:53 AM | hotkey | info | Ignored hotkey press because dictation processing is still in progress.
- 6:25:53 AM | hotkey | info | Observed hotkey press.
- 6:25:29 AM | transcription | info | Transcription request started with a 30 second timeout.
- 6:25:29 AM | recordingStop | info | Recording finalized via Modifier State Watchdog. Clip 14.21s · 143 KB. Starting transcription.
- 6:25:29 AM | hotkey | info | Hotkey released via Modifier State Watchdog. Moving into recording finalization.
- 6:25:15 AM | recordingStart | info | Recording started from the global hotkey.
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
Request -> Response p50: 1738 ms
Request -> Response p95: 30076 ms
Request -> Headers p50: 1286 ms
Request -> Headers p95: 1993 ms
Release -> Inserted p50: 2225 ms
Release -> Inserted p95: 9515 ms
Transcript Characters p50: 104
Transcript Characters p95: 224
Transcript Words p50: 19
Transcript Words p95: 39
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
  Attempts: 44
  Verified Inserts: 4
  Unverified Inserts: 40
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1260 ms
  Request -> Response p95: 8940 ms
  Request -> Headers p50: 1073 ms
  Request -> Headers p95: 2164 ms
  Release -> Inserted p50: 1912 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 69
  Transcript Characters p95: 224
  Transcript Words p50: 13
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
  Attempts: 49
  Verified Inserts: 4
  Unverified Inserts: 40
  Failures: 5
  Streaming Fallbacks: 0
  Request -> Response p50: 1276 ms
  Request -> Response p95: 21301 ms
  Request -> Headers p50: 1073 ms
  Request -> Headers p95: 2164 ms
  Release -> Inserted p50: 1912 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 69
  Transcript Characters p95: 224
  Transcript Words p50: 13
  Transcript Words p95: 38
Unknown
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
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
recordingFailed
  Attempts: 2
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 2
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
6:10:08 AM | unverifiedInsert | req 1872 ms | hdr 1837 ms | total 2500 ms | chars 74 | Codex | Codex | appClipboardPaste | net -
6:10:25 AM | transcriptionFailed | req 1315 ms | hdr 1286 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:11:23 AM | unverifiedInsert | req 1738 ms | hdr 1700 ms | total 2303 ms | chars 8 | Codex | Codex | appClipboardPaste | net -
6:21:17 AM | unverifiedInsert | req 2037 ms | hdr 1993 ms | total 2609 ms | chars 153 | Codex | Codex | appClipboardPaste | net -
6:21:34 AM | unverifiedInsert | req 1828 ms | hdr 1791 ms | total 2418 ms | chars 107 | Codex | Codex | appClipboardPaste | net -
6:21:50 AM | unverifiedInsert | req 1276 ms | hdr 1243 ms | total 1867 ms | chars 18 | Codex | Codex | appClipboardPaste | net -
6:21:55 AM | unverifiedInsert | req 909 ms | hdr 867 ms | total 1502 ms | chars 15 | Codex | Codex | appClipboardPaste | net -
6:22:30 AM | unverifiedInsert | req 1487 ms | hdr 1452 ms | total 2061 ms | chars 185 | Codex | Codex | appClipboardPaste | net -
6:25:07 AM | transcriptionTimedOut | req 30076 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:25:59 AM | transcriptionTimedOut | req 30081 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
```
