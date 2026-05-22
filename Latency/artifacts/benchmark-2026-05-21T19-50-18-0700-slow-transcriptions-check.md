date: 2026-05-21
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: slow-transcriptions-check

# Latency Snapshot

Captured: `2026-05-21T19:50:18-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 1F389EAC-565F-4924-8D8E-FE3240F6B09F
Completed: May 21, 2026 at 7:50:09 PM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 873 ms
Release -> Inserted: 1486 ms
Transcript Characters: 74
Transcript Words: 13
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_6a9635cdf66b4337900d107efaf02bea
OpenAI Processing: 518 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 839 ms
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
Updated: May 21, 2026 at 7:50:09 PM
Session: 28ECE838-ECED-411B-AFE3-2D376C54A768
Current Attempt: 1F389EAC-565F-4924-8D8E-FE3240F6B09F
Workflow: Inserted (inserted)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: B5E360CB-4EC2-44B9-9C09-2C21216DA621
Last Failure Stage: recordingStop
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 7:50:02 PM
Hotkey Released: 7:50:07 PM
Finalizing Shown: 7:50:07 PM
Recording Finalized: 7:50:07 PM
Transcription Started: 7:50:07 PM
Insertion Completed: 7:50:09 PM
Stop Trigger: recordingReleaseWatchdog
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 7:50:09 PM
Recent Events:
- 7:50:09 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 7:50:08 PM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 74 chars · 13 words from 5.23s.
- 7:50:07 PM | transcription | info | Transcription request started with a 30 second timeout.
- 7:50:07 PM | recordingStop | info | Recording finalized via Recording Release Watchdog. Clip 5.23s · 73 KB. Starting transcription.
- 7:50:07 PM | hotkey | info | Hotkey released via Recording Release Watchdog. Moving into recording finalization.
- 7:50:07 PM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 7:50:07 PM | recordingStop | info | Recording release watchdog observed the hotkey is no longer physically pressed. Finalizing automatically.
- 7:50:02 PM | recordingStart | info | Recording started from the global hotkey.
```

## Recent 20 Summary
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Verified Inserts: 5
Unverified Inserts: 13
Failures: 2
Streaming Fallbacks: 0
Request -> Response p50: 1258 ms
Request -> Response p95: 2473 ms
Request -> Headers p50: 1045 ms
Request -> Headers p95: 2164 ms
Release -> Inserted p50: 1916 ms
Release -> Inserted p95: 3184 ms
Transcript Characters p50: 50
Transcript Characters p95: 124
Transcript Words p50: 10
Transcript Words p95: 20
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
  Request -> Response p50: 30152 ms
  Request -> Response p95: 30198 ms
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
  Verified Inserts: 22
  Unverified Inserts: 13
  Failures: 9
  Streaming Fallbacks: 24
  Request -> Response p50: 2365 ms
  Request -> Response p95: 21704 ms
  Request -> Headers p50: 1507 ms
  Request -> Headers p95: 2418 ms
  Release -> Inserted p50: 2597 ms
  Release -> Inserted p95: 22042 ms
  Transcript Characters p50: 53
  Transcript Characters p95: 161
  Transcript Words p50: 10
  Transcript Words p95: 29
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
  Verified Inserts: 22
  Unverified Inserts: 13
  Failures: 14
  Streaming Fallbacks: 24
  Request -> Response p50: 2436 ms
  Request -> Response p95: 30131 ms
  Request -> Headers p50: 1507 ms
  Request -> Headers p95: 2418 ms
  Release -> Inserted p50: 2597 ms
  Release -> Inserted p95: 22042 ms
  Transcript Characters p50: 53
  Transcript Characters p95: 161
  Transcript Words p50: 10
  Transcript Words p95: 29
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
safetyBlock
  Attempts: 9
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 9
  Streaming Fallbacks: 9
  Request -> Response p50: 3489 ms
  Request -> Response p95: 23051 ms
  Request -> Headers p50: 1671 ms
  Request -> Headers p95: 2446 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: 71
  Transcript Characters p95: 161
  Transcript Words p50: 13
  Transcript Words p95: 29
transcriptionFailed
  Attempts: 1
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 869 ms
  Request -> Response p95: 869 ms
  Request -> Headers p50: Unknown
  Request -> Headers p95: Unknown
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
transcriptionTimedOut
  Attempts: 3
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 30152 ms
  Request -> Response p95: 30198 ms
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
7:44:41 PM | unverifiedInsert | req 744 ms | hdr 697 ms | total 1330 ms | chars 13 | Codex | Codex | appClipboardPaste | net -
7:45:20 PM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
7:45:33 PM | unverifiedInsert | req 883 ms | hdr 834 ms | total 1458 ms | chars 50 | Codex | Codex | appClipboardPaste | net -
7:45:57 PM | unverifiedInsert | req 1090 ms | hdr 1045 ms | total 1674 ms | chars 43 | Codex | Codex | appClipboardPaste | net -
7:46:07 PM | unverifiedInsert | req 972 ms | hdr 938 ms | total 1560 ms | chars 56 | Codex | Codex | appClipboardPaste | net -
7:46:33 PM | unverifiedInsert | req 914 ms | hdr 879 ms | total 1507 ms | chars 52 | Codex | Codex | appClipboardPaste | net -
7:46:45 PM | unverifiedInsert | req 629 ms | hdr 537 ms | total 1251 ms | chars 50 | Codex | Codex | appClipboardPaste | net -
7:48:29 PM | unverifiedInsert | req 21301 ms | hdr 958 ms | total 22042 ms | chars 69 | Codex | Codex | appClipboardPaste | net -
7:49:27 PM | unverifiedInsert | req 1579 ms | hdr 1532 ms | total 2185 ms | chars 124 | Codex | Codex | appClipboardPaste | net -
7:50:09 PM | unverifiedInsert | req 873 ms | hdr 839 ms | total 1486 ms | chars 74 | Codex | Codex | appClipboardPaste | net -
```
