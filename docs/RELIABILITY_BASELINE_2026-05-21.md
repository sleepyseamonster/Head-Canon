# Reliability Baseline

- Captured at: `2026-05-22T01:34:53Z`
- Runtime under test: `/Applications/HeadCanon.app`
- Host macOS: `26.5 (25F71)`
- Diagnostics source: `~/Library/Application Support/HeadCanon/diagnostics/`
- Dominant app class in the current log: `Codex`

## Current Metrics

Recent `100`-attempt summary from `Scripts/diagnostics.swift`:

- Attempts: `100`
- Failures: `73`
- Streaming fallbacks: `36`
- Request -> Response `p50`: `1857 ms`
- Request -> Response `p95`: `24015 ms`
- Request -> Headers `p50`: `1215 ms`
- Request -> Headers `p95`: `2403 ms`
- Release -> Inserted `p50`: `2816 ms`
- Release -> Inserted `p95`: `22294 ms`

## App-Class Split

- `Codex`
  - Attempts: `96`
  - Failures: `69`
  - Streaming fallbacks: `32`
  - Request -> Response `p50`: `1770 ms`
  - Request -> Response `p95`: `24015 ms`
  - Release -> Inserted `p50`: `2816 ms`
  - Release -> Inserted `p95`: `22294 ms`
- `Native`
  - Apps observed: `ChatGPT Atlas`
  - Attempts: `4`
  - Failures: `4`

## Failure Split

Recent `100`-attempt pre-truth-state summary:

- `insertion`: `64`
- `transcription`: `9`
- clean inserted records: `27`

## Audit

- This baseline is still heavily `Codex`-weighted, so it is useful for rollback and regression comparison but not yet for a full support claim.
- The tail remains the main risk: timeout-shaped transcription failures and insertion-path failures dominate far more than median latency.
- This artifact should stay unchanged while the truth-state model and insertion verification work land, so we can compare post-hardening behavior against the same starting point.
