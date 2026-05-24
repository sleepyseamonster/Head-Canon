# Head Canon Safari Companion

This is the first Safari Web Extension scaffold for Head Canon.

What it does today:

- mirrors the same browser target taxonomy as the Chromium companion
- captures the focused editable browser target
- inserts into:
  - `input`
  - `textarea`
  - `contenteditable`
- emits the same truth-state result family:
  - `inserted`
  - `unverifiedInsert`
  - `expired`
  - `unsupported`
  - `failed`
- stores the latest focused target snapshot in extension-local storage for debugging

What it does not do yet:

- it is not yet embedded in a signed Safari app extension target
- it is not yet connected to Head Canon through an app-to-extension bridge
- it does not yet have installed-app matrix evidence
- it does not yet have site-specific adapters for `ChatGPT`, `Gmail`, or `Google Docs`

## Local Development

1. Keep using the shared fixture page:

```bash
./Scripts/serve_browser_fixtures.sh --open
```

2. Use Safari's Web Extension development flow to load the contents of:

- `/Users/worldbuilder/Desktop/Head Canon/BrowserCompanion/Safari`

3. Confirm the scaffold can classify and insert into the same generic fixture set as Chromium:

- plain input
- textarea
- contenteditable
- iframe-backed editor
- shadow DOM editor
- secure field negative case

## Architecture Note

The Safari scaffold intentionally keeps the same protocol shape and truth-state model as the Chromium lane. The missing piece is transport, not target taxonomy.
