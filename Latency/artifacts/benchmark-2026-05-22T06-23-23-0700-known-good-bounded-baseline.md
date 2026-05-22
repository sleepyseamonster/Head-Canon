date: 2026-05-22
status: complete
owner: Latency
purpose: Persist a dated latency snapshot from the local diagnostics log.
scenario: known-good-bounded-baseline

# Latency Snapshot

Captured: `2026-05-22T06:23:23-0700`

This artifact snapshots the current persisted diagnostics log. It does not generate new dictation turns by itself.

## Latest Attempt
Command:
```bash
swift Scripts/diagnostics.swift latest
```

Observed:
```text
Attempt: 6D8BACC0-A3CA-4090-977A-09445D867266
Completed: May 22, 2026 at 6:22:30 AM
State: inserted
Truth State: unverifiedInsert
Hotkey: Hold Control + Option
App Class: Codex
Request -> Response: 1487 ms
Release -> Inserted: 2061 ms
Transcript Characters: 185
Transcript Words: 32
Backend: openai.gpt-4o-mini-transcribe
Mode: Standard Completed Recording
Fallback: No
HTTP Status: 200
Request ID: req_32adeaca1aaf446daf9dc2c4d7af0780
OpenAI Processing: 914 ms
Content Type: text/plain; charset=utf-8
Response Headers Received: 1452 ms
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
Updated: May 22, 2026 at 6:23:23 AM
Session: 28ECE838-ECED-411B-AFE3-2D376C54A768
Current Attempt: None
Workflow: Ready (ready)
Ready: Yes
Audio Capture Recording: No
Hotkey: Hold Control + Option
Hotkey Physically Pressed: No
Active Transcription: None
Last Failure Stage: transcription
Last Truth State: unverifiedInsert
Last Error: None
Recording Started: 6:22:09 AM
Hotkey Released: 6:22:28 AM
Finalizing Shown: 6:22:28 AM
Recording Finalized: 6:22:28 AM
Transcription Started: 6:22:28 AM
Insertion Completed: 6:22:30 AM
Stop Trigger: globalModifierMonitor
Last Event: Head Canon pasted into the intended target context, but could not verify the resulting field contents.
Last Event Stage: insertion
Last Event Failed: No
Last Event At: 6:22:30 AM
Recent Events:
- 6:22:30 AM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
- 6:22:30 AM | transcription | info | Transcription succeeded via openai.gpt-4o-mini-transcribe. 185 chars · 32 words from 18.85s.
- 6:22:28 AM | transcription | info | Transcription request started with a 30 second timeout.
- 6:22:28 AM | recordingStop | info | Recording finalized via Global Modifier Monitor. Clip 18.85s · 180 KB. Starting transcription.
- 6:22:28 AM | hotkey | info | Hotkey released via Global Modifier Monitor. Moving into recording finalization.
- 6:22:09 AM | recordingStart | info | Recording started from the global hotkey.
- 6:22:09 AM | hotkey | info | Observed hotkey press.
- 6:21:55 AM | insertion | info | Head Canon pasted into the intended target context, but could not verify the resulting field contents.
```

## Current Settings Snapshot
Observed from the persisted preferences domain:
```bash
defaults read local.headcanon.app
```

Observed:
```text
{
    "NSWindow Frame HeadCanon.SettingsRootView-1-AppWindow-1" = "237 161 900 647 0 0 1728 1084 ";
    accessibilityPrompted = 1;
    lastValidatedAPIKeyFingerprint = 5ef2022f9a793cad18435300d5da5c6add3172d825621d6bfe77b404e6a3903f;
    lastValidationDate = "2026-05-19 22:19:23 +0000";
    selectedMicrophoneID = BuiltInMicrophoneDevice;
}
```

Inferred current settings from the persisted domain plus `AppPreferences` defaults:
- runtime app path: `/Applications/HeadCanon.app`
- hotkey: `Hold Control + Option`
- transcription backend: `openai.gpt-4o-mini-transcribe`
- request mode: `Standard Completed Recording`
- insertion route in current healthy slice: `Codex` via `appClipboardPaste`
- selected microphone: `BuiltInMicrophoneDevice`
- paste fallback: enabled by default because no override is stored
- history retention: session-only default because no override is stored
- API key validation cache present with last validation at `2026-05-19 22:19:23 +0000`

