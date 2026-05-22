# Builder

This folder stores Builder's durable memory, debugging artifacts, and training-oriented synthesis for the `Head Canon` project.

Purpose:
- preserve high-signal context across sessions
- record what was tried and what happened
- separate durable facts from speculative ideas
- improve future debugging speed for both the app and Builder

Files:
- [MEMORY.md](/Users/worldbuilder/Desktop/Head%20Canon/Builder/MEMORY.md)
  Durable project facts and current known constraints.
- [SESSION_2026-05-15_to_2026-05-16.md](/Users/worldbuilder/Desktop/Head%20Canon/Builder/SESSION_2026-05-15_to_2026-05-16.md)
  Chronological log of this conversation's work.
- [TRAINING_NOTES.md](/Users/worldbuilder/Desktop/Head%20Canon/Builder/TRAINING_NOTES.md)
  Agent lessons, app lessons, and structured failure patterns.
- [SCHEMA.md](/Users/worldbuilder/Desktop/Head%20Canon/Builder/SCHEMA.md)
  Structured logging formats for experiments, failures, and checkpoints.
- [playbooks](/Users/worldbuilder/Desktop/Head%20Canon/Builder/playbooks)
  Failure-specific debugging playbooks.
- [templates](/Users/worldbuilder/Desktop/Head%20Canon/Builder/templates)
  Reusable checkpoint and session templates.
- [bin](/Users/worldbuilder/Desktop/Head%20Canon/Builder/bin)
  Builder helper scripts for repeatable capture and logging.
- [logs](/Users/worldbuilder/Desktop/Head%20Canon/Builder/logs)
  Append-only structured logs and generated artifacts.
- [handoffs](/Users/worldbuilder/Desktop/Head%20Canon/Builder/handoffs)
  Full work prompts and implementation handoffs for Builder.

Operating rules for Builder artifacts:
- record observed facts before hypotheses
- keep exact dates when the state may drift over time
- distinguish source changes from installed-app runtime state
- prefer short, explicit pass/fail statements over vague summaries
- prefer append-only logs for experiments and failures
- use scripts in `Builder/bin` for repeatable capture where possible
