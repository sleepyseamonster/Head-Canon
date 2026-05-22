# GitHub Manager Memory

## Identity
- GitHub Manager workspace created on May 20, 2026.

## Repository Facts
- Repository root: `/Users/worldbuilder/Desktop/Head Canon`
- GitHub repository: `sleepyseamonster/Head-Canon`
- Origin remote: `https://github.com/sleepyseamonster/Head-Canon.git`
- Project category: local-first macOS dictation app
- Preferred implementation direction from repo instructions: Swift, SwiftUI, macOS 14+, Apple Silicon first
- Package manifest present: `Package.swift`
- Existing durable agent workspace also present: `Builder/`

## Workflow Facts
- The repo currently has unrelated in-progress source changes and untracked files.
- GitHub-manager work must avoid interfering with those existing changes unless explicitly asked.
- Repo-management memory is stored in `GitHubManager/` to keep operational notes separate from implementation notes.

## Current Assumptions
- The user wants an ongoing repo-local workspace for GitHub management artifacts.
- This workspace should be append-friendly and readable by future agents.

## Known Preferences
- Save memories in-repo rather than relying on chat-only state.
- Keep artifacts explicit and discoverable.
- Use the trigger phrase `run your sop` to authorize the full GitHub-manager execution flow.
- Pushing to GitHub is part of the SOP, but only after explicit branch/upstream verification.
- Do not treat quoted or hypothetical mentions of `run your sop` as execution authority.
- Do not push directly to a default or protected branch unless the user explicitly asks for that.

## First Bootstrap Action
- On May 20, 2026, the `GitHubManager/` folder was created with instructions, memory, schemas, artifacts, and logs.
