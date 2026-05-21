# Builder Training Notes

## Purpose
This file is structured as training-oriented synthesis for future Builder sessions.

## Durable Lessons For Builder

### 1. Separate source truth from runtime truth
Observed pattern:
- source can compile and test cleanly
- installed app can still be blocked by macOS permissions

Training implication:
- always state whether a claim is about source, build, or installed runtime

### 2. TCC ambiguity must be treated as a primary blocker
Observed pattern:
- repeated `TCCAccessRequest() IPC`
- no granted log
- UI remains pending

Training implication:
- do not continue downstream debugging when Accessibility trust is still ambiguous

### 3. Narrow the target aggressively
Observed pattern:
- broad “is the app usable?” questions can explode into scope drift

Training implication:
- reduce to one bundle path, one target app, one pass/fail question

### 4. Improve observability before speculative fixes
Observed pattern:
- without stage-based diagnostics, many failures look identical

Training implication:
- if the failure stage is unclear, add minimal in-app diagnostics before deeper platform work

### 5. UI button failures are often implementation failures, not user failures
Observed pattern:
- user reported `Relaunch` did nothing
- actual issue was the relaunch code path

Training implication:
- trust direct user reports about UI deadness and inspect handler implementation quickly

## Structured Failure Cases

### Case A
- Trigger:
  Accessibility appears configured by the user but app still shows `Pending Approval`
- Symptoms:
  repeated TCC requests
  no granted logs
  no end-to-end progress
- Correct classification:
  `permission/readiness`
- First actions:
  reset TCC
  keep installed app path stable
  avoid reinstall churn

### Case B
- Trigger:
  App exposes `Relaunch` but nothing visible happens
- Symptoms:
  no new instance
  no old instance exit
- Correct classification:
  `permission/readiness` support-path bug
- First actions:
  inspect relaunch implementation
  switch to deterministic relaunch command

## App Improvement Opportunities
- Add explicit UI text that distinguishes:
  - app requested trust
  - macOS has not granted trust
  - app must be relaunched after trust
- Add a visible timestamp for the last permission refresh
- Add a visible diagnostic event when `Relaunch` is requested
- Consider a one-time “copy exact app path” affordance near Accessibility guidance
- Consider gating repeated TCC polling to reduce noise when the app is already in a known pending state

## Agent Improvement Opportunities
- When the user asks for “audit and rewrite,” preserve the prior reasoning but compress scope faster
- When the user asks whether the app is usable, distinguish:
  - launchable
  - configurable
  - core loop proven
- Prefer turning ephemeral reasoning into durable repo artifacts early when debugging spans multiple turns or days

## Current Confidence Snapshot
- High confidence:
  source changes made in this session compile and test cleanly
- Medium confidence:
  microphone and API key setup are mostly functioning
- Low confidence:
  Accessibility trust will stabilize under the current ad-hoc signing setup without repeated friction
