# Dave Findings

## Open
- Clipboard fallback likely creates a temporary transcript exposure path through the system pasteboard and should be treated as a distinct security mode, not just a transport detail.
- Diagnostics persistence needs periodic review to confirm transcript text and sensitive identifiers are not being retained unnecessarily.
- Hosted transcription remains an explicit network boundary and product copy should stay synchronized with real behavior.
- Local code-signing and trust setup touches the machine Keychain and should be treated as a machine-security decision, not just a build convenience.
