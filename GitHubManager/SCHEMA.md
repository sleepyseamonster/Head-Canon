# GitHub Manager Schemas

## Purpose
These schemas make repo-management artifacts consistent across sessions.

## `logs/activity.jsonl`
One JSON object per meaningful GitHub-management action.

Fields:
- `timestamp`
- `actor`
- `action`
- `scope`
- `branch`
- `status`
- `evidence`
- `next_step`

## `logs/decisions.jsonl`
One JSON object per durable workflow decision.

Fields:
- `timestamp`
- `decision`
- `reason`
- `impact`
- `source`

## Artifact Frontmatter
Use simple leading fields when useful:
- `date`
- `branch`
- `status`
- `owner`
- `purpose`

## Status Values
- `draft`
- `in_progress`
- `blocked`
- `complete`
