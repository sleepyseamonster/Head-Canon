date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: post-disk-clear-latency-diagnostic

# Latency Snapshot

Captured: `2026-05-22T08:53:23-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 9B8C5104-14FA-49FA-AB2C-418454D8AF58
Completed: May 22, 2026 at 8:53:12 AM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 3795 ms
Release -> Inserted: 4374 ms
Transcript Characters: 38
Transcript Words: 8
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_5887b446a7be4e978aef446128c4db0a
OpenAI Processing: 690 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 3762 ms
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
Updated: May 22, 2026 at 8:53:12 AM
Session: A6CFD72F-2159-4939-99D8-8520352EA024
Current Attempt: None
Workflow: Inserted (inserted)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: recordingStop
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 8:53:05 AM
Hotkey Released: 8:53:08 AM
Finalizing Shown: 8:53:08 AM
Recording Finalized: 8:53:08 AM
Transcription Started: 8:53:08 AM
Insertion Completed: 8:53:12 AM
Stop Trigger: globalModifierMonitor
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 8:53:12 AM
Recent Events:
- 8:53:12 AM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 8:53:12 AM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 38 chars · 8 words from 2.69s.
- 8:53:08 AM | transcription | info | Transcription request started with a 30 second timeout.
- 8:53:08 AM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 2.69s · 53 KB. Starting transcription.
- 8:53:08 AM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 8:53:05 AM | recordingStart | info | Recording started from the global hotkey.
- 8:53:05 AM | hotkey | info | Observed hotkey press.
- 8:46:27 AM | recordingStop | failure | Disk Full
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
Unverified Inserts: 13
Failures: 7
Streaming Fallbacks: 0
Request -> Response p50: 1493 ms
Request -> Response p95: 2792 ms
Request -> Headers p50: 1461 ms
Request -> Headers p95: 2752 ms
Release -> Inserted p50: 2096 ms
Release -> Inserted p95: 3412 ms
Transcript Characters p50: 102
Transcript Characters p95: 240
Transcript Words p50: 18
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
  Attempts: 7
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 7
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
  Attempts: 43
  Verified Inserts: 0
  Unverified Inserts: 43
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1493 ms
  Request -> Response p95: 2935 ms
  Request -> Headers p50: 1461 ms
  Request -> Headers p95: 2897 ms
  Release -> Inserted p50: 2074 ms
  Release -> Inserted p95: 3522 ms
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
  Unverified Inserts: 43
  Failures: 7
  Streaming Fallbacks: 0
  Request -> Response p50: 1493 ms
  Request -> Response p95: 2935 ms
  Request -> Headers p50: 1461 ms
  Request -> Headers p95: 2897 ms
  Release -> Inserted p50: 2074 ms
  Release -> Inserted p95: 3522 ms
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
  Attempts: 7
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 7
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
8:43:44 AM | unverifiedInsert | req 1304 ms | hdr 1233 ms | total 1938 ms | chars 53 | Codex | Codex | appClipboardPaste | net -
8:44:20 AM | unverifiedInsert | req 1630 ms | hdr 1595 ms | total 2211 ms | chars 118 | Codex | Codex | appClipboardPaste | net -
8:44:37 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:40 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:40 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:42 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:46 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:44:55 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:46:27 AM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
8:53:12 AM | unverifiedInsert | req 3795 ms | hdr 3762 ms | total 4374 ms | chars 38 | Codex | Codex | appClipboardPaste | net -
```
