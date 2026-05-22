date: 2026-05-21
branch: codex/headcanon-rebrand-diagnostics
status: in_progress
owner: GitHub Manager
purpose: Record the staged commit plan for the May 21 SOP execution

# SOP Commit Plan

## Frozen Baseline
- Current branch: `codex/headcanon-rebrand-diagnostics`
- Upstream: `origin/codex/headcanon-rebrand-diagnostics`
- Remote: `https://github.com/sleepyseamonster/Head-Canon.git`
- Baseline commit before staging: `364a15c`

## Classified Worktree

### Batch 1: Durable workspace artifacts
- `D-Bug/`
- `Dave/`
- `Latency/`
- `GitHubManager/MEMORY.md`
- `GitHubManager/logs/activity.jsonl`
- `GitHubManager/logs/decisions.jsonl`
- `GitHubManager/artifacts/checkpoint-2026-05-21-workspace-ready.md`
- `GitHubManager/artifacts/branch-2026-05-21-sop-plan.md`

Rationale:
- These changes create or extend durable repo-local workspaces and supporting artifacts.
- They do not alter product runtime behavior.

Verification:
- file review only

### Batch 2: Dictation hardening and diagnostics
- `Sources/HeadCanon/App/ClipboardWriter.swift`
- `Sources/HeadCanon/App/HeadCanonModel.swift`
- `Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift`
- `Sources/HeadCanon/Insertion/TextInsertionService.swift`
- `Sources/HeadCanon/Transcription/OpenAIBoundedTranscriptionBackend.swift`
- `Sources/HeadCanon/Transcription/TranscriptionBackend.swift`
- `Sources/HeadCanon/UI/SettingsRootView.swift`
- `Sources/HeadCanon/UI/StatusOverlayController.swift`
- `Scripts/analyze_focused_target.swift`
- `Scripts/diagnostics.swift`
- `Tests/HeadCanonTests/HeadCanonTests.swift`
- `docs/CURRENT_CHECKPOINT.md`
- `docs/EXECUTION_PLAN.md`
- `docs/USABILITY_CHECKLIST.md`
- `docs/V1_SPEC.md`

Rationale:
- These changes all support the same product checkpoint: bounded transcription hardening, richer transport diagnostics, and safer insertion handling for opaque editors such as `Codex`.

Verification:
- `swift test`
- `swift Scripts/diagnostics.swift summary 5`
- `swift Scripts/analyze_focused_target.swift --help` in an untrusted shell context should fail with an Accessibility read error rather than crash

## Audit
- The workspace-artifact batch is separable from the runtime batch without rewriting behavior history.
- The runtime batch already has passing automated coverage in `swift test`.
- No direct push to `main` is planned; the branch tracks a non-default upstream branch.

## Next Step
- Stage and commit Batch 1, then Batch 2, then verify push safety and push `codex/headcanon-rebrand-diagnostics`.
