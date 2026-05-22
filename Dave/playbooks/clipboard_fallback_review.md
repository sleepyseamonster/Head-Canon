# Clipboard Fallback Review

Goal:
- verify that paste fallback is explicit, bounded, and as safe as the current product can make it

Review targets:
- [Sources/HeadCanon/Insertion/TextInsertionService.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Insertion/TextInsertionService.swift)
- [Sources/HeadCanon/App/ClipboardWriter.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/App/ClipboardWriter.swift)
- [docs/V1_SPEC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/V1_SPEC.md)

Checklist:
1. Confirm which app classes use direct insertion versus clipboard-based fallback.
2. Confirm secure text fields are blocked before any clipboard write.
3. Confirm focus is re-checked before posting paste events.
4. Confirm whether existing clipboard contents are preserved and restored.
5. Confirm manual transcript recovery still works when insertion is blocked.
6. Record exact behavior for `TextEdit`, `Codex`, and one browser textarea.

Evidence to record:
- chosen insertion strategy
- whether pasteboard contents were changed
- whether restore happened
- whether focus-drift protection blocked delivery
- whether transcript remained recoverable
