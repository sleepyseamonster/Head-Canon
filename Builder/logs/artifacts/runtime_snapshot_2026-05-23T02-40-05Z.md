# Runtime Snapshot

- Timestamp: 2026-05-23T02:40:05Z
- CWD: /Users/worldbuilder/Desktop/Head Canon

## App Path
```text
/Applications/HeadCanon.app
```

## Codesign
```text
Executable=/Applications/HeadCanon.app/Contents/MacOS/HeadCanon
Identifier=local.headcanon.app
Format=app bundle with Mach-O thin (arm64)
CodeDirectory v=20500 size=5428 flags=0x10000(runtime) hashes=159+7 location=embedded
VersionPlatform=1
VersionMin=917504
VersionSDK=1705216
Hash type=sha256 size=32
CandidateCDHash sha256=53ae1e1babe4ed464e74d24bb0462608cdda5a49
CandidateCDHashFull sha256=53ae1e1babe4ed464e74d24bb0462608cdda5a49cffd79c1112ef480054eadfe
Hash choices=sha256
CMSDigest=53ae1e1babe4ed464e74d24bb0462608cdda5a49cffd79c1112ef480054eadfe
CMSDigestType=2
Executable Segment base=0
Executable Segment limit=1032192
Executable Segment flags=0x1
Page size=16384
CDHash=53ae1e1babe4ed464e74d24bb0462608cdda5a49
Signature size=6203
Authority=HeadCanon Local Signing
Timestamp=May 22, 2026 at 7:39:50 PM
Info.plist entries=11
TeamIdentifier=not set
Runtime Version=26.5.0
Sealed Resources version=2 rules=13 files=2
Internal requirements count=1 size=96
```

## Running Processes
```text
49628
49642
```

## Recent TCC Requests
```text
Timestamp               Ty Process[PID:TID]
2026-05-22 19:30:07.920 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:30:12.702 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:30:14.990 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:30:16.911 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:30:17.856 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:30:20.107 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:31:17.818 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:32:01.534 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:33:22.153 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:33:57.727 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:34:15.791 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:35:44.951 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:36:34.842 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:37:08.895 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:37:19.982 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:37:19.982 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:37:25.979 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:37:40.493 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:38:09.266 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:39:19.727 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:39:46.871 A  HeadCanon[90336:1afc8a] (TCC) TCCAccessRequest() IPC
2026-05-22 19:39:58.621 A  HeadCanon[49628:26a6cd] (TCC) TCCAccessRequest() IPC
```

## User Defaults
```text
{
    "NSWindow Frame HeadCanon.SettingsRootView-1-AppWindow-1" = "237 161 900 647 0 0 1728 1084 ";
    accessibilityPrompted = 1;
    lastValidatedAPIKeyFingerprint = 5ef2022f9a793cad18435300d5da5c6add3172d825621d6bfe77b404e6a3903f;
    lastValidationDate = "2026-05-19 22:19:23 +0000";
    selectedMicrophoneID = BuiltInMicrophoneDevice;
}
```

## Git Status
```text
 M Scripts/diagnostics.swift
 M Scripts/verify_dist_app.sh
 M Sources/HeadCanon/App/HeadCanonModel.swift
 M Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift
 M Sources/HeadCanon/Diagnostics/LiveDiagnosticsRecord.swift
 M Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift
 M Sources/HeadCanon/Transcription/TranscriptionBackend.swift
 M Sources/HeadCanon/UI/MenuBarContentView.swift
 M Sources/HeadCanon/UI/SettingsRootView.swift
 M Tests/HeadCanonTests/HeadCanonTests.swift
 M docs/CURRENT_CHECKPOINT.md
 M docs/EXECUTION_PLAN.md
 M docs/LOCAL_RUNTIME.md
 M docs/USABILITY_CHECKLIST.md
?? Builder/logs/artifacts/runtime_snapshot_2026-05-23T02-40-05Z.md
?? Latency/artifacts/benchmark-2026-05-22T12-24-58-0700-speed-check.md
?? Latency/artifacts/benchmark-2026-05-22T19-38-01-0700-post-instrumentation-live-diagnostic.md
?? Scripts/disk_health.sh
?? Sources/HeadCanon/Diagnostics/DiskSpaceReadiness.swift
?? Sources/HeadCanon/Diagnostics/DiskSpaceReserve.swift
```
