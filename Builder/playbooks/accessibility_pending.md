# Playbook: Accessibility Pending Approval

## Trigger
- app shows `Pending Approval`
- Accessibility is not reaching `Granted`
- TCC checks repeat in logs

## Classification
- `permission/readiness`

## First Checks
1. Confirm the runtime app is `/Applications/HeadCanon.app`
2. Confirm `dist/HeadCanon.app` is not being used
3. Confirm the installed bundle identifier is `local.headcanon.app`
4. Confirm the app is not being reinstalled repeatedly during the same checkpoint

## Evidence To Gather
- screenshot of Accessibility settings
- app UI state for Microphone, Accessibility, OpenAI key
- recent `TCCAccessRequest()` log entries
- `codesign -dv --verbose=4 /Applications/HeadCanon.app`

## Known Good Commands
```bash
tccutil reset Accessibility local.headcanon.app
/usr/bin/log show --last 10m --predicate 'process == "HeadCanon" AND eventMessage CONTAINS[c] "TCCAccessRequest"' --style compact
codesign -dv --verbose=4 /Applications/HeadCanon.app 2>&1
```

## Recovery Sequence
1. quit `HeadCanon`
2. quit `System Settings`
3. reset Accessibility with `tccutil`
4. re-open `/Applications/HeadCanon.app`
5. prompt Accessibility again
6. enable `HeadCanon` in Accessibility settings
7. relaunch the installed app once
8. refresh app status

## Stop Conditions
- do not continue to hotkey or insertion debugging while trust is still ambiguous
- do not reinstall again unless intentionally updating the installed app
