# Installed App Baseline

Captured: `2026-05-21T17:24:14-0700`
Bundle under test: `/Applications/HeadCanon.app`

## Latest Attempt
- Completed: `2026-05-21 17:23:31 -0700`
- State: `failed`
- App class: `Codex`
- Backend: `openai.gpt-4o-mini-transcribe`
- Mode: `Standard Completed Recording`
- Request -> Response: `3383 ms`
- Response Headers Received: `1671 ms`
- Planned strategy at release time: `appClipboardPaste`
- Planned strategy at insert time: `appClipboardPaste`
- Failure stage: `insertion`
- Failure message: `Head Canon could not verify the focused text field in this app, so it preserved the transcript instead of blindly pasting into a placeholder-prone composer. Transcript copied to clipboard for manual paste.`
- Clipboard recovery reason: `insertionSafetyBlock`

## Recent 20-Attempt Summary
- Attempts: `20`
- Failures: `19`
- Streaming fallbacks: `17`
- Request -> Response p50: `2656 ms`
- Request -> Response p95: `3674 ms`
- Request -> Headers p50: `1278 ms`
- Request -> Headers p95: `1845 ms`
- Release -> Inserted p50: `1784 ms`
- Release -> Inserted p95: `1784 ms`

## Recent 50-Attempt Summary By Failure
- `insertion`
  - attempts: `43`
  - failures: `43`
  - request -> response p50: `1684 ms`
  - request -> response p95: `4158 ms`
  - request -> headers p50: `1126 ms`
  - request -> headers p95: `1903 ms`
- `none`
  - attempts: `6`
  - failures: `0`
  - request -> response p50: `1350 ms`
  - request -> response p95: `9416 ms`
  - release -> inserted p50: `1729 ms`
  - release -> inserted p95: `9689 ms`
- `transcription`
  - attempts: `1`
  - failures: `1`
  - request -> response p50: `30177 ms`

## Audit
- The dominant live failure remains insertion-stage, not transcription-stage.
- The latest installed-app evidence still predates validation of the just-landed runtime changes.
- This artifact should be treated as the before snapshot for the next installed-app validation pass.