## Recent 20 Summary
Command:
```bash
swift Scripts/diagnostics.swift summary 20
```

Observed:
```text
Attempts: 20
Verified Inserts: 0
Unverified Inserts: 18
Failures: 2
Streaming Fallbacks: 0
Request -> Response p50: 1487 ms
Request -> Response p95: 8940 ms
Request -> Headers p50: 1282 ms
Request -> Headers p95: 1993 ms
Release -> Inserted p50: 2225 ms
Release -> Inserted p95: 9515 ms
Transcript Characters p50: 107
Transcript Characters p95: 245
Transcript Words p50: 19
Transcript Words p95: 39
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
openai.gpt-4o-mini-transcribe
  Attempts: 46
  Verified Inserts: 6
  Unverified Inserts: 40
  Failures: 0
  Streaming Fallbacks: 0
  Request -> Response p50: 1276 ms
  Request -> Response p95: 8940 ms
  Request -> Headers p50: 1108 ms
  Request -> Headers p95: 2164 ms
  Release -> Inserted p50: 1916 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 59
  Transcript Characters p95: 224
  Transcript Words p50: 12
  Transcript Words p95: 38
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
  Verified Inserts: 6
  Unverified Inserts: 40
  Failures: 3
  Streaming Fallbacks: 0
  Request -> Response p50: 1276 ms
  Request -> Response p95: 8940 ms
  Request -> Headers p50: 1108 ms
  Request -> Headers p95: 2164 ms
  Release -> Inserted p50: 1916 ms
  Release -> Inserted p95: 9515 ms
  Transcript Characters p50: 59
  Transcript Characters p95: 224
  Transcript Words p50: 12
  Transcript Words p95: 38
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
```

## Recent 10 Timeline
Command:
```bash
swift Scripts/diagnostics.swift recent 10
```

Observed:
```text
8:07:17 PM | unverifiedInsert | req 1769 ms | hdr 1735 ms | total 2324 ms | chars 139 | Codex | Codex | appClipboardPaste | net -
8:10:23 PM | unverifiedInsert | req 8940 ms | hdr 916 ms | total 9515 ms | chars 113 | Codex | Codex | appClipboardPaste | net -
6:10:08 AM | unverifiedInsert | req 1872 ms | hdr 1837 ms | total 2500 ms | chars 74 | Codex | Codex | appClipboardPaste | net -
6:10:25 AM | transcriptionFailed | req 1315 ms | hdr 1286 ms | total ? ms | chars ? | Codex | Codex | appClipboardPaste | net -
6:11:23 AM | unverifiedInsert | req 1738 ms | hdr 1700 ms | total 2303 ms | chars 8 | Codex | Codex | appClipboardPaste | net -
6:21:17 AM | unverifiedInsert | req 2037 ms | hdr 1993 ms | total 2609 ms | chars 153 | Codex | Codex | appClipboardPaste | net -
6:21:34 AM | unverifiedInsert | req 1828 ms | hdr 1791 ms | total 2418 ms | chars 107 | Codex | Codex | appClipboardPaste | net -
6:21:50 AM | unverifiedInsert | req 1276 ms | hdr 1243 ms | total 1867 ms | chars 18 | Codex | Codex | appClipboardPaste | net -
6:21:55 AM | unverifiedInsert | req 909 ms | hdr 867 ms | total 1502 ms | chars 15 | Codex | Codex | appClipboardPaste | net -
6:22:30 AM | unverifiedInsert | req 1487 ms | hdr 1452 ms | total 2061 ms | chars 185 | Codex | Codex | appClipboardPaste | net -
```

## Baseline Read
- This is the current known-good bounded-path baseline for `Codex` on May 22, 2026.
- Median hosted transcription is strong in the recent slice: `request -> response p50 = 1276-1487 ms` depending on window, with `request -> headers p50 = 1108-1282 ms`.
- User-perceived latency is also strong in the recent slice: `release -> inserted p50 = 1916-2225 ms`.
- Tail latency is improved versus the earlier unstable snapshots, but not eliminated: recent `20` `request -> response p95 = 8940 ms` and `release -> inserted p95 = 9515 ms`.
- The current slice is almost entirely `Codex`, and most successful turns are still `unverifiedInsert` rather than fully verified field-state confirmations.
