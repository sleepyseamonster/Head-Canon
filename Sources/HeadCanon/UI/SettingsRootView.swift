import SwiftUI

@MainActor
struct SettingsRootView: View {
    @Bindable var model: HeadCanonModel
    @State private var apiKeyDraft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                OnboardingChecklistView(model: model)
                if !model.setupBlockers.isEmpty {
                    setupBlockerPanel
                }
                if let lastErrorMessage = model.lastErrorMessage, !lastErrorMessage.isEmpty {
                    errorPanel(lastErrorMessage)
                }
                recoveryTranscriptPanel
                settingsForm
                setupHelp
                diagnosticsPanel
                verificationMatrix
            }
            .padding(24)
        }
        .onAppear {
            apiKeyDraft = ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 14) {
                    AppLogoView(size: 54, cornerRadius: 14)

                    Text("Head Canon v1")
                        .font(.largeTitle.weight(.semibold))
                }

                Spacer()
                Button("Refresh Status") {
                    model.requestStatusRefresh()
                }
                StatusBadgeView(title: model.workflowStatus.title)
            }

            Text("Bounded push-to-talk dictation for macOS with explicit setup, API key validation, and insertion fallbacks.")
                .foregroundStyle(.secondary)
        }
    }

    private var setupBlockerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dictation is blocked until setup is complete.")
                .font(.headline)

            ForEach(model.setupBlockers) { blocker in
                VStack(alignment: .leading, spacing: 4) {
                    Text(blocker.title)
                        .font(.subheadline.weight(.semibold))
                    Text(blocker.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var settingsForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("OpenAI") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Head Canon v1 uses an OpenAI-hosted transcription backend. Audio is not sent off-device silently, but this backend is network-backed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Picker(
                        "Transcription Model",
                        selection: Binding(
                            get: { model.preferences.openAITranscriptionModel },
                            set: { model.preferences.openAITranscriptionModel = $0 }
                        )
                    ) {
                        ForEach(OpenAITranscriptionModel.allCases) { transcriptionModel in
                            Text(transcriptionModel.title).tag(transcriptionModel)
                        }
                    }

                    Text(model.preferences.openAITranscriptionModel.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    SecureField("Paste OpenAI API key", text: $apiKeyDraft)

                    HStack {
                        Button("Save Key") {
                            let value = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !value.isEmpty else { return }

                            Task {
                                await model.saveAPIKey(value)
                                apiKeyDraft = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Remove Key") {
                            model.removeAPIKey()
                        }

                        Button("Validate Key") {
                            Task {
                                await model.validateAPIKeyRemotely()
                            }
                        }

                        Spacer()

                        Text(model.apiKeyState.title)
                            .foregroundStyle(.secondary)
                    }

                    if let lastValidationDate = model.lastValidationDate {
                        Text("Last validation: \(lastValidationDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 6)
            }

            GroupBox("Input") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker(
                        "Hotkey",
                        selection: Binding(
                            get: { model.preferences.hotkey.identifier },
                            set: { identifier in
                                model.setHotkey(HotkeyShortcut.fromStoredIdentifier(identifier.rawValue))
                            }
                        )
                    ) {
                        ForEach(HotkeyShortcut.allShortcuts, id: \.identifier) { shortcut in
                            Text(shortcut.displayString).tag(shortcut.identifier)
                        }
                    }

                    Button("Reset Hotkey to Default") {
                        model.resetHotkeyToDefault()
                    }

                    Picker(
                        "Microphone",
                        selection: Binding(
                            get: { model.preferences.selectedMicrophoneID },
                            set: { model.preferences.selectedMicrophoneID = $0 }
                        )
                    ) {
                        Text("System Default").tag(Optional<String>.none)
                        ForEach(model.availableMicrophones) { device in
                            Text(device.name).tag(Optional(device.id))
                        }
                    }

                    Text("Choose a microphone explicitly, or leave System Default to follow the macOS default input.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            }

            GroupBox("System Readiness") {
                VStack(alignment: .leading, spacing: 12) {
                    diagnosticsFact("Microphone", model.permissionSnapshot.microphone.title)
                    diagnosticsFact("Accessibility", model.permissionSnapshot.accessibility.title)
                    diagnosticsFact("OpenAI Key", model.apiKeyState.title)
                    diagnosticsFact("Disk", model.diskSpaceReadiness?.status.title ?? "Unknown")
                    diagnosticsFact("Free Space", model.diskSpaceReadiness?.freeSpaceLabel ?? "Unknown")
                    diagnosticsFact("Reserve", model.diskSpaceReadiness?.reservation.status.title ?? "Unknown")
                    diagnosticsFact("Reserved Space", model.diskSpaceReadiness?.reservation.reservedSpaceLabel ?? "Unknown")

                    if let diskSpaceWarningMessage = model.diskSpaceWarningMessage {
                        Text(diskSpaceWarningMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if let blockingMessage = model.diskSpaceReadiness?.blockingMessage {
                        Text(blockingMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let diskSpaceReserveSummary = model.diskSpaceReserveSummary {
                        Text(diskSpaceReserveSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 6)
            }

            GroupBox("App Identity") {
                VStack(alignment: .leading, spacing: 12) {
                    if let runtimeWarningMessage = model.runtimeWarningMessage {
                        Text(runtimeWarningMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Head Canon must be granted permissions for this exact app bundle:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(model.currentAppPath)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)

                    HStack {
                        Button("Copy App Path") {
                            model.copyAppPath()
                        }

                        Button("Reveal In Finder") {
                            model.revealAppInFinder()
                        }

                        Button("Relaunch App") {
                            model.relaunchApp()
                        }

                        Spacer()
                    }
                }
                .padding(.top, 6)
            }

            GroupBox("History & Fallbacks") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker(
                        "Transcript Retention",
                        selection: Binding(
                            get: { model.preferences.historyRetentionMode },
                            set: {
                                model.preferences.historyRetentionMode = $0
                                model.applyPrivacyPreferences()
                            }
                        )
                    ) {
                        ForEach(HistoryRetentionMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    Text(model.historyRetentionSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Toggle(
                        "Allow paste-based insertion when required",
                        isOn: Binding(
                            get: { model.preferences.pasteFallbackEnabled },
                            set: { model.preferences.pasteFallbackEnabled = $0 }
                        )
                    )

                    HStack {
                        Button("Paste Last Transcript") {
                            model.pasteLastTranscript()
                        }
                        .disabled(model.lastTranscript?.isEmpty ?? true)

                        Button("Copy Last Transcript") {
                            model.copyLastTranscript()
                        }
                        .disabled(model.lastTranscript?.isEmpty ?? true)
                    }

                    Button("Clear Last Transcript") {
                        model.clearLastTranscript()
                    }
                    .disabled(model.lastTranscript?.isEmpty ?? true)
                }
                .padding(.top, 6)
            }
        }
    }

    private var hasRetainedTranscript: Bool {
        !(model.lastTranscript?.isEmpty ?? true)
    }

    private var recoveryTranscriptDisplayText: String {
        if let lastTranscript = model.lastTranscript, !lastTranscript.isEmpty {
            return lastTranscript
        }

        if model.preferences.historyRetentionMode == .neverStore {
            return "Transcript retention is off."
        }

        return "No retained transcript yet."
    }

    private var recoveryTranscriptStatusText: String {
        if hasRetainedTranscript {
            return "The latest retained transcript is available to copy or paste manually."
        }

        if model.preferences.historyRetentionMode == .neverStore {
            return "Turn on transcript retention if you want a manual recovery copy after each dictation."
        }

        return "This area stays visible so the recovery path is predictable. The next successful transcription will appear here."
    }

    private var recoveryTranscriptPanel: some View {
        GroupBox("Last Transcript") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Text(recoveryTranscriptStatusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 12)

                    Button {
                        model.copyLastTranscript()
                    } label: {
                        Label("Copy Transcript", systemImage: "doc.on.doc.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.lastTranscript?.isEmpty ?? true)
                }

                ScrollView {
                    Text(recoveryTranscriptDisplayText)
                        .font(.body)
                        .foregroundStyle(hasRetainedTranscript ? .primary : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 220, maxHeight: 320)
                .padding(14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.secondary.opacity(0.25))
                }
                .accessibilityIdentifier("last-transcript-recovery-text")

                HStack {
                    Button("Paste Last Transcript") {
                        model.pasteLastTranscript()
                    }
                    .disabled(model.lastTranscript?.isEmpty ?? true)

                    Button("Copy Last Transcript") {
                        model.copyLastTranscript()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.lastTranscript?.isEmpty ?? true)

                    Button("Clear Last Transcript") {
                        model.clearLastTranscript()
                    }
                    .disabled(model.lastTranscript?.isEmpty ?? true)

                    Spacer()
                }
            }
            .padding(.top, 6)
        }
    }

    private var setupHelp: some View {
        GroupBox("Setup Help") {
            VStack(alignment: .leading, spacing: 12) {
                Text("If Accessibility keeps showing Pending Approval or never flips to Granted, grant access to this exact app bundle, then relaunch and refresh:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(model.currentAppPath)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommended steps")
                        .font(.subheadline.weight(.semibold))
                    Text("1. Click Open Accessibility Settings.")
                    Text("2. Remove old HeadCanon entries if needed.")
                    Text("3. Add or re-enable this exact installed app bundle.")
                    Text("4. Relaunch the existing installed bundle without rebuilding or replacing it.")
                    Text("5. Return here, then click Refresh Status.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("Use one signed app bundle in `/Applications` for permission testing. Replacing an ad-hoc build can invalidate Accessibility approval even when HeadCanon still appears enabled in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("Open Accessibility Settings") {
                        model.openAccessibilitySettings()
                    }

                    Button("Open Microphone Settings") {
                        model.openMicrophoneSettings()
                    }

                    Button("Open System Settings") {
                        model.openSystemSettings()
                    }

                    Spacer()
                }
            }
            .padding(.top, 6)
        }
    }

    private var verificationMatrix: some View {
        GroupBox("v1 Verification Targets") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Track direct insertion and paste-fallback behavior against these target apps during implementation:")
                    .foregroundStyle(.secondary)

                ForEach([
                    "TextEdit",
                    "Notes",
                    "Slack message composer",
                    "Google Docs or Chrome textarea",
                    "Terminal",
                    "One Electron app target"
                ], id: \.self) { target in
                    HStack {
                        Image(systemName: "circle.dotted")
                            .foregroundStyle(.secondary)
                        Text(target)
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    private var diagnosticsPanel: some View {
        GroupBox("Diagnostics") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Accessibility Diagnosis")
                        .font(.subheadline.weight(.semibold))
                    Text(model.permissionDebugSnapshot.diagnosis.title)
                        .font(.subheadline)
                    Text(model.permissionDebugSnapshot.diagnosis.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Next action: \(model.permissionDebugSnapshot.diagnosis.nextAction)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Observed Facts")
                        .font(.subheadline.weight(.semibold))
                    diagnosticsFact("Bundle Path", model.permissionDebugSnapshot.bundlePath)
                    diagnosticsFact("Bundle Identifier", model.permissionDebugSnapshot.bundleIdentifier)
                    diagnosticsFact("Installed Bundle", model.permissionDebugSnapshot.isInstalledBundle ? "Yes" : "No")
                    diagnosticsFact("Microphone", model.permissionDebugSnapshot.microphoneState.title)
                    diagnosticsFact("Accessibility", model.permissionDebugSnapshot.accessibilityState.title)
                    diagnosticsFact("Disk", model.diskSpaceReadiness?.status.title ?? "Unknown")
                    diagnosticsFact("Free Space", model.diskSpaceReadiness?.freeSpaceLabel ?? "Unknown")
                    diagnosticsFact("Reserve", model.diskSpaceReadiness?.reservation.status.title ?? "Unknown")
                    diagnosticsFact("Reserved Space", model.diskSpaceReadiness?.reservation.reservedSpaceLabel ?? "Unknown")
                    diagnosticsFact("AX Trust Check", model.permissionDebugSnapshot.accessibilityTrusted ? "True" : "False")
                    diagnosticsFact("Accessibility Prompted", model.permissionDebugSnapshot.accessibilityPrompted ? "Yes" : "No")
                    diagnosticsFact("Relaunch Requested", model.permissionDebugSnapshot.accessibilityRelaunchRequested ? "Yes" : "No")
                    diagnosticsFact(
                        "Last Permission Refresh",
                        model.permissionDebugSnapshot.lastPermissionRefreshDate?.formatted(date: .omitted, time: .standard) ?? "Never"
                    )
                    diagnosticsFact(
                        "Last Self-Test Run",
                        model.permissionDebugSnapshot.lastSelfTestDate?.formatted(date: .omitted, time: .standard) ?? "Never"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Permission Tools")
                        .font(.subheadline.weight(.semibold))

                    HStack {
                        Button("Refresh Permission Snapshot") {
                            model.refreshPermissionDebugger()
                        }

                        Button("Run Accessibility Self-Tests") {
                            model.runPermissionSelfTests()
                        }

                        Button("Copy Full Diagnostics Report") {
                            model.copyDiagnosticsReport()
                        }

                        Button("Open Diagnostics Folder") {
                            model.openDiagnosticsFolder()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recording Recovery")
                        .font(.subheadline.weight(.semibold))
                    Text("Use these if a recording or transcription state looks stuck. They do not expose transcript or audio contents.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Button("Finalize Recording Now") {
                            model.finalizeCurrentRecordingNow()
                        }
                        .disabled(!model.canFinalizeCurrentRecording)

                        Button("Cancel Current Dictation") {
                            model.cancelCurrentDictation()
                        }
                        .disabled(!model.canCancelCurrentDictation)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest Recording Attempt")
                        .font(.subheadline.weight(.semibold))

                    if let report = model.lastRecordingAttemptDiagnostics {
                        recordingDiagnosticsSection(for: report)
                    } else {
                        Text("No recording metrics captured yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Insertion Routing")
                        .font(.subheadline.weight(.semibold))

                    Text("Put Codex or another target app frontmost, then analyze the currently focused insertion target.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Analyze Focused Insertion Target") {
                        model.analyzeFocusedInsertionTarget()
                    }

                    if model.lastCapturedInsertionReport != nil || model.lastInsertionAttemptReport != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            if let report = model.lastCapturedInsertionReport {
                                insertionDiagnosticsSection(for: report)
                            }

                            if let report = model.lastInsertionAttemptReport {
                                insertionDiagnosticsSection(for: report)
                            }
                        }
                    }
                }

                if !model.permissionSelfTestResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility Self-Tests")
                            .font(.subheadline.weight(.semibold))

                        Text("These tests are read-only. For focused-target checks, put TextEdit or another target app frontmost before running them.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(model.permissionSelfTestResults) { result in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: iconName(for: result.status))
                                    .font(.caption)
                                    .foregroundStyle(color(for: result.status))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(result.kind.title): \(result.summary)")
                                        .font(.caption)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(result.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Checkpoint")
                        .font(.subheadline.weight(.semibold))
                    Text(model.checkpointSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Failed Stage")
                        .font(.subheadline.weight(.semibold))
                    Text(model.lastFailureStage?.title ?? "None")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Truth State")
                        .font(.subheadline.weight(.semibold))
                    Text(model.lastAttemptTruthState?.title ?? "None")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(model.lastAttemptTruthState?.detail ?? "No dictation outcome has been classified yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let lastDiagnosticEvent = model.lastDiagnosticEvent {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Event")
                            .font(.subheadline.weight(.semibold))
                        Text(lastDiagnosticEvent.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(lastDiagnosticEvent.timestamp.formatted(date: .omitted, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !model.diagnosticEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Events")
                            .font(.subheadline.weight(.semibold))

                        ForEach(model.diagnosticEvents) { event in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: event.isFailure ? "exclamationmark.circle.fill" : "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(event.isFailure ? .red : .secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.summary)
                                        .font(.caption)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(
                                        [
                                            event.stage?.title,
                                            event.timestamp.formatted(date: .omitted, time: .standard)
                                        ]
                                        .compactMap { $0 }
                                        .joined(separator: " · ")
                                    )
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                HStack {
                    Button("Clear All Diagnostics") {
                        model.clearDiagnosticHistory()
                    }

                    Spacer()
                }
            }
            .padding(.top, 6)
        }
    }

    private func errorPanel(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Blocker")
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func diagnosticsFact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.caption)
    }

    @ViewBuilder
    private func insertionDiagnosticsSection(for report: InsertionAttemptReport) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.observationLabel)
                .font(.caption.weight(.semibold))
            diagnosticsFact("Observed At", report.observedAt.formatted(date: .omitted, time: .standard))
            diagnosticsFact("App", report.capabilities.applicationName)
            diagnosticsFact("Bundle Identifier", report.capabilities.bundleIdentifier ?? "Unknown")
            diagnosticsFact("Context Kind", report.capabilities.contextKind.title)
            diagnosticsFact("Capability Profile", report.capabilities.capabilityProfile.title)
            diagnosticsFact("Target", report.capabilities.targetLabel)
            diagnosticsFact("Role", report.capabilities.role ?? "Unknown")
            diagnosticsFact("Subrole", report.capabilities.subrole ?? "Unknown")
            diagnosticsFact("Editable", report.capabilities.editable ? "Yes" : "No")
            diagnosticsFact("Secure", report.capabilities.secure ? "Yes" : "No")
            diagnosticsFact("Placeholder Present", report.capabilities.hasPlaceholderValue ? "Yes" : "No")
            diagnosticsFact("Placeholder Likely Active", report.capabilities.placeholderLikelyActive ? "Yes" : "No")
            diagnosticsFact("Placeholder Ambiguous Value", report.capabilities.placeholderAmbiguousValueDetected ? "Yes" : "No")
            diagnosticsFact("Value Readable", report.capabilities.valueReadable ? "Yes" : "No")
            diagnosticsFact("Value Settable", report.capabilities.valueSettable ? "Yes" : "No")
            diagnosticsFact("Selected Range Readable", report.capabilities.selectedTextRangeReadable ? "Yes" : "No")
            diagnosticsFact("Selected Text Readable", report.capabilities.selectedTextReadable ? "Yes" : "No")
            diagnosticsFact("Direct Insert Compatible", report.capabilities.directInsertCompatible ? "Yes" : "No")
            diagnosticsFact("Paste Compatible", report.capabilities.pasteCompatible ? "Yes" : "No")
            diagnosticsFact("Planned Strategy", report.chosenStrategy.title)
            diagnosticsFact("Applied Strategy", report.appliedStrategy?.title ?? "Not executed")
            diagnosticsFact("Verification", report.verificationOutcome?.title ?? "Unknown")
            diagnosticsFact("Placeholder Handling", report.placeholderHandlingOutcome?.title ?? "Unknown")
            diagnosticsFact("Strategy Reason", report.strategyReason)

            if let browserMetadata = report.capabilities.browserMetadata {
                diagnosticsFact("Browser Host", browserMetadata.browser.title)
                diagnosticsFact("Browser Target Class", browserMetadata.targetClass.title)
                diagnosticsFact("Browser Editor Family", browserMetadata.editorFamily.title)
                diagnosticsFact("Browser Verification Mode", browserMetadata.verificationMode.title)
                diagnosticsFact("Browser Fingerprint", browserMetadata.targetFingerprint ?? "Unknown")
            }

            if let predictedFailureClass = report.predictedFailureClass {
                diagnosticsFact("Predicted Failure", predictedFailureClass.title)
            }

            if !report.rejectedStrategies.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rejected Strategies")
                        .font(.caption.weight(.semibold))

                    ForEach(report.rejectedStrategies) { rejection in
                        Text("\(rejection.strategy.title): \(rejection.reason)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private func recordingDiagnosticsSection(for report: RecordingAttemptDiagnostics) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            diagnosticsFact("Hotkey Pressed At", formatted(report.hotkeyPressedAt))
            diagnosticsFact("Recording Started At", formatted(report.recordingStartedAt))
            diagnosticsFact("Press To Recording Start", formattedDuration(report.pressToRecordingStartDuration))
            diagnosticsFact("Hotkey Released At", formatted(report.hotkeyReleasedAt))
            diagnosticsFact("Finalizing State Shown At", formatted(report.finalizingStateShownAt))
            diagnosticsFact("Release To Finalizing State", formattedDuration(report.releaseToFinalizingStateDuration))
            diagnosticsFact("Recording Finalized At", formatted(report.recordingFinalizedAt))
            diagnosticsFact("Release To Recording Finalized", formattedDuration(report.releaseToFinalizedDuration))
            diagnosticsFact("Transcription Request Started At", formatted(report.transcriptionRequestStartedAt))
            diagnosticsFact("Recording Finalized To Request Start", formattedDuration(report.finalizedToRequestStartDuration))
            diagnosticsFact("Transcription Response Completed At", formatted(report.transcriptionResponseCompletedAt))
            diagnosticsFact("Request Start To Response Complete", formattedDuration(report.requestToResponseDuration))
            diagnosticsFact("Insertion Completed At", formatted(report.insertionCompletedAt))
            diagnosticsFact("Response Complete To Insertion Complete", formattedDuration(report.responseToInsertionDuration))
            diagnosticsFact("Hotkey Release To Insertion Complete", formattedDuration(report.releaseToInsertionDuration))
            diagnosticsFact("Stop Trigger", report.stopTrigger?.title ?? "Unknown")
            diagnosticsFact("Clip Duration", formattedDuration(report.clipDuration))
            diagnosticsFact("Recorded File Size", formattedFileSize(report.recordedFileSizeBytes))
            diagnosticsFact("Transcript Characters", report.transcriptCharacterCount.map(String.init) ?? "Unknown")
            diagnosticsFact("Transcript Words", report.transcriptWordCount.map(String.init) ?? "Unknown")
            diagnosticsFact("Transcription Backend", report.transcriptionBackendID ?? "Unknown")
            diagnosticsFact("Transcription Request Mode", report.transcriptionRequestMode ?? "Unknown")
            diagnosticsFact("Streaming Fallback Used", formattedBool(report.transcriptionFellBackFromStreaming))
            diagnosticsFact("Transcription HTTP Status", report.transcriptionHTTPStatusCode.map(String.init) ?? "Unknown")
            diagnosticsFact("Transcription Request ID", report.transcriptionRequestID ?? "Unknown")
            diagnosticsFact("OpenAI Processing Time", formattedMilliseconds(report.transcriptionProcessingMS))
            diagnosticsFact("Response Content Type", report.transcriptionResponseContentType ?? "Unknown")
            diagnosticsFact("Response Headers Received", formattedMilliseconds(report.transcriptionResponseHeadersReceivedMS))
            diagnosticsFact("Transport Failure Stage", report.transcriptionTransportFailureStage ?? "Unknown")
            diagnosticsFact("Network Error Domain", report.transcriptionNetworkErrorDomain ?? "Unknown")
            diagnosticsFact("Network Error Code", report.transcriptionNetworkErrorCode.map(String.init) ?? "Unknown")
            diagnosticsFact("Network Error Code Name", report.transcriptionNetworkErrorCodeName ?? "Unknown")
        }
    }

    private func formatted(_ date: Date?) -> String {
        date?.formatted(date: .omitted, time: .standard) ?? "Unknown"
    }

    private func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else {
            return "Unknown"
        }

        return String(format: "%.2fs", duration)
    }

    private func formattedFileSize(_ bytes: Int64?) -> String {
        guard let bytes else {
            return "Unknown"
        }

        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func formattedMilliseconds(_ milliseconds: Int?) -> String {
        guard let milliseconds else {
            return "Unknown"
        }

        return "\(milliseconds) ms"
    }

    private func formattedBool(_ value: Bool?) -> String {
        guard let value else {
            return "Unknown"
        }

        return value ? "Yes" : "No"
    }

    private func iconName(for status: PermissionSelfTestStatus) -> String {
        switch status {
        case .passed:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.circle.fill"
        case .failed:
            "xmark.circle.fill"
        }
    }

    private func color(for status: PermissionSelfTestStatus) -> Color {
        switch status {
        case .passed:
            .green
        case .warning:
            .yellow
        case .failed:
            .red
        }
    }
}
