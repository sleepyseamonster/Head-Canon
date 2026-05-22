date: 2026-05-21
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: clean-app-matrix-prep

# Latency Snapshot

Captured: `2026-05-21T17:50:31-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: E979DCF3-A43B-4660-95B0-C73E36A9F343
Completed: May 21, 2026 at 5:50:06 PM
State: inserted
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 3026 ms
Release -> Inserted: 3602 ms
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: Yes
HTTP Status: 200
Request ID: req_a4e5cc9bf3854c20bdf99f4cdf45694f
OpenAI Processing: 398 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1222 ms
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
```

## Recent 20 Summary
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Failures: 11
Streaming Fallbacks: 19
Request -> Response p50: 3444 ms
Request -> Response p95: 9530 ms
Request -> Headers p50: 1593 ms
Request -> Headers p95: 2446 ms
Release -> Inserted p50: 3602 ms
Release -> Inserted p95: 9812 ms
```

## Recent 50 Summary By Model
Command:
```bash
swift Scripts/diagnostics.swift summary-by-model 50
```

Observed:
```text
Unknown
  Attempts: 1
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 869 ms
  Request -> Response p95: 869 ms
  Request -> Headers p50: Unknown
  Request -> Headers p95: Unknown
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 49
  Failures: 36
  Streaming Fallbacks: 30
  Request -> Response p50: 2210 ms
  Request -> Response p95: 4933 ms
  Request -> Headers p50: 1192 ms
  Request -> Headers p95: 2027 ms
  Release -> Inserted p50: 2795 ms
  Release -> Inserted p95: 5173 ms
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
  Failures: 33
  Streaming Fallbacks: 26
  Request -> Response p50: 2060 ms
  Request -> Response p95: 4933 ms
  Request -> Headers p50: 1126 ms
  Request -> Headers p95: 2027 ms
  Release -> Inserted p50: 2795 ms
  Release -> Inserted p95: 5173 ms
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
```

## Recent 50 Summary By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
insertion
  Attempts: 36
  Failures: 36
  Streaming Fallbacks: 20
  Request -> Response p50: 2210 ms
  Request -> Response p95: 3674 ms
  Request -> Headers p50: 1215 ms
  Request -> Headers p95: 1845 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
none
  Attempts: 13
  Failures: 0
  Streaming Fallbacks: 10
  Request -> Response p50: 2226 ms
  Request -> Response p95: 4933 ms
  Request -> Headers p50: 1150 ms
  Request -> Headers p95: 2027 ms
  Release -> Inserted p50: 2795 ms
  Release -> Inserted p95: 5173 ms
transcription
  Attempts: 1
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 869 ms
  Request -> Response p95: 869 ms
  Request -> Headers p50: Unknown
  Request -> Headers p95: Unknown
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
```

## Recent 10 Timeline
Command:
```bash
swift Scripts/diagnostics.swift recent 10
```

Observed:
```text
5:38:51 PM | inserted | req 9530 ms | hdr 4287 ms | total 9812 ms | Codex | Codex | appClipboardPaste | net -
5:40:03 PM | inserted | req 4933 ms | hdr 1973 ms | total 5173 ms | Codex | Codex | appClipboardPaste | net -
5:40:26 PM | inserted | req 2365 ms | hdr 1150 ms | total 2597 ms | Codex | Codex | appClipboardPaste | net -
5:41:15 PM | inserted | req 4103 ms | hdr 2027 ms | total 4339 ms | Codex | Codex | appClipboardPaste | net -
5:41:43 PM | failed | req 869 ms | hdr ? ms | total ? ms | Codex | Codex | appClipboardPaste | net -
5:49:14 PM | inserted | req 2087 ms | hdr 1061 ms | total 2795 ms | Codex | Codex | appClipboardPaste | net -
5:49:42 PM | inserted | req 3444 ms | hdr 1657 ms | total 4026 ms | Codex | Codex | appClipboardPaste | net -
5:49:53 PM | inserted | req 1770 ms | hdr 816 ms | total 2344 ms | Codex | Codex | appClipboardPaste | net -
5:49:59 PM | inserted | req 2226 ms | hdr 1303 ms | total 2816 ms | Codex | Codex | appClipboardPaste | net -
5:50:06 PM | inserted | req 3026 ms | hdr 1222 ms | total 3602 ms | Codex | Codex | appClipboardPaste | net -
```
