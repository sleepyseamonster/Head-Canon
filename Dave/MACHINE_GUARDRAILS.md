# Local Machine Guardrails

This file tracks security-sensitive operations that affect the local Mac, not just the repo.

## High-Impact Areas
- login Keychain changes
- local certificate trust changes
- code-signing identity creation and use
- installed app replacement under `/Applications`
- macOS TCC state for microphone and Accessibility
- Gatekeeper and signing verification expectations

## Current Known Machine-Touching Scripts
- [Scripts/setup_local_codesign_identity.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/setup_local_codesign_identity.sh)
  Creates and trusts a local code-signing identity in the login Keychain.
- [Scripts/install_app.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/install_app.sh)
  Updates the installed runtime target used for real permission testing.
- [Scripts/build_app_bundle.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/build_app_bundle.sh)
  Chooses signing mode and can produce trusted or untrusted bundles depending on identity availability.
- [Scripts/verify_dist_app.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/verify_dist_app.sh)
  Verifies whether a build should be treated as trusted.

## Guardrails
- Do not assume a locally trusted self-signed identity is equivalent to a Developer ID release identity.
- Do not blur `dist/HeadCanon.app` and `/Applications/HeadCanon.app` when discussing permissions or trust.
- Treat Keychain trust modifications as machine-security changes and document them in a checkpoint when they occur.
- Prefer verification evidence from `codesign` and `spctl` over assumptions about build scripts.
- Do not store certificate exports, private keys, or other machine secrets in this repo.

## Review Questions
- What changed on the machine versus only in source?
- Which app bundle path is the trusted runtime for this checkpoint?
- What signing identity and Team ID are expected?
- Did any step modify the login Keychain or trust settings?
- Can the current runtime still be explained clearly to a future reviewer?
