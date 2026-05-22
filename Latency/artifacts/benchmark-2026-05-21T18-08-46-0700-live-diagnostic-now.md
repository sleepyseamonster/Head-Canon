date: 2026-05-21
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: live-diagnostic-now

# Latency Snapshot

Captured: `2026-05-21T18:08:46-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 091DF340-CB7B-40E3-BB72-C2867B48CDAC
Completed: May 21, 2026 at 6:05:00 PM
State: timedOut
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 30198 ms
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
Placeholder Present: No
Placeholder Likely Active: No
Placeholder Ambiguous Value: No
Placeholder Handling: noneNeeded
Failure Stage: transcription
Failure Message: Head Canon stopped waiting for transcription after 30 seconds.
```

## Recent 20 Summary
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Failures: 5
Streaming Fallbacks: 16
Request -> Response p50: 3444 ms
Request -> Response p95: 30152 ms
Request -> Headers p50: 1332 ms
Request -> Headers p95: 2078 ms
Release -> Inserted p50: 3602 ms
Release -> Inserted p95: 22294 ms
Transcript Characters p50: 53
Transcript Characters p95: 156
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
  Failures: 4
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
  Attempts: 46
  Failures: 27
  Streaming Fallbacks: 36
  Request -> Response p50: 2656 ms
  Request -> Response p95: 21704 ms
  Request -> Headers p50: 1222 ms
  Request -> Headers p95: 2078 ms
  Release -> Inserted p50: 3166 ms
  Release -> Inserted p95: 22294 ms
  Transcript Characters p50: 54
  Transcript Characters p95: 237
  Transcript Words p50: 10
  Transcript Words p95: 43
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
  Attempts: 46
  Failures: 27
  Streaming Fallbacks: 32
  Request -> Response p50: 2676 ms
  Request -> Response p95: 30131 ms
  Request -> Headers p50: 1192 ms
  Request -> Headers p95: 2078 ms
  Release -> Inserted p50: 3166 ms
  Release -> Inserted p95: 22294 ms
  Transcript Characters p50: 53
  Transcript Characters p95: 237
  Transcript Words p50: 10
  Transcript Words p95: 40
Native
  Apps: ChatGPT Atlas
  Attempts: 4
  Failures: 4
  Streaming Fallbacks: 4
  Request -> Response p50: 3430 ms
  Request -> Response p95: 3512 ms
  Request -> Headers p50: 1523 ms
  Request -> Headers p95: 1592 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: 200
  Transcript Characters p95: 226
  Transcript Words p50: 36
  Transcript Words p95: 43
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
insertion
  Attempts: 27
  Failures: 27
  Streaming Fallbacks: 20
  Request -> Response p50: 2656 ms
  Request -> Response p95: 4158 ms
  Request -> Headers p50: 1278 ms
  Request -> Headers p95: 1930 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: 71
  Transcript Characters p95: 260
  Transcript Words p50: 13
  Transcript Words p95: 43
none
  Attempts: 19
  Failures: 0
  Streaming Fallbacks: 16
  Request -> Response p50: 2597 ms
  Request -> Response p95: 21704 ms
  Request -> Headers p50: 1150 ms
  Request -> Headers p95: 2078 ms
  Release -> Inserted p50: 3166 ms
  Release -> Inserted p95: 22294 ms
  Transcript Characters p50: 53
  Transcript Characters p95: 156
  Transcript Words p50: 10
  Transcript Words p95: 28
transcription
  Attempts: 4
  Failures: 4
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
5:50:06 PM | inserted | req 3026 ms | hdr 1222 ms | total 3602 ms | chars 15 | Codex | Codex | appClipboardPaste | net -
5:51:00 PM | inserted | req 4422 ms | hdr 1808 ms | total 5009 ms | chars 138 | Codex | Codex | appClipboardPaste | net -
5:51:18 PM | inserted | req 2280 ms | hdr 1077 ms | total 2859 ms | chars 64 | Codex | Codex | appClipboardPaste | net -
5:54:17 PM | inserted | req 21704 ms | hdr 1002 ms | total 22294 ms | chars 58 | Codex | Codex | appClipboardPaste | net -
5:55:23 PM | inserted | req 2859 ms | hdr 1096 ms | total 3422 ms | chars 53 | Codex | Codex | appClipboardPaste | net -
5:56:23 PM | inserted | req 2597 ms | hdr 1332 ms | total 3166 ms | chars 53 | Codex | Codex | appClipboardPaste | net -
5:59:25 PM | timedOut | req 30131 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:00:48 PM | timedOut | req 30152 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:01:46 PM | inserted | req 24015 ms | hdr 2078 ms | total 24595 ms | chars 54 | Codex | Codex | appClipboardPaste | net -
6:05:00 PM | timedOut | req 30198 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
```
