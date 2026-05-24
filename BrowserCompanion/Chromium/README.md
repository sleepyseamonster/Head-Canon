# Head Canon Chromium Companion

This is the first unpacked Chromium companion scaffold for Head Canon.

What it does today:

- maintains a native-messaging connection to the local Head Canon stub host
- captures the focused editable browser target
- inserts into:
  - `input`
  - `textarea`
  - `contenteditable`
- emits explicit result states such as `inserted`, `unverifiedInsert`, `expired`, and `unsupported`

What it does not do yet:

- ship as a packaged browser extension
- register itself from the Head Canon app automatically
- support site-specific adapters for `ChatGPT`, `Gmail`, or `Google Docs`
- feed real page origin or frame identity back into the app through a live production path

## Local Development
1. Open `chrome://extensions` or the equivalent Chromium extensions page.
2. Enable `Developer mode`.
3. Click `Load unpacked`.
4. Select this folder:
   - `/Users/worldbuilder/Desktop/Head Canon/BrowserCompanion/Chromium`
5. Install the native host manifest:

```bash
./Scripts/install_chromium_companion.sh
```

The scaffold now pins a stable local development extension ID:

- `cmjkhlmckbjapkhoecamfbemddfgkjbe`

6. Optionally start the local browser fixtures:

```bash
./Scripts/serve_browser_fixtures.sh --open
```

7. Click the extension action while focused in a fixture field to log the focused target snapshot.

## Native Host Name

The scaffold currently uses:

- `local.headcanon.browser_companion`

## Fixture Coverage

The local fixture page covers:

- plain input
- textarea
- contenteditable
- iframe-backed editor
- shadow DOM editor
- secure field negative case
