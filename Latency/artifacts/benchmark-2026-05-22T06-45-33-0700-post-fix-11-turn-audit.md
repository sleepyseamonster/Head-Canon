date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: post-fix-11-turn-audit

# Latency Snapshot

Captured: `2026-05-22T06:45:33-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: B3418284-D127-4208-ABC4-B92675FABD79
Completed: May 22, 2026 at 6:44:48 AM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 2872 ms
Release -> Inserted: 3649 ms
Transcript Characters: 76
Transcript Words: 13
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_20aea5b3bf3a4fc884747432da163758
OpenAI Processing: 909 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 2837 ms
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
Updated: May 22, 2026 at 6:44:48 AM
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
Recording Started: 6:44:38 AM
Hotkey Released: 6:44:45 AM
Finalizing Shown: 6:44:45 AM
Recording Finalized: 6:44:45 AM
Transcription Started: 6:44:45 AM
Insertion Completed: 6:44:48 AM
Stop Trigger: recordingReleaseWatchdog
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 6:44:48 AM
Recent Events:
- 6:44:48 AM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 6:44:48 AM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 76 chars · 13 words from 7.29s.
- 6:44:45 AM | transcription | info | Transcription request started with a 30 second timeout.
- 6:44:45 AM | recordingStop | info | Recording finalized via Recording Release Watchdog. Clip 7.29s · 90 KB. Starting transcription.
- 6:44:45 AM | hotkey | info | Observed hotkey release from Global Modifier Monitor without an active recording.
- 6:44:45 AM | hotkey | info | Hotkey released via Recording Release Watchdog. Moving into recording finalization.
- 6:44:45 AM | recordingStop | info | Recording release watchdog observed the hotkey is no longer physically pressed. Finalizing automatically.
- 6:44:38 AM | recordingStart | info | Recording started from the global hotkey.
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
Request -> Response p50: 1779 ms
Request -> Response p95: 30076 ms
Request -> Headers p50: 1616 ms
Request -> Headers p95: 2837 ms
Release -> Inserted p50: 2418 ms
Release -> Inserted p95: 3649 ms
Transcript Characters p50: 61
Transcript Characters p95: 153
Transcript Words p50: 10
Transcript Words p95: 28
```

## Recent 50 Summary By Model
Command:
```bash
swift Scripts/diagnostics.swift summary-by-model 50
```

Observed:
```text
Unknown
  Attempts: 4
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 4
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
  Attempts: 46
  Verified Inserts: 0
  Unverified Inserts: 46
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1579 ms
  Request -> Response p95: 8940 ms
  Request -> Headers p50: 1430 ms
  Request -> Headers p95: 2837 ms
  Release -> Inserted p50: 2185 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 74
  Transcript Characters p95: 224
  Transcript Words p50: 14
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
  Unverified Inserts: 46
  Failures: 4
  Streaming Fallbacks: 0
  Request -> Response p50: 1579 ms
  Request -> Response p95: 21301 ms
  Request -> Headers p50: 1286 ms
  Request -> Headers p95: 2837 ms
  Release -> Inserted p50: 2185 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 74
  Transcript Characters p95: 224
  Transcript Words p50: 14
  Transcript Words p95: 38
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
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
6:39:36 AM | unverifiedInsert | req 1616 ms | hdr 1581 ms | total 2200 ms | chars 51 | Codex | Codex | appClipboardPaste | net -
6:40:14 AM | unverifiedInsert | req 2594 ms | hdr 2561 ms | total 3132 ms | chars 93 | Codex | Codex | appClipboardPaste | net -
6:41:10 AM | unverifiedInsert | req 1604 ms | hdr 1568 ms | total 2173 ms | chars 50 | Codex | Codex | appClipboardPaste | net -
6:41:57 AM | unverifiedInsert | req 1498 ms | hdr 1462 ms | total 2087 ms | chars 61 | Codex | Codex | appClipboardPaste | net -
6:42:14 AM | unverifiedInsert | req 2142 ms | hdr 2110 ms | total 2701 ms | chars 48 | Codex | Codex | appClipboardPaste | net -
6:42:29 AM | unverifiedInsert | req 1886 ms | hdr 1851 ms | total 2471 ms | chars 153 | Codex | Codex | appClipboardPaste | net -
6:43:00 AM | unverifiedInsert | req 3524 ms | hdr 3491 ms | total 4113 ms | chars 71 | Codex | Codex | appClipboardPaste | net -
6:43:20 AM | unverifiedInsert | req 1465 ms | hdr 1430 ms | total 2036 ms | chars 89 | Codex | Codex | appClipboardPaste | net -
6:44:11 AM | unverifiedInsert | req 1647 ms | hdr 1616 ms | total 2453 ms | chars 145 | Codex | Codex | appClipboardPaste | net -
6:44:48 AM | unverifiedInsert | req 2872 ms | hdr 2837 ms | total 3649 ms | chars 76 | Codex | Codex | appClipboardPaste | net -
```
