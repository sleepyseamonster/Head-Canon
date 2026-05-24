date: 2026-05-23
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: full-latency-diagnostic

# Latency Snapshot

Captured: `2026-05-23T17:47:53-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: EA279C58-17D7-45E6-A27B-78BA124F7D40
Completed: May 23, 2026 at 5:47:38 PM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 1549 ms
Release -> Inserted: 2257 ms
Transcript Characters: 17
Transcript Words: 3
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_e4175dff3294446c91e6798b4f3ffc25
OpenAI Processing: 728 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1454 ms
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
Updated: May 23, 2026 at 5:47:39 PM
Session: 95781B3A-24DF-4CF1-828D-7EDC2B5E6E4F
Current Attempt: None
Workflow: Inserted (inserted)
Ready: Yes
Disk Readiness: Healthy
Disk Free Space: 47.61 GB
Disk Reserve: Reserved
Disk Reserved Space: 2.15 GB
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: transcription
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 5:47:34 PM
Hotkey Released: 5:47:36 PM
Finalizing Shown: 5:47:36 PM
Recording Finalized: 5:47:36 PM
Transcription Started: 5:47:36 PM
Insertion Completed: 5:47:38 PM
Stop Trigger: globalModifierMonitor
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 5:47:38 PM
Recent Events:
- 5:47:38 PM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 5:47:38 PM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 17 chars · 3 words from 2.33s.
- 5:47:36 PM | transcription | info | Transcription request started with a 30 second timeout.
- 5:47:36 PM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 2.33s · 50 KB. Starting transcription.
- 5:47:36 PM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 5:47:34 PM | recordingStart | info | Recording started from the global hotkey.
- 5:47:34 PM | hotkey | info | Observed hotkey press.
- 5:46:46 PM | transcription | failure | The transcription response was empty or could not be decoded.
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
Request -> Response p50: 1835 ms
Request -> Response p95: 2851 ms
Request -> Headers p50: 1603 ms
Request -> Headers p95: 2816 ms
Release -> Inserted p50: 2263 ms
Release -> Inserted p95: 3484 ms
Transcript Characters p50: 51
Transcript Characters p95: 398
Transcript Words p50: 11
Transcript Words p95: 67
```

## Recent 50 Summary By Model
Command:
```bash
swift Scripts/diagnostics.swift summary-by-model 50
```

Observed:
```text
Unknown
  Attempts: 3
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 2462 ms
  Request -> Response p95: 2613 ms
  Request -> Headers p50: 983 ms
  Request -> Headers p95: 1298 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 47
  Verified Inserts: 0
  Unverified Inserts: 47
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1515 ms
  Request -> Response p95: 3696 ms
  Request -> Headers p50: 1470 ms
  Request -> Headers p95: 3660 ms
  Release -> Inserted p50: 2138 ms
  Release -> Inserted p95: 4326 ms
  Transcript Characters p50: 39
  Transcript Characters p95: 398
  Transcript Words p50: 6
  Transcript Words p95: 67
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
  Unverified Inserts: 47
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 1530 ms
  Request -> Response p95: 3696 ms
  Request -> Headers p50: 1454 ms
  Request -> Headers p95: 3660 ms
  Release -> Inserted p50: 2138 ms
  Release -> Inserted p95: 4326 ms
  Transcript Characters p50: 39
  Transcript Characters p95: 398
  Transcript Words p50: 6
  Transcript Words p95: 67
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
transcriptionFailed
  Attempts: 3
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 2462 ms
  Request -> Response p95: 2613 ms
  Request -> Headers p50: 983 ms
  Request -> Headers p95: 1298 ms
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
5:44:37 PM | unverifiedInsert | req 3704 ms | hdr 3669 ms | total 4348 ms | chars 428 | Codex | Codex | appClipboardPaste | net -
5:45:17 PM | unverifiedInsert | req 1883 ms | hdr 1848 ms | total 2531 ms | chars 13 | Codex | Codex | appClipboardPaste | net -
5:45:27 PM | unverifiedInsert | req 1835 ms | hdr 1800 ms | total 2461 ms | chars 69 | Codex | Codex | appClipboardPaste | net -
5:45:45 PM | unverifiedInsert | req 1640 ms | hdr 1603 ms | total 2263 ms | chars 30 | Codex | Codex | appClipboardPaste | net -
5:45:57 PM | unverifiedInsert | req 1383 ms | hdr 1332 ms | total 2018 ms | chars 92 | Codex | Codex | appClipboardPaste | net -
5:46:24 PM | unverifiedInsert | req 1246 ms | hdr 1214 ms | total 1878 ms | chars 42 | Codex | Codex | appClipboardPaste | net -
5:46:31 PM | unverifiedInsert | req 1503 ms | hdr 1470 ms | total 2132 ms | chars 7 | Codex | Codex | appClipboardPaste | net -
5:46:42 PM | unverifiedInsert | req 1809 ms | hdr 1774 ms | total 2426 ms | chars 51 | Codex | Codex | appClipboardPaste | net -
5:46:46 PM | transcriptionFailed | req 2613 ms | hdr 892 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
5:47:38 PM | unverifiedInsert | req 1549 ms | hdr 1454 ms | total 2257 ms | chars 17 | Codex | Codex | appClipboardPaste | net -
```

## Internet Quality
Command:
```bash
networkQuality
```

Observed:
```text
==== SUMMARY ====
Uplink capacity: 15.807 Mbps
Downlink capacity: 110.203 Mbps
Responsiveness: Low (1.337 seconds | 44 RPM)
Idle Latency: 53.637 milliseconds | 1118 RPM
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
Request -> Response p50: 1641 ms
Request -> Response p95: 2851 ms
Request -> Headers p50: 1608 ms
Headers Share p50: 98%
Release -> Inserted p50: 2263 ms
Response -> Inserted p50: 629 ms
Slow Successes >= 5s: 0/17
Very Slow Successes >= 10s: 0/17
Body-Read Failures: 3
Body-Read Failures With Empty Body Evidence: 0
Body-Read Failures With UTF-8 Decode Failure: 0
Body-Read Failures With Content-Length Mismatch: 0
Body-Read Failures Missing Body Evidence: 0
Network Uplink: 15.807 Mbps
Network Downlink: 110.203 Mbps
Network Responsiveness: Low (1.337 s)
Network Idle Latency: 53.637 ms
Interpretation:
- Recent failures are concentrated in transcription body reads after HTTP 200 responses.
- Current network responsiveness is poor enough to plausibly contribute to higher transcription latency.
- Insertion overhead after the transcription response remains relatively small.
Next Check:
- Inspect the next transcription failure with the latest diagnostics output to confirm whether body bytes are empty, mismatched, or non-UTF-8.
```
