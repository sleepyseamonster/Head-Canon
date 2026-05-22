date: 2026-05-21
status: complete
owner: Latency
purpose: Snapshot the current persisted diagnostics state from the local installed-app log.

# Live Diagnostics Snapshot

Captured from the repo-local reader at [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift:357) on `2026-05-21T17:28:10-0700`.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: EFD52ACD-883A-4560-B720-2FC2AECD4C46
Completed: May 21, 2026 at 5:23:31 PM
State: failed
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 3383 ms
Release -> Inserted: Unknown
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: Yes
HTTP Status: 200
Request ID: req_791865c291b74b6c9f0e48ec12e374ca
OpenAI Processing: 276 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1671 ms
Failure Stage: insertion
Clipboard Recovery: Copied
Clipboard Recovery Reason: insertionSafetyBlock
```

Read:
- The latest observed problem is not slow transcription alone.
- The latest turn transcribed in `3383 ms`, then failed in `Codex` insertion safety handling and copied the transcript for recovery.

## Recent 20 Attempts
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Failures: 19
Streaming Fallbacks: 17
Request -> Response p50: 2656 ms
Request -> Response p95: 3674 ms
Request -> Headers p50: 1278 ms
Request -> Headers p95: 1845 ms
Release -> Inserted p50: 1784 ms
Release -> Inserted p95: 1784 ms
```

Read:
- This sample is failure-heavy, so `release -> inserted` is based on very few successes.
- The transport median is decent for a hosted bounded path, but the success rate in this recent slice is poor enough that raw speed is not the headline.

## Recent 50 Attempts By Model
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
  Request -> Response p50: 30177 ms
  Request -> Response p95: 30177 ms

openai.gpt-4o-mini-transcribe
  Attempts: 49
  Failures: 43
  Streaming Fallbacks: 17
  Request -> Response p50: 1579 ms
  Request -> Response p95: 9416 ms
  Request -> Headers p50: 1119 ms
  Request -> Headers p95: 1903 ms
  Release -> Inserted p50: 1729 ms
  Release -> Inserted p95: 9689 ms
```

Read:
- `gpt-4o-mini-transcribe` is still the real active baseline.
- The model’s median is strong, but the long tail remains very real.

## Recent 50 Attempts By App Class
Command:
```bash
swift Scripts/diagnostics.swift summary-by-app-class 50
```

Observed:
```text
Codex
  Apps: Codex
  Attempts: 46
  Failures: 40
  Streaming Fallbacks: 13
  Request -> Response p50: 1557 ms
  Request -> Response p95: 9534 ms
  Request -> Headers p50: 1086 ms
  Request -> Headers p95: 1903 ms
  Release -> Inserted p50: 1729 ms
  Release -> Inserted p95: 9689 ms

Native
  Apps: ChatGPT Atlas
  Attempts: 4
  Failures: 4
  Streaming Fallbacks: 4
  Request -> Response p50: 3430 ms
  Request -> Response p95: 3512 ms
  Request -> Headers p50: 1523 ms
  Request -> Headers p95: 1592 ms
```

Read:
- `Codex` still dominates the current latency and failure picture.
- The dataset is not a balanced app matrix yet.

## Recent 50 Attempts By Failure
Command:
```bash
swift Scripts/diagnostics.swift summary-by-failure 50
```

Observed:
```text
insertion
  Attempts: 43
  Failures: 43
  Streaming Fallbacks: 16
  Request -> Response p50: 1684 ms
  Request -> Response p95: 4158 ms
  Request -> Headers p50: 1126 ms
  Request -> Headers p95: 1903 ms

none
  Attempts: 6
  Failures: 0
  Streaming Fallbacks: 1
  Request -> Response p50: 1350 ms
  Request -> Response p95: 9416 ms
  Request -> Headers p50: 1047 ms
  Request -> Headers p95: 1185 ms
  Release -> Inserted p50: 1729 ms
  Release -> Inserted p95: 9689 ms

transcription
  Attempts: 1
  Failures: 1
  Streaming Fallbacks: 0
  Request -> Response p50: 30177 ms
  Request -> Response p95: 30177 ms
```

Read:
- The dominant live failure class is still insertion, not transcription.
- The timeout path still exists, but it is rare in this current slice.

## Recent 10 Timeline
Command:
```bash
swift Scripts/diagnostics.swift recent 10
```

Observed:
```text
11:30:17 AM | failed | req 2210 ms | hdr 1126 ms | total ? ms | Codex | Codex | customEditorPaste | net -
11:30:23 AM | failed | req 2676 ms | hdr 1096 ms | total ? ms | Codex | Codex | customEditorPaste | net -
11:33:28 AM | failed | req 3171 ms | hdr 1738 ms | total ? ms | Codex | Codex | customEditorPaste | net -
11:35:17 AM | failed | req 2642 ms | hdr 1220 ms | total ? ms | Native | ChatGPT Atlas | unsupported | net -
11:36:10 AM | failed | req 3512 ms | hdr 1523 ms | total ? ms | Native | ChatGPT Atlas | unsupported | net -
4:47:54 PM | failed | req 3674 ms | hdr 1845 ms | total ? ms | Codex | Codex | appClipboardPaste | net -
4:48:28 PM | failed | req 2060 ms | hdr 984 ms | total ? ms | Codex | Codex | appClipboardPaste | net -
4:55:36 PM | failed | req 4158 ms | hdr 1832 ms | total ? ms | Codex | Codex | appClipboardPaste | net -
5:01:47 PM | failed | req 3621 ms | hdr 2446 ms | total ? ms | Codex | Codex | appClipboardPaste | net -
5:23:31 PM | failed | req 3383 ms | hdr 1671 ms | total ? ms | Codex | Codex | appClipboardPaste | net -
```

Read:
- The recent sequence is almost entirely failure-only, which explains why total-path success metrics are thin.
- There is visible strategy drift from `customEditorPaste` to `appClipboardPaste` in the recent timeline, which is worth remembering during future regression checks.

## Historical Comparison Anchor
- The prior before-snapshot is [D-Bug/artifacts/installed-app-baseline-2026-05-21.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/artifacts/installed-app-baseline-2026-05-21.md:1).
- That artifact should still be treated as the earlier installed-app comparison point until a newer success-heavy benchmark pass is saved in `Latency/artifacts/`.

## Audit
- The current diagnostics log is rich enough to support performance triage.
- The current measured pain is reliability in app-specific insertion paths more than raw hosted transcription median.
- If we are close to peak bounded-path speed, the next "latency" wins are mostly tail and routing wins.

## Next Recommended Step
- Run a clean, deliberate installed-app benchmark pass that includes a success-heavy target like `TextEdit` alongside `Codex`, then save that result directly in `Latency/artifacts/`.
