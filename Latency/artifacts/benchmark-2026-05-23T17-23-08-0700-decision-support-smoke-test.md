date: 2026-05-23
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: decision-support-smoke-test

# Latency Snapshot

Captured: `2026-05-23T17:23:08-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: D1A14EAD-3CF0-4136-A101-7EA314EA6C09
Completed: May 23, 2026 at 5:22:20 PM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 3696 ms
Release -> Inserted: 4326 ms
Transcript Characters: 423
Transcript Words: 78
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_8e58316dfccd4ee3b01a06177c02ccb0
OpenAI Processing: 1779 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 3660 ms
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
Updated: May 23, 2026 at 5:22:20 PM
Session: 5D89CEDB-478A-4A1D-BC5B-CE0E654FAF22
Current Attempt: None
Workflow: Inserted (inserted)
Ready: Yes
Disk Readiness: Healthy
Disk Free Space: 47.69 GB
Disk Reserve: Reserved
Disk Reserved Space: 2.15 GB
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: transcription
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 5:21:39 PM
Hotkey Released: 5:22:16 PM
Finalizing Shown: 5:22:16 PM
Recording Finalized: 5:22:16 PM
Transcription Started: 5:22:16 PM
Insertion Completed: 5:22:20 PM
Stop Trigger: globalModifierMonitor
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 5:22:20 PM
Recent Events:
- 5:22:20 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 5:22:20 PM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 423 chars · 78 words from 37.36s.
- 5:22:16 PM | transcription | info | Transcription request started with a 30 second timeout.
- 5:22:16 PM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 37.36s · 325 KB. Starting transcription.
- 5:22:16 PM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 5:21:39 PM | recordingStart | info | Recording started from the global hotkey.
- 5:21:38 PM | hotkey | info | Observed hotkey press.
- 5:21:20 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
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
Request -> Response p50: 1516 ms
Request -> Response p95: 4179 ms
Request -> Headers p50: 1232 ms
Request -> Headers p95: 1657 ms
Release -> Inserted p50: 2085 ms
Release -> Inserted p95: 2305 ms
Transcript Characters p50: 46
Transcript Characters p95: 177
Transcript Words p50: 8
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
  Request -> Response p50: 4179 ms
  Request -> Response p95: 30049 ms
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
  Verified Inserts: 0
  Unverified Inserts: 43
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 1471 ms
  Request -> Response p95: 2585 ms
  Request -> Headers p50: 1367 ms
  Request -> Headers p95: 2556 ms
  Release -> Inserted p50: 2043 ms
  Release -> Inserted p95: 3170 ms
  Transcript Characters p50: 41
  Transcript Characters p95: 215
  Transcript Words p50: 7
  Transcript Words p95: 39
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
  Attempts: 48
  Verified Inserts: 0
  Unverified Inserts: 43
  Failures: 5
  Streaming Fallbacks: 0
  Request -> Response p50: 1480 ms
  Request -> Response p95: 4179 ms
  Request -> Headers p50: 1355 ms
  Request -> Headers p95: 2556 ms
  Release -> Inserted p50: 2043 ms
  Release -> Inserted p95: 3170 ms
  Transcript Characters p50: 41
  Transcript Characters p95: 215
  Transcript Words p50: 7
  Transcript Words p95: 39
Native
  Apps: ChatGPT Atlas
  Attempts: 2
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 2
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
  Attempts: 4
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 4
  Streaming Fallbacks: 0
  Request -> Response p50: 4179 ms
  Request -> Response p95: 7220 ms
  Request -> Headers p50: 1139 ms
  Request -> Headers p95: 3392 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
transcriptionTimedOut
  Attempts: 1
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 30049 ms
  Request -> Response p95: 30049 ms
  Request -> Headers p50: Unknown
  Request -> Headers p95: Unknown
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
5:20:05 PM | unverifiedInsert | req 1617 ms | hdr 1582 ms | total 2257 ms | chars 177 | Codex | Codex | appClipboardPaste | net -
5:20:14 PM | unverifiedInsert | req 1616 ms | hdr 1583 ms | total 2239 ms | chars 61 | Codex | Codex | appClipboardPaste | net -
5:20:27 PM | unverifiedInsert | req 1476 ms | hdr 1437 ms | total 2085 ms | chars 115 | Codex | Codex | appClipboardPaste | net -
5:20:47 PM | unverifiedInsert | req 1498 ms | hdr 1162 ms | total 2126 ms | chars 57 | Codex | Codex | appClipboardPaste | net -
5:20:59 PM | unverifiedInsert | req 1393 ms | hdr 1355 ms | total 2009 ms | chars 69 | Codex | Codex | appClipboardPaste | net -
5:21:02 PM | unverifiedInsert | req 945 ms | hdr 909 ms | total 1581 ms | chars 14 | Codex | Codex | appClipboardPaste | net -
5:21:06 PM | unverifiedInsert | req 1264 ms | hdr 1227 ms | total 1859 ms | chars 27 | Codex | Codex | appClipboardPaste | net -
5:21:13 PM | unverifiedInsert | req 1616 ms | hdr 1581 ms | total 2305 ms | chars 26 | Codex | Codex | appClipboardPaste | net -
5:21:20 PM | unverifiedInsert | req 1267 ms | hdr 1232 ms | total 1894 ms | chars 34 | Codex | Codex | appClipboardPaste | net -
5:22:20 PM | unverifiedInsert | req 3696 ms | hdr 3660 ms | total 4326 ms | chars 423 | Codex | Codex | appClipboardPaste | net -
```

## Internet Quality
Command:
```bash
networkQuality
```

Observed:
```text
==== SUMMARY ====
Uplink capacity: 14.000 Mbps
Downlink capacity: 124.710 Mbps
Responsiveness: Low (1.893 seconds | 31 RPM)
Idle Latency: 52.380 milliseconds | 1145 RPM
```

## Decision Support
Command:
```bash
swift Latency/bin/latency_decision_support.swift --window 20 --network-quality-file <captured-network-quality>
```

Observed:
```text
Assessment: degraded
Primary Bottleneck: transcription response-body instability
Window: 20 attempts
Successful Turns: 17
Failures: 3
Request -> Response p50: 1476 ms
Request -> Response p95: 1692 ms
Request -> Headers p50: 1355 ms
Headers Share p50: 97%
Release -> Inserted p50: 2085 ms
Response -> Inserted p50: 624 ms
Slow Successes >= 5s: 0/17
Very Slow Successes >= 10s: 0/17
Body-Read Failures: 2
Body-Read Failures With Empty Body Evidence: 0
Body-Read Failures With UTF-8 Decode Failure: 0
Body-Read Failures With Content-Length Mismatch: 0
Body-Read Failures Missing Body Evidence: 0
Network Uplink: 14.000 Mbps
Network Downlink: 124.710 Mbps
Network Responsiveness: Low (1.893 s)
Network Idle Latency: 52.380 ms
Interpretation:
- Recent failures are concentrated in transcription body reads after HTTP 200 responses.
- Current network responsiveness is poor enough to plausibly contribute to higher transcription latency.
- Insertion overhead after the transcription response remains relatively small.
Next Check:
- Inspect the next transcription failure with the latest diagnostics output to confirm whether body bytes are empty, mismatched, or non-UTF-8.
```
