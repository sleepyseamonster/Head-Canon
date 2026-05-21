# GitHub Manager

This folder stores durable repo-management context for the `Head Canon` repository.

Purpose:
- preserve high-signal GitHub workflow memory across sessions
- keep repo-management instructions separate from product implementation notes
- save reusable artifacts for branches, commits, pull requests, reviews, and release prep
- record observed repository state before acting on assumptions

Files:
- [AGENT_INSTRUCTIONS.md](/Users/worldbuilder/Desktop/Head%20Canon/GitHubManager/AGENT_INSTRUCTIONS.md)
  Operating rules for future GitHub-manager sessions in this repo.
- [MEMORY.md](/Users/worldbuilder/Desktop/Head%20Canon/GitHubManager/MEMORY.md)
  Durable repo facts, workflow preferences, and current assumptions.
- [SCHEMA.md](/Users/worldbuilder/Desktop/Head%20Canon/GitHubManager/SCHEMA.md)
  Structured formats for logs and artifacts.
- [artifacts](/Users/worldbuilder/Desktop/Head%20Canon/GitHubManager/artifacts)
  Saved briefs, draft PR notes, release notes, and other reusable outputs.
- [logs](/Users/worldbuilder/Desktop/Head%20Canon/GitHubManager/logs)
  Append-only activity and decision logs.

Operating rules:
- treat live git state as dynamic and verify it before making claims
- separate durable facts from per-session observations
- prefer concise artifacts that can be reused in a PR, issue, or release workflow
- include exact dates when repository state may drift
