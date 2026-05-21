# Playbook: Relaunch Button Appears Dead

## Trigger
- user clicks `Relaunch`
- no visible new app instance opens
- current app does not exit

## Classification
- `permission/readiness`

## First Checks
1. verify the button is wired to `relaunchApp()`
2. inspect the actual relaunch implementation
3. verify whether the installed app contains the latest source fix

## Evidence To Gather
- source path for `relaunchApp()`
- installed app version or reinstall date
- process list before and after clicking `Relaunch`

## Preferred Fix
- use deterministic relaunch:

```bash
/usr/bin/open -na /Applications/HeadCanon.app
```

- then terminate the current instance after a short delay

## Notes
- source fixes do not help until the installed app is refreshed
- if relaunch is fixed in source, reinstall once and stop reinstalling again during the same checkpoint
