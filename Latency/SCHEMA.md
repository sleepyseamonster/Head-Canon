# Latency Schemas

## Purpose
These schemas make latency artifacts consistent across sessions.

## `logs/activity.jsonl`
One JSON object per meaningful latency-focused action.

Fields:
- `timestamp`
- `actor`
- `action`
- `scope`
- `status`
- `evidence`
- `next_step`

## `logs/benchmarks.jsonl`
One JSON object per benchmark or timing capture.

Fields:
- `timestamp`
- `scenario`
- `build`
- `device`
- `path_segment`
- `sample_count`
- `metrics_ms`
- `result`
- `evidence`
- `notes`

## `logs/decisions.jsonl`
One JSON object per durable latency decision.

Fields:
- `timestamp`
- `decision`
- `reason`
- `impact`
- `source`

## Artifact Frontmatter
Use simple leading fields when useful:
- `date`
- `status`
- `owner`
- `purpose`
- `scenario`

## Status Values
- `draft`
- `in_progress`
- `blocked`
- `complete`
