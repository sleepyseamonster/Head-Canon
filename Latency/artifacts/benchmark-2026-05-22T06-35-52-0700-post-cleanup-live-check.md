date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: post-cleanup-live-check

# Latency Snapshot

Captured: `2026-05-22T06:35:52-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: C529FC3D-BCB1-4A42-8EB4-A907F0F5BC01
Completed: May 22, 2026 at 6:35:26 AM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 913 ms
Release -> Inserted: 1685 ms
Transcript Characters: 23
Transcript Words: 5
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_60b32201d32143c690f003a447505653
OpenAI Processing: 661 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 876 ms
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
Updated: May 22, 2026 at 6:35:26 AM
Session: 28ECE838-ECED-411B-AFE3-2D376C54A768
Current Attempt: C529FC3D-BCB1-4A42-8EB4-A907F0F5BC01
Workflow: Inserted (inserted)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: 6C70DB48-893F-43B4-AD0D-80DEB5F02A26
Last Failure Stage: transcription
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 6:35:22 AM
Hotkey Released: 6:35:24 AM
Finalizing Shown: 6:35:24 AM
Recording Finalized: 6:35:24 AM
Transcription Started: 6:35:24 AM
Insertion Completed: 6:35:26 AM
Stop Trigger: globalModifierMonitor
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 6:35:26 AM
Recent Events:
- 6:35:26 AM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 6:35:25 AM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 23 chars · 5 words from 2.46s.
- 6:35:24 AM | transcription | info | Transcription request started with a 30 second timeout.
- 6:35:24 AM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 2.46s · 50 KB. Starting transcription.
- 6:35:24 AM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 6:35:24 AM | hotkey | info | Hotkey released via Recording Release Watchdog. Moving into recording finalization.
- 6:35:24 AM | recordingStop | info | Recording release watchdog observed the hotkey is no longer physically pressed. Finalizing automatically.
- 6:35:22 AM | recordingStart | info | Recording started from the global hotkey.
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
Request -> Headers p95: 1837 ms
Release -> Inserted p50: 2225 ms
Release -> Inserted p95: 9515 ms
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
  Verified Inserts: 2
  Unverified Inserts: 42
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1276 ms
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
  Verified Inserts: 2
  Unverified Inserts: 42
  Failures: 5
  Streaming Fallbacks: 0
  Request -> Response p50: 1315 ms
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
6:11:23 AM | unverifiedInsert | req 1738 ms | hdr 1700 ms | total 2303 ms | chars 8 | Codex | Codex | appClipboardPaste | net -
6:21:17 AM | unverifiedInsert | req 2037 ms | hdr 1993 ms | total 2609 ms | chars 153 | Codex | Codex | appClipboardPaste | net -
6:21:34 AM | unverifiedInsert | req 1828 ms | hdr 1791 ms | total 2418 ms | chars 107 | Codex | Codex | appClipboardPaste | net -
6:21:50 AM | unverifiedInsert | req 1276 ms | hdr 1243 ms | total 1867 ms | chars 18 | Codex | Codex | appClipboardPaste | net -
6:21:55 AM | unverifiedInsert | req 909 ms | hdr 867 ms | total 1502 ms | chars 15 | Codex | Codex | appClipboardPaste | net -
6:22:30 AM | unverifiedInsert | req 1487 ms | hdr 1452 ms | total 2061 ms | chars 185 | Codex | Codex | appClipboardPaste | net -
6:25:07 AM | transcriptionTimedOut | req 30076 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:25:59 AM | transcriptionTimedOut | req 30081 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:34:51 AM | unverifiedInsert | req 1857 ms | hdr 1821 ms | total 2423 ms | chars 13 | Codex | Codex | appClipboardPaste | net -
6:35:26 AM | unverifiedInsert | req 913 ms | hdr 876 ms | total 1685 ms | chars 23 | Codex | Codex | appClipboardPaste | net -
```
