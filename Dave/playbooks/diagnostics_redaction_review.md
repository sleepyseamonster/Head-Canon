# Diagnostics Redaction Review

Goal:
- verify that local diagnostics remain useful without retaining more sensitive content than intended

Review targets:
- [Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DiagnosticsStore.swift)
- [Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift](/Users/worldbuilder/Desktop/Head%20Canon/Sources/HeadCanon/Diagnostics/DictationAttemptRecord.swift)
- [Scripts/diagnostics.swift](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/diagnostics.swift)
- [docs/USABILITY_CHECKLIST.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/USABILITY_CHECKLIST.md)

Checklist:
1. Enumerate every persisted field in the record schema.
2. Mark each field as required, useful-but-sensitive, or unnecessary.
3. Confirm transcript text is not persisted by default.
4. Confirm reader output does not print secrets or transcript bodies.
5. Confirm file permissions and rotation policy match the intended retention level.
6. Record any field that could become sensitive when combined with other data.

Evidence to record:
- schema version reviewed
- fields confirmed safe by default
- fields needing minimization or gating
- diagnostic file permissions
- log rotation limits
