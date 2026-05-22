# Release Trust Review

Goal:
- verify whether a built bundle should be treated as trusted on the local Mac

Review targets:
- [Scripts/build_app_bundle.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/build_app_bundle.sh)
- [Scripts/verify_dist_app.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/verify_dist_app.sh)
- [Scripts/setup_local_codesign_identity.sh](/Users/worldbuilder/Desktop/Head%20Canon/Scripts/setup_local_codesign_identity.sh)
- [docs/LOCAL_RUNTIME.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/LOCAL_RUNTIME.md)
- [docs/SECURITY_RUBRIC.md](/Users/worldbuilder/Desktop/Head%20Canon/docs/SECURITY_RUBRIC.md)

Checklist:
1. Record the bundle path under review.
2. Record the expected signing identity and expected Team ID.
3. Inspect whether the build is ad-hoc, locally trusted, or Developer ID signed.
4. Record whether the process modified the login Keychain or trust configuration.
5. Run verification and record `codesign` and `spctl` results.
6. State whether the bundle is trusted for:
   - packaging only
   - local permission testing
   - release-style verification

Evidence to record:
- exact app bundle path
- actual signing identity
- actual Team ID
- Gatekeeper assessment result
- machine-impact notes
