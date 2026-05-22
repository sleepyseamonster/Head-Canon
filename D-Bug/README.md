# D-Bug

This folder stores D-Bug's durable debugging context for the `Head Canon` project.

Purpose:
- preserve high-signal debugging knowledge across sessions
- keep runtime findings separate from implementation churn
- save reusable artifacts for installed-app failures, regressions, and recovery steps
- record observed behavior before proposing fixes
- provide a stable home for D-Bug's operating instructions and memory

Files:
- [AGENT_INSTRUCTIONS.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/AGENT_INSTRUCTIONS.md)
  D-Bug's operating rules for debugging the repo and installed app.
- [MEMORY.md](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/MEMORY.md)
  Durable debugging facts, current suspects, and working assumptions.
- [logs](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/logs)
  Append-only checkpoint notes and debugging findings.
- [artifacts](/Users/worldbuilder/Desktop/Head%20Canon/D-Bug/artifacts)
  Saved non-sensitive artifacts from debugging passes.

Operating rules:
- prefer observed failures over theory
- include exact dates when runtime behavior may drift
- distinguish repo state from `/Applications/HeadCanon.app` behavior
- do not store secrets, raw audio, or transcript contents
- keep notes short, specific, and reusable
