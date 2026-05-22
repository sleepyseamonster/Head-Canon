date: 2026-05-21
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: live-state-postfix

# Latency Snapshot

Captured: `2026-05-21T19:41:14-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 939B0D47-BA7F-4DAF-9CDB-E2C14CC23C07
Completed: May 21, 2026 at 7:35:40 PM
State: failed
Truth State: recordingFailed
Hotkey: Hold Control + Option
App Class: Unknown
Request -> Response: Unknown
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
Failure Stage: recordingStop
Failure Message: Disk Full
```

## Live State
Command:
```bash
swift Scripts/diagnostics.swift live
```

Observed:
```text
Updated: May 21, 2026 at 7:39:53 PM
Session: 28ECE838-ECED-411B-AFE3-2D376C54A768
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
Last Event At: 7:39:51 PM
Recent Events:
- 7:39:51 PM | hotkey | info | Registered hotkey: Hold Control + Option
- 7:39:51 PM | none | info | Permissions updated: Microphone Granted · Accessibility Granted
- 7:39:51 PM | none | info | Bootstrapped app from /Applications/HeadCanon.app
```

## Recent 20 Summary
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Verified Inserts: 16
Unverified Inserts: 0
Failures: 4
Streaming Fallbacks: 9
Request -> Response p50: 2436 ms
Request -> Response p95: 30152 ms
Request -> Headers p50: 1332 ms
Request -> Headers p95: 2164 ms
Release -> Inserted p50: 2859 ms
Release -> Inserted p95: 22294 ms
Transcript Characters p50: 52
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
  Attempts: 5
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 5
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
  Attempts: 45
  Verified Inserts: 23
  Unverified Inserts: 0
  Failures: 22
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
  Attempts: 45
  Verified Inserts: 23
  Unverified Inserts: 0
  Failures: 22
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
  Verified Inserts: 0
  Unverified Inserts: 0
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
insertionFailed
  Attempts: 9
  Verified Inserts: 0
  Unverified Inserts: 0
  Failures: 9
  Streaming Fallbacks: 7
  Request -> Response p50: 2398 ms
  Request -> Response p95: 3171 ms
  Request -> Headers p50: 1096 ms
  Request -> Headers p95: 1738 ms
  Release -> Inserted p50: Unknown
  Release -> Inserted p95: Unknown
  Transcript Characters p50: 27
  Transcript Characters p95: 393
  Transcript Words p50: 5
  Transcript Words p95: 73
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
unsupportedTarget
  Attempts: 4
  Verified Inserts: 0
  Unverified Inserts: 0
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

## Recent 10 Timeline
Command:
```bash
swift Scripts/diagnostics.swift recent 10
```

Observed:
```text
6:01:46 PM | verifiedInsert | req 24015 ms | hdr 2078 ms | total 24595 ms | chars 54 | Codex | Codex | appClipboardPaste | net -
6:05:00 PM | transcriptionTimedOut | req 30198 ms | hdr ? ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:13:31 PM | verifiedInsert | req 2436 ms | hdr 2403 ms | total 3082 ms | chars 87 | Codex | Codex | appClipboardPaste | net -
6:14:44 PM | verifiedInsert | req 1728 ms | hdr 1689 ms | total 2316 ms | chars 30 | Codex | Codex | appClipboardPaste | net -
6:16:40 PM | verifiedInsert | req 1633 ms | hdr 1598 ms | total 2219 ms | chars 49 | Codex | Codex | appClipboardPaste | net -
6:16:46 PM | verifiedInsert | req 847 ms | hdr 810 ms | total 1434 ms | chars 31 | Codex | Codex | appClipboardPaste | net -
6:36:55 PM | verifiedInsert | req 1258 ms | hdr 1224 ms | total 1916 ms | chars 52 | Codex | Codex | appClipboardPaste | net -
6:39:53 PM | verifiedInsert | req 2200 ms | hdr 2164 ms | total 2783 ms | chars 13 | Codex | Codex | appClipboardPaste | net -
7:09:05 PM | verifiedInsert | req 1804 ms | hdr 1772 ms | total 2375 ms | chars 10 | Codex | Codex | appClipboardPaste | net -
7:35:40 PM | recordingFailed | req ? ms | hdr ? ms | total ? ms | chars ? | Unknown | Unknown App | unknown | net -
```
