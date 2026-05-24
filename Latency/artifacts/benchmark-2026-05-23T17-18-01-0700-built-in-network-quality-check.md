date: 2026-05-23
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: built-in-network-quality-check

# Latency Snapshot

Captured: `2026-05-23T17:18:01-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 6F329EB9-317F-48C7-8AE1-857253DE1304
Completed: May 23, 2026 at 5:17:58 PM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 1185 ms
Release -> Inserted: 1818 ms
Transcript Characters: 46
Transcript Words: 8
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_cfa8d1577f584b7bbbc9f0bad83460c0
OpenAI Processing: 675 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1149 ms
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
Updated: May 23, 2026 at 5:18:01 PM
Session: 5D89CEDB-478A-4A1D-BC5B-CE0E654FAF22
Current Attempt: 0BE5001E-F739-4146-ABB4-5E54C1B9DE22
Workflow: Recording (recording)
Ready: Yes
Disk Readiness: Healthy
Disk Free Space: 47.67 GB
Disk Reserve: Reserved
Disk Reserved Space: 2.15 GB
Audio Capture Recording: Yes
Hotkey: Hold Control + Option
Hotkey Physically Pressed: Yes
Active Transcription: None
Last Failure Stage: transcription
Last Truth State: None
Last Error: None
Recording Started: 5:18:01 PM
Hotkey Released: Unknown
Finalizing Shown: Unknown
Recording Finalized: Unknown
Transcription Started: Unknown
Insertion Completed: Unknown
Stop Trigger: Unknown
Last Event: Recording started from the global hotkey.
Last Event Stage: recordingStart
Last Event Failed: No
Last Event At: 5:18:01 PM
Recent Events:
- 5:18:01 PM | recordingStart | info | Recording started from the global hotkey.
- 5:18:01 PM | hotkey | info | Observed hotkey press.
- 5:17:58 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 5:17:57 PM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 46 chars · 8 words from 3.54s.
- 5:17:56 PM | transcription | info | Transcription request started with a 30 second timeout.
- 5:17:56 PM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 3.54s · 59 KB. Starting transcription.
- 5:17:56 PM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 5:17:53 PM | recordingStart | info | Recording started from the global hotkey.
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
Unverified Inserts: 16
Failures: 4
Streaming Fallbacks: 0
Request -> Response p50: 1471 ms
Request -> Response p95: 3071 ms
Request -> Headers p50: 1187 ms
Request -> Headers p95: 2556 ms
Release -> Inserted p50: 2043 ms
Release -> Inserted p95: 2877 ms
Transcript Characters p50: 41
Transcript Characters p95: 162
Transcript Words p50: 7
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
  Attempts: 6
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 6
  Streaming Fallbacks: 0
  Request -> Response p50: 2472 ms
  Request -> Response p95: 7220 ms
  Request -> Headers p50: 1139 ms
  Request -> Headers p95: 3392 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 44
  Verified Inserts: 1
  Unverified Inserts: 42
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 1471 ms
  Request -> Response p95: 2585 ms
  Request -> Headers p50: 1437 ms
  Request -> Headers p95: 2556 ms
  Release -> Inserted p50: 2043 ms
  Release -> Inserted p95: 3170 ms
  Transcript Characters p50: 46
  Transcript Characters p95: 236
  Transcript Words p50: 8
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
  Attempts: 47
  Verified Inserts: 0
  Unverified Inserts: 42
  Failures: 5
  Streaming Fallbacks: 0
  Request -> Response p50: 1480 ms
  Request -> Response p95: 4179 ms
  Request -> Headers p50: 1364 ms
  Request -> Headers p95: 2556 ms
  Release -> Inserted p50: 2107 ms
  Release -> Inserted p95: 3170 ms
  Transcript Characters p50: 46
  Transcript Characters p95: 236
  Transcript Words p50: 9
  Transcript Words p95: 45
Native
  Apps: ChatGPT Atlas
  Attempts: 3
  Verified Inserts: 1
  Unverified Inserts: 0
  Failures: 2
  Streaming Fallbacks: 0
  Request -> Response p50: 3071 ms
  Request -> Response p95: 3071 ms
  Request -> Headers p50: 3037 ms
  Request -> Headers p95: 3037 ms
  Release -> Inserted p50: 1735 ms
  Release -> Inserted p95: 1735 ms
  Transcript Characters p50: 47
  Transcript Characters p95: 47
  Transcript Words p50: 8
  Transcript Words p95: 8
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
  Attempts: 5
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 5
  Streaming Fallbacks: 0
  Request -> Response p50: 2472 ms
  Request -> Response p95: 7220 ms
  Request -> Headers p50: 1139 ms
  Request -> Headers p95: 3392 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
unsupportedTarget
  Attempts: 1
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 3071 ms
  Request -> Response p95: 3071 ms
  Request -> Headers p50: 3037 ms
  Request -> Headers p95: 3037 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: 7
  Transcript Characters p95: 7
  Transcript Words p50: 1
  Transcript Words p95: 1
```

## Recent 10 Timeline
Command:
```bash
swift Scripts/diagnostics.swift recent 10
```

Observed:
```text
5:15:55 PM | unverifiedInsert | req 2585 ms | hdr 2556 ms | total 3192 ms | chars 165 | Codex | Codex | appClipboardPaste | net -
5:16:14 PM | unverifiedInsert | req 1174 ms | hdr 1139 ms | total 1827 ms | chars 41 | Codex | Codex | appClipboardPaste | net -
5:16:22 PM | transcriptionFailed | req 2147 ms | hdr 1139 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
5:16:31 PM | unverifiedInsert | req 1192 ms | hdr 1157 ms | total 1834 ms | chars 41 | Codex | Codex | appClipboardPaste | net -
5:16:45 PM | transcriptionFailed | req 4179 ms | hdr 973 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
5:16:51 PM | unverifiedInsert | req 1183 ms | hdr 1150 ms | total 1803 ms | chars 17 | Codex | Codex | appClipboardPaste | net -
5:17:12 PM | unverifiedInsert | req 1692 ms | hdr 1657 ms | total 2294 ms | chars 162 | Codex | Codex | appClipboardPaste | net -
5:17:26 PM | unverifiedInsert | req 1556 ms | hdr 1523 ms | total 2178 ms | chars 22 | Codex | Codex | appClipboardPaste | net -
5:17:48 PM | unverifiedInsert | req 1516 ms | hdr 1478 ms | total 2140 ms | chars 118 | Codex | Codex | appClipboardPaste | net -
5:17:58 PM | unverifiedInsert | req 1185 ms | hdr 1149 ms | total 1818 ms | chars 46 | Codex | Codex | appClipboardPaste | net -
```

## Internet Quality
Command:
```bash
networkQuality
```

Observed:
```text
==== SUMMARY ====
Uplink capacity: 12.819 Mbps
Downlink capacity: 111.653 Mbps
Responsiveness: Low (1.321 seconds | 45 RPM)
Idle Latency: 40.662 milliseconds | 1475 RPM
```
