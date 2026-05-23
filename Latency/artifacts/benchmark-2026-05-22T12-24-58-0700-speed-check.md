date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: speed-check

# Latency Snapshot

Captured: `2026-05-22T12:24:58-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 77ADE864-CFBF-461A-9655-BB8BE2C9C4DD
Completed: May 22, 2026 at 12:24:42 PM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 4594 ms
Release -> Inserted: 5224 ms
Transcript Characters: 18
Transcript Words: 4
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_3f115988b2f5418b9598301c74e7fee9
OpenAI Processing: 763 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 4559 ms
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
Updated: May 22, 2026 at 12:24:42 PM
Session: F58C43FC-534E-4010-938D-D11B3A0E6BDD
Current Attempt: None
Workflow: Inserted (inserted)
Ready: Yes
Disk Readiness: Healthy
Disk Free Space: 49.14 GB
Disk Reserve: Reserved
Disk Reserved Space: 2.15 GB
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: transcription
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 12:24:35 PM
Hotkey Released: 12:24:37 PM
Finalizing Shown: 12:24:37 PM
Recording Finalized: 12:24:37 PM
Transcription Started: 12:24:37 PM
Insertion Completed: 12:24:42 PM
Stop Trigger: globalModifierMonitor
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 12:24:42 PM
Recent Events:
- 12:24:42 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 12:24:41 PM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 18 chars · 4 words from 2.04s.
- 12:24:37 PM | transcription | info | Transcription request started with a 30 second timeout.
- 12:24:37 PM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 2.04s · 48 KB. Starting transcription.
- 12:24:37 PM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 12:24:35 PM | recordingStart | info | Recording started from the global hotkey.
- 12:24:35 PM | hotkey | info | Observed hotkey press.
- 12:24:21 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
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
Request -> Response p50: 4922 ms
Request -> Response p95: 12612 ms
Request -> Headers p50: 4892 ms
Request -> Headers p95: 11247 ms
Release -> Inserted p50: 5578 ms
Release -> Inserted p95: 11894 ms
Transcript Characters p50: 77
Transcript Characters p95: 194
Transcript Words p50: 13
Transcript Words p95: 37
```

## Recent 50 Summary By Model
Command:
```bash
swift Scripts/diagnostics.swift summary-by-model 50
```

Observed:
```text
Unknown
  Attempts: 2
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 2
  Streaming Fallbacks: 0
  Request -> Response p50: 12612 ms
  Request -> Response p95: 12612 ms
  Request -> Headers p50: 10207 ms
  Request -> Headers p95: 10207 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 48
  Verified Inserts: 0
  Unverified Inserts: 48
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 2156 ms
  Request -> Response p95: 8342 ms
  Request -> Headers p50: 2127 ms
  Request -> Headers p95: 8312 ms
  Release -> Inserted p50: 2805 ms
  Release -> Inserted p95: 8979 ms
  Transcript Characters p50: 65
  Transcript Characters p95: 235
  Transcript Words p50: 12
  Transcript Words p95: 42
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
  Unverified Inserts: 48
  Failures: 2
  Streaming Fallbacks: 0
  Request -> Response p50: 2513 ms
  Request -> Response p95: 11284 ms
  Request -> Headers p50: 2127 ms
  Request -> Headers p95: 10207 ms
  Release -> Inserted p50: 2805 ms
  Release -> Inserted p95: 8979 ms
  Transcript Characters p50: 65
  Transcript Characters p95: 235
  Transcript Words p50: 12
  Transcript Words p95: 42
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
  Request -> Response p50: 12612 ms
  Request -> Response p95: 12612 ms
  Request -> Headers p50: 10207 ms
  Request -> Headers p95: 10207 ms
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
12:13:37 PM | unverifiedInsert | req 4478 ms | hdr 4444 ms | total 5104 ms | chars 17 | Codex | Codex | appClipboardPaste | net -
12:15:21 PM | unverifiedInsert | req 4185 ms | hdr 4141 ms | total 4809 ms | chars 50 | Codex | Codex | appClipboardPaste | net -
12:16:05 PM | unverifiedInsert | req 8342 ms | hdr 8312 ms | total 8979 ms | chars 112 | Codex | Codex | appClipboardPaste | net -
12:17:51 PM | unverifiedInsert | req 7274 ms | hdr 7245 ms | total 7931 ms | chars 91 | Codex | Codex | appClipboardPaste | net -
12:19:01 PM | unverifiedInsert | req 11284 ms | hdr 11247 ms | total 11894 ms | chars 77 | Codex | Codex | appClipboardPaste | net -
12:19:31 PM | unverifiedInsert | req 5441 ms | hdr 5406 ms | total 6135 ms | chars 60 | Codex | Codex | appClipboardPaste | net -
12:22:11 PM | unverifiedInsert | req 4967 ms | hdr 4928 ms | total 5651 ms | chars 85 | Codex | Codex | appClipboardPaste | net -
12:23:01 PM | transcriptionFailed | req 12612 ms | hdr 10207 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
12:24:21 PM | unverifiedInsert | req 18065 ms | hdr 18030 ms | total 18677 ms | chars 109 | Codex | Codex | appClipboardPaste | net -
12:24:42 PM | unverifiedInsert | req 4594 ms | hdr 4559 ms | total 5224 ms | chars 18 | Codex | Codex | appClipboardPaste | net -
```
