date: 2026-05-21
status: reference
owner: D-Bug
scope: public Wispr Flow behavior relevant to Head Canon reliability

# Wispr Flow Reference Notes

## Sources Checked
- Wispr Flow docs: What is Flow?
  - `https://docs.wisprflow.ai/articles/2772472373-what-is-flow`
- Wispr Flow docs: Fix text not pasting after dictation
  - `https://docs.wisprflow.ai/articles/7971211038-fix-text-not-pasting-after-dictation`
- Wispr Flow docs: Supported & Unsupported Keyboard Hotkey Shortcuts
  - `https://docs.wisprflow.ai/articles/2612050838-supported-unsupported-keyboard-hotkey-shortcuts`
- Wispr Flow docs: Quit and relaunch Wispr Flow
  - `https://docs.wisprflow.ai/articles/7492559320-quit-and-relaunch-wispr-flow`
- Wispr Flow docs: Use Flow hands-free
  - `https://docs.wisprflow.ai/articles/6391241694-use-flow-hands-free`

## Relevant Product Patterns
- Flow is positioned as dictation that works in any text field, with live transcription and AI commands.
- Text insertion failures are treated separately from transcription failures.
- Recovery is explicit:
  - paste last transcript shortcut/menu item
  - copy button or recovery action when insertion fails
  - force quit/relaunch guidance for stuck listening states
- Public troubleshooting distinguishes:
  - transcription succeeded but text did not paste
  - wrong/old clipboard content pasted
  - hotkey activation delayed or dropped
  - app focus changes while dictation is in progress
  - stuck listening/no audio captured
- Flow documents platform-specific insertion edge cases and fixes, including cases where apps close or change the active field during dictation.

## Implications For Head Canon
- Keep the state taxonomy explicit:
  - recording stuck
  - transcription failed
  - transcription succeeded but insertion failed
  - insertion unverified
  - setup/permission blocked
- Preserve the local recovery controls already added:
  - `Paste Last Transcript`
  - `Finalize Recording Now`
  - `Cancel Current Dictation`
- Add any future “Retry Insert” or “Copy Transcript” action at the visible HUD/settings layer, not only in diagnostics.
- Treat `Scripts/diagnostics.swift live` as the equivalent of a support snapshot for stuck states; `latest` alone is insufficient.
- Continue testing arbitrary app text fields as a matrix rather than assuming one insertion path works everywhere.

## Non-Goals From This Research
- Do not clone Flow's product surface wholesale.
- Do not add cloud sync, teams, billing, or broad plugin architecture.
- Do not send audio/transcripts silently or store raw audio by default.
