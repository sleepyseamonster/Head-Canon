# Local Runtime Rules

`HeadCanon` must be treated as one installed app, not a moving build artifact.

## Where The Real App Lives

- runtime app path: `/Applications/HeadCanon.app`
- throwaway build artifact: `/Users/worldbuilder/Desktop/Head Canon/dist/HeadCanon.app`

Only the installed app should be opened for normal use.

## What Persists

- OpenAI API key state is stored by the app.
- Hotkey and local preferences are stored by the app.
- Microphone and Accessibility approvals are stored by macOS TCC for the installed app identity.

## What Breaks Persistence

- reinstalling an ad-hoc signed build
- replacing `/Applications/HeadCanon.app` with a newly rebuilt ad-hoc bundle
- launching or testing from `dist/HeadCanon.app`

When the app identity changes, macOS can treat it like a new app and ask for Microphone or Accessibility again.

## Normal User Workflow

1. Install once with `./Scripts/install_app.sh`
2. Open the installed app with `./Scripts/open_app.sh` or by clicking `/Applications/HeadCanon.app`
3. Do not reinstall unless intentionally updating the app

## Development Workflow

- `./Scripts/install_app.sh`
  - if no stable signing identity exists and the app is already installed, this opens the existing installed app instead of replacing it
  - if no stable signing identity exists and the app is not installed yet, the script now stops and requires an explicit signing setup step

## Browser Companion Scaffold

The Chromium browser companion currently ships as a local unpacked-extension scaffold.

Developer workflow:

1. Load `/Users/worldbuilder/Desktop/Head Canon/BrowserCompanion/Chromium` as an unpacked extension.
2. Install the native host manifest with:
   - `./Scripts/install_chromium_companion.sh`
3. The scaffold now pins a stable local development extension ID:
   - `cmjkhlmckbjapkhoecamfbemddfgkjbe`
4. Serve the local fixture page with:
   - `./Scripts/serve_browser_fixtures.sh --open`

Important note:

- the repo-local `./Scripts/run_chromium_fixture_matrix.sh` automation now proves the fixture page can launch in a temp Chrome profile, but Chrome still does not automatically activate the unpacked extension from that forced-profile path on this machine
- for now, real Chromium matrix evidence still requires a manual `Load unpacked` step in Chrome developer mode

This browser lane is now partially live:

- the installed app can detect Chromium native-host installation state
- the extension can persist real browser target snapshots into Head Canon diagnostics
- the app can prefer browser-companion insertion for eligible Chromium targets before falling back to AX or paste

What still is not done:

- the Safari scaffold exists, but it is not yet app-bridged or installed-app verified
- no installed-app browser matrix evidence yet
- no site-specific adapters for `ChatGPT`, `Gmail`, or `Google Docs`

## Stable Signing

Stable macOS permission persistence across updates requires one consistent signing identity for every rebuild.

This repo supports a local self-signed identity named `HeadCanon Local Signing`.
Create it once with:

`./Scripts/setup_local_codesign_identity.sh`

After that, `./Scripts/install_app.sh` and `./Scripts/build_app_bundle.sh` will prefer that identity automatically.

Trusted build verification now also requires an expected signer:

- `HEAD_CANON_EXPECTED_SIGNING_IDENTITY="HeadCanon Local Signing" ./Scripts/verify_dist_app.sh`
- or `HEAD_CANON_EXPECTED_TEAM_ID="<TEAMID>" ./Scripts/verify_dist_app.sh`

When the expected signer is the local self-signed `HeadCanon Local Signing` identity, `verify_dist_app.sh` treats a matching `codesign` identity plus a passing `codesign --verify` result as sufficient for local runtime checks even though Gatekeeper will still reject that build.
