# Latency

This folder stores durable latency-focused context for the `Head Canon` project.

Purpose:
- preserve high-signal performance knowledge across sessions
- keep latency investigations separate from general implementation notes
- save reusable benchmark artifacts, timing logs, and tuning decisions
- record measured evidence before optimization ideas

Files:
- [AGENT_INSTRUCTIONS.md](/Users/worldbuilder/Desktop/Head%20Canon/Latency/AGENT_INSTRUCTIONS.md)
  Operating rules for future latency-focused sessions in this repo.
- [MEMORY.md](/Users/worldbuilder/Desktop/Head%20Canon/Latency/MEMORY.md)
  Durable performance facts, bottlenecks, and current assumptions.
- [SCHEMA.md](/Users/worldbuilder/Desktop/Head%20Canon/Latency/SCHEMA.md)
  Structured formats for latency logs and artifacts.
- [bin](/Users/worldbuilder/Desktop/Head%20Canon/Latency/bin)
  Latency helper scripts for repeatable capture and reporting.
- [artifacts](/Users/worldbuilder/Desktop/Head%20Canon/Latency/artifacts)
  Saved benchmark reports, timing breakdowns, and experiment summaries.
- [logs](/Users/worldbuilder/Desktop/Head%20Canon/Latency/logs)
  Append-only activity, benchmark, and decision logs.

Operating rules:
- prefer measured timings over impressions
- separate observed latency from inferred cause
- include exact dates because performance state can drift quickly
- keep experiments reproducible when possible
- do not store secrets or raw user audio here
