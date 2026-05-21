# Builder Logs

This directory stores append-only structured logs and generated artifacts.

Files:
- `experiments.jsonl`
- `failures.jsonl`
- `checkpoints.jsonl`
- `artifacts/`

Rules:
- prefer appending over rewriting
- keep raw evidence references when possible
- do not store secrets
