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
2. Copy the assigned extension ID.
3. Install the native host manifest with:
   - `./Scripts/install_chromium_companion.sh --extension-id <extension-id>`
4. Serve the local fixture page with:
   - `./Scripts/serve_browser_fixtures.sh --open`

This browser lane is still a scaffold. The installed app does not yet drive the companion end to end.

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
