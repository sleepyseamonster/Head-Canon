date: 2026-05-22
branch: main
status: complete
owner: GitHub Manager
purpose: Capture the May 22 SOP result for the main-branch reliability checkpoint

# Main SOP Checkpoint

## Baseline
- Current branch: `main`
- Upstream: `origin/main`
- Remote: `https://github.com/sleepyseamonster/Head-Canon.git`
- Baseline commit before this SOP batch: `de1db14`

## Landed Scope
- disk-space readiness thresholds, reserve handling, and diagnostics wiring
- recovery transcript UI visibility fixes in the menu and Settings
- richer transcription failure diagnostics including response-body metadata
- updated local runtime and usability docs
- new Builder and Latency artifacts describing the checkpoint and its verification context

## Verification
- `swift test`
- `swift Scripts/diagnostics.swift live`
- `sh Scripts/disk_health.sh`

## Audit
- The current batch is coherent around one product checkpoint: bounded dictation reliability and recovery hardening.
- Verification passed on the repo state being committed.
- Push target remains `main`, which matches the repo's default-branch workflow.

## Next Recommended Step
- Build and install `/Applications/HeadCanon.app`, then manually verify:
  - low-disk warning versus hard-block behavior
  - always-visible `Last Transcript` recovery UI states
  - no inserted-overlay re-entry regression during repeated dictation
