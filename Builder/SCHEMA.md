# Builder Schemas

## Purpose
These schemas make Builder logs reusable across sessions.

## `logs/experiments.jsonl`
One JSON object per experiment attempt.

Fields:
- `timestamp`
- `goal`
- `actor`
- `bundle_path`
- `bundle_identifier`
- `signing_mode`
- `target_app`
- `action`
- `result`
- `failure_class`
- `confidence`
- `evidence`
- `next_step`

## `logs/failures.jsonl`
One JSON object per meaningful failure.

Fields:
- `timestamp`
- `failure_class`
- `summary`
- `bundle_path`
- `target_app`
- `observed`
- `suspected_cause`
- `evidence`
- `mitigation_attempted`
- `status`

## `logs/checkpoints.jsonl`
One JSON object per checkpoint note.

Fields:
- `timestamp`
- `checkpoint_goal`
- `tested`
- `happened`
- `ruled_out`
- `next_high_signal_step`

## Confidence Levels
- `high`
- `medium`
- `low`

## Failure Classes
- `permission/readiness`
- `hotkey`
- `recording start`
- `recording stop`
- `transcription`
- `insertion`
- `unknown`
