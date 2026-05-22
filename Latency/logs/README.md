# Latency Logs

This directory stores append-only latency logs.

Files:
- [activity.jsonl](/Users/worldbuilder/Desktop/Head%20Canon/Latency/logs/activity.jsonl)
  Chronological actions taken by the latency specialist.
- [benchmarks.jsonl](/Users/worldbuilder/Desktop/Head%20Canon/Latency/logs/benchmarks.jsonl)
  Measured timings and benchmark summaries.
- [decisions.jsonl](/Users/worldbuilder/Desktop/Head%20Canon/Latency/logs/decisions.jsonl)
  Durable performance decisions that future sessions should honor.

Rules:
- log observed state, not speculation
- keep entries short and concrete
- prefer append-only updates over rewriting history
- do not store secrets or raw audio
