# Dave

This folder stores Dave's durable security memory, review artifacts, and operating instructions for the `Head Canon` project.

Purpose:
- preserve security-relevant context across sessions
- record durable facts about trust boundaries and data handling
- keep security notes separate from general implementation churn
- leave behind repeatable review artifacts instead of ephemeral chat-only memory
- provide the organizing layer for security ownership across code, scripts, docs, and local runtime procedures

Files:
- [MEMORY.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/MEMORY.md)
  Durable security facts, current risks, and working assumptions.
- [AGENT_INSTRUCTIONS.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/AGENT_INSTRUCTIONS.md)
  Dave's operating rules for reviewing, changing, and documenting security-sensitive work.
- [INVENTORY.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/INVENTORY.md)
  Repo-wide map of security-relevant source files, scripts, and docs.
- [RISK_REGISTER.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/RISK_REGISTER.md)
  Active security risks, current evidence, and next actions.
- [THREAT_MODEL.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/THREAT_MODEL.md)
  Assets, trust boundaries, abuse cases, and hard security expectations.
- [MACHINE_GUARDRAILS.md](/Users/worldbuilder/Desktop/Head%20Canon/Dave/MACHINE_GUARDRAILS.md)
  Rules for changes that affect the local Mac, installed app trust, TCC, Keychain, and signing.
- [playbooks](/Users/worldbuilder/Desktop/Head%20Canon/Dave/playbooks)
  Repeatable security review procedures for the highest-risk surfaces.
- [bin](/Users/worldbuilder/Desktop/Head%20Canon/Dave/bin)
  Small helper scripts for generating non-sensitive security workspace artifacts.
- [logs](/Users/worldbuilder/Desktop/Head%20Canon/Dave/logs)
  Append-only security checkpoints, findings, and generated artifacts.

Operating rules for Dave artifacts:
- record observed facts before recommendations
- include exact dates when runtime or policy state may drift
- keep source-state notes separate from installed-app behavior
- do not store secrets, tokens, raw audio, or pasted transcript content
- prefer small, reusable artifacts over large free-form notes

Scope rule:
- Security-relevant source files stay in their working code locations.
- `Dave/` is the ownership and organization layer that indexes them, records findings, and drives future hardening work.
