---
date: 2026-05-22
status: complete
owner: Latency
purpose: Compare the known-good bounded baseline against the immediate timeout regression and capture the traced diagnostics inconsistency.
scenario: baseline-vs-timeout-regression
---

# Baseline vs Timeout Regression

Captured: `2026-05-22T06:31:13-0700`

This artifact compares:
- baseline: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/benchmark-2026-05-22T06-23-23-0700-known-good-bounded-baseline.md`
- regression: `/Users/worldbuilder/Desktop/Head Canon/Latency/artifacts/benchmark-2026-05-22T06-27-16-0700-quick-diagnostic.md`

## What Stayed Healthy

- The normal successful path remained fast.
- In the recent `50` model slice, `openai.gpt-4o-mini-transcribe` stayed at `request -> response p50 = 1276 ms` in the baseline and `1260 ms` in the regression snapshot.
- `release -> inserted p50` stayed effectively flat at `1916 ms` in the baseline and `1912 ms` in the regression snapshot.

## What Regressed

- The regression is concentrated in the timeout tail, not the median path.
- Recent `20` `request -> response p95` worsened from `8940 ms` to `30076 ms`.
- Recent `20` failures rose from `2` to `3`.
- The latest attempt in the regression snapshot hard-timed-out after `30081 ms`.
- `Codex` recent `50` app-class `request -> response p95` worsened from `8940 ms` to `21301 ms`.
- `Codex` recent `50` failures rose from `3` to `5`.

## Traced Diagnostics Inconsistency

The regression snapshot showed:

```text
Current Attempt: None
Active Transcription: 16CC441B-17BF-42D3-88E6-F5CC9285468C
Workflow: Needs Attention (failed)
```

That state is internally inconsistent and was traced to persistence ordering in `HeadCanonModel`:

- `setWorkflowStatus(.failed, ...)` persists live state immediately.
- `transcribeAndInsert(...)` clears `activeTranscriptionAttemptID` later in its `defer`.
- No follow-up live-state persistence happened after that cleanup.

Result:
- the persisted `live-state.json` could record a failed workflow with `currentAttemptID = nil` but still retain the stale `activeTranscriptionAttemptID`

## Fix Applied

Code fix:
- `/Users/worldbuilder/Desktop/Head Canon/Sources/HeadCanon/App/HeadCanonModel.swift`
- after clearing `activeTranscriptionAttemptID` in the `defer` block, the model now persists live state again so the final snapshot reflects the cleaned-up transcription state

Regression coverage:
- `/Users/worldbuilder/Desktop/Head Canon/Tests/HeadCanonTests/HeadCanonTests.swift`
- `Hung transcription times out and leaves transcribing state` now injects `RecordingDiagnosticsStore` and asserts the last persisted live-state record has `activeTranscriptionAttemptID == nil` and `workflowStatus == failed`

## Verification

Commands run:

```bash
swift build
swift test --filter hungTranscriptionTimesOut
```

Observed:
- `swift build` passed
- the focused timeout regression test passed

## Audit

- The baseline remains a valid fast-path reference point.
- The stale `Active Transcription` field was a real diagnostics bug and is now fixed.
- This fix improves the trustworthiness of the live diagnostics output, but it does not by itself explain or solve the underlying `~30s` transcription timeout tail.

## Next Step

- Capture a fresh live latency diagnostic after a real timeout or a longer mixed-turn session.
- Compare whether the live state now clears `Active Transcription` correctly on failure.
- Continue tracing the true timeout source separately from diagnostics cleanup, because the catastrophic tail is still the highest-risk latency issue.
