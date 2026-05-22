date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: post-reinstall-clean-live-state

# Latency Snapshot

Captured: `2026-05-22T06:57:29-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: D0CA6532-DA70-45B2-B540-C291A594E617
Completed: May 22, 2026 at 6:55:44 AM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 1220 ms
Release -> Inserted: 1803 ms
Transcript Characters: 9
Transcript Words: 2
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_c0d9724ddf9649f4916ad2dae4e61d13
OpenAI Processing: 827 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1185 ms
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
Updated: May 22, 2026 at 6:57:07 AM
Session: 7544598C-6513-4393-8649-5AFD58EA50EF
Current Attempt: None
Workflow: Ready (ready)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: None
Last Truth State: None
Last Error: None
Recording Timing: None
Last Event: Registered hotkey: Hold Control + Option
Last Event Stage: hotkey
Last Event Failed: No
Last Event At: 6:57:07 AM
Recent Events:
- 6:57:07 AM | hotkey | info | Registered hotkey: Hold Control + Option
- 6:57:07 AM | none | info | Permissions updated: Microphone Granted · Accessibility Granted
- 6:57:07 AM | none | info | Bootstrapped app from /Applications/HeadCanon.app
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
Unverified Inserts: 19
Failures: 1
Streaming Fallbacks: 0
Request -> Response p50: 1330 ms
Request -> Response p95: 4122 ms
Request -> Headers p50: 1296 ms
Request -> Headers p95: 4087 ms
Release -> Inserted p50: 1907 ms
Release -> Inserted p95: 4712 ms
Transcript Characters p50: 35
Transcript Characters p95: 168
Transcript Words p50: 7
Transcript Words p95: 32
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
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 4
  Streaming Fallbacks: 0
  Request -> Response p50: 30076 ms
  Request -> Response p95: 30081 ms
  Request -> Headers p50: 1286 ms
  Request -> Headers p95: 1286 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
openai.gpt-4o-mini-transcribe
  Attempts: 46
  Verified Inserts: 0
  Unverified Inserts: 46
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1616 ms
  Request -> Response p95: 5081 ms
  Request -> Headers p50: 1549 ms
  Request -> Headers p95: 3491 ms
  Release -> Inserted p50: 2225 ms
  Release -> Inserted p95: 5658 ms
  Transcript Characters p50: 56
  Transcript Characters p95: 185
  Transcript Words p50: 10
  Transcript Words p95: 32
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
  Unverified Inserts: 46
  Failures: 4
  Streaming Fallbacks: 0
  Request -> Response p50: 1616 ms
  Request -> Response p95: 10486 ms
  Request -> Headers p50: 1462 ms
  Request -> Headers p95: 3491 ms
  Release -> Inserted p50: 2225 ms
  Release -> Inserted p95: 5658 ms
  Transcript Characters p50: 56
  Transcript Characters p95: 185
  Transcript Words p50: 10
  Transcript Words p95: 32
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
  Request -> Response p50: 1315 ms
  Request -> Response p95: 1315 ms
  Request -> Headers p50: 1286 ms
  Request -> Headers p95: 1286 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: Unknown
  Transcript Characters p95: Unknown
  Transcript Words p50: Unknown
  Transcript Words p95: Unknown
transcriptionTimedOut
  Attempts: 2
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 2
  Streaming Fallbacks: 0
  Request -> Response p50: 30081 ms
  Request -> Response p95: 30081 ms
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
6:54:28 AM | unverifiedInsert | req 1717 ms | hdr 1680 ms | total 2302 ms | chars 253 | Codex | Codex | appClipboardPaste | net -
6:54:35 AM | unverifiedInsert | req 4122 ms | hdr 4087 ms | total 4712 ms | chars 7 | Codex | Codex | appClipboardPaste | net -
6:54:47 AM | unverifiedInsert | req 889 ms | hdr 855 ms | total 1490 ms | chars 18 | Codex | Codex | appClipboardPaste | net -
6:54:52 AM | unverifiedInsert | req 997 ms | hdr 962 ms | total 1590 ms | chars 18 | Codex | Codex | appClipboardPaste | net -
6:55:01 AM | unverifiedInsert | req 1326 ms | hdr 1290 ms | total 1900 ms | chars 35 | Codex | Codex | appClipboardPaste | net -
6:55:06 AM | unverifiedInsert | req 1966 ms | hdr 1930 ms | total 2520 ms | chars 27 | Codex | Codex | appClipboardPaste | net -
6:55:16 AM | unverifiedInsert | req 974 ms | hdr 931 ms | total 1571 ms | chars 26 | Codex | Codex | appClipboardPaste | net -
6:55:21 AM | transcriptionFailed | req 1013 ms | hdr 975 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:55:31 AM | unverifiedInsert | req 1047 ms | hdr 1013 ms | total 1632 ms | chars 21 | Codex | Codex | appClipboardPaste | net -
6:55:44 AM | unverifiedInsert | req 1220 ms | hdr 1185 ms | total 1803 ms | chars 9 | Codex | Codex | appClipboardPaste | net -
```
