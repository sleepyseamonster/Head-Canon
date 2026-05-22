date: 2026-05-21
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: stuck-recording-audit

# Latency Snapshot

Captured: `2026-05-21T19:17:48-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 5EA284BF-BA15-4C3B-8DE4-F500D83B851C
Completed: May 21, 2026 at 7:09:05 PM
State: inserted
Truth State: Unknown
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 1804 ms
Release -> Inserted: 2375 ms
Transcript Characters: 10
Transcript Words: 2
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_6164cadd3d2a4a459b2d4334ad5b4846
OpenAI Processing: 301 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1772 ms
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
Verification: Unknown
Placeholder Present: No
Placeholder Likely Active: No
Placeholder Ambiguous Value: No
Placeholder Handling: noneNeeded
```

## Recent 20 Summary
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Failures: 3
Streaming Fallbacks: 10
Request -> Response p50: 2597 ms
Request -> Response p95: 30152 ms
Request -> Headers p50: 1332 ms
Request -> Headers p95: 2164 ms
Release -> Inserted p50: 2859 ms
Release -> Inserted p95: 22294 ms
Transcript Characters p50: 49
Transcript Characters p95: 87
Transcript Words p50: 10
Transcript Words p95: 17
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
  Failures: 23
  Streaming Fallbacks: 36
  Request -> Response p50: 2656 ms
  Request -> Response p95: 21704 ms
  Request -> Headers p50: 1378 ms
  Request -> Headers p95: 2403 ms
  Release -> Inserted p50: 2859 ms
  Release -> Inserted p95: 22294 ms
  Transcript Characters p50: 53
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
  Failures: 23
  Streaming Fallbacks: 32
  Request -> Response p50: 2676 ms
  Request -> Response p95: 30131 ms
  Request -> Headers p50: 1378 ms
  Request -> Headers p95: 2403 ms
  Release -> Inserted p50: 2859 ms
  Release -> Inserted p95: 22294 ms
  Transcript Characters p50: 50
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
  Attempts: 23
  Failures: 23
  Streaming Fallbacks: 20
  Request -> Response p50: 2822 ms
  Request -> Response p95: 4158 ms
  Request -> Headers p50: 1378 ms
  Request -> Headers p95: 1930 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: 71
  Transcript Characters p95: 260
  Transcript Words p50: 13
  Transcript Words p95: 43
none
  Attempts: 23
  Failures: 0
  Streaming Fallbacks: 16
  Request -> Response p50: 2365 ms
  Request -> Response p95: 21704 ms
  Request -> Headers p50: 1332 ms
  Request -> Headers p95: 2403 ms
  Release -> Inserted p50: 2859 ms
  Release -> Inserted p95: 22294 ms
  Transcript Characters p50: 39
  Transcript Characters p95: 156
  Transcript Words p50: 7
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
6:00:48 PM | transcription | req 30152 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:01:46 PM | none | req 24015 ms | hdr 2078 ms | total 24595 ms | chars 54 | Codex | Codex | appClipboardPaste | net -
6:05:00 PM | transcription | req 30198 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:13:31 PM | none | req 2436 ms | hdr 2403 ms | total 3082 ms | chars 87 | Codex | Codex | appClipboardPaste | net -
6:14:44 PM | none | req 1728 ms | hdr 1689 ms | total 2316 ms | chars 30 | Codex | Codex | appClipboardPaste | net -
6:16:40 PM | none | req 1633 ms | hdr 1598 ms | total 2219 ms | chars 49 | Codex | Codex | appClipboardPaste | net -
6:16:46 PM | none | req 847 ms | hdr 810 ms | total 1434 ms | chars 31 | Codex | Codex | appClipboardPaste | net -
6:36:55 PM | none | req 1258 ms | hdr 1224 ms | total 1916 ms | chars 52 | Codex | Codex | appClipboardPaste | net -
6:39:53 PM | none | req 2200 ms | hdr 2164 ms | total 2783 ms | chars 13 | Codex | Codex | appClipboardPaste | net -
7:09:05 PM | none | req 1804 ms | hdr 1772 ms | total 2375 ms | chars 10 | Codex | Codex | appClipboardPaste | net -
```
