import SwiftUI

@MainActor
struct MenuBarContentView: View {
    @Bindable var model: HeadCanonModel
    @State private var apiKeyDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(alignment: .top, spacing: 12) {
                    AppLogoView(size: 34, cornerRadius: 9)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Head Canon")
                            .font(.headline)
                        Text(model.statusSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 16)

                StatusBadgeView(title: model.workflowStatus.title)
            }

            VStack(alignment: .leading, spacing: 10) {
                permissionRow(title: "Microphone", state: model.permissionSnapshot.microphone)
                permissionRow(title: "Accessibility", state: model.permissionSnapshot.accessibility)
                permissionRow(title: "OpenAI Key", stateTitle: model.apiKeyState.title)
                permissionRow(title: "Disk", stateTitle: model.diskSpaceReadiness?.status.title ?? "Unknown")
            }

            if !model.setupBlockers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup Blockers")
                        .font(.subheadline.weight(.semibold))

                    ForEach(model.setupBlockers) { blocker in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(blocker.title)
                                .font(.caption.weight(.semibold))
                            Text(blocker.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if let runtimeWarningMessage = model.runtimeWarningMessage {
                Text(runtimeWarningMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let diskSpaceWarningMessage = model.diskSpaceWarningMessage {
                Text(diskSpaceWarningMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let diskSpaceReserveSummary = model.diskSpaceReserveSummary {
                Text(diskSpaceReserveSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let microphoneSetupAction = model.microphoneSetupAction {
                Button("\(microphoneSetupAction.title) Microphone Access") {
                    model.performSetupAction(microphoneSetupAction)
                }
            }

            if let accessibilitySetupAction = model.accessibilitySetupAction {
                Button("\(accessibilitySetupAction.title) Accessibility Access") {
                    model.performSetupAction(accessibilitySetupAction)
                }
            }

            if model.apiKeyState != .valid {
                SecureField("Paste OpenAI API key", text: $apiKeyDraft)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save Key") {
                        let trimmedValue = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedValue.isEmpty else {
                            return
                        }

                        Task {
                            await model.saveAPIKey(trimmedValue)
                            apiKeyDraft = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Validate OpenAI Key") {
                        Task {
                            await model.refreshAPIKeyState()
                        }
                    }

                    Spacer()
                }

                Text("This backend sends audio to OpenAI for transcription. Head Canon does not send audio off-device silently.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if model.apiKeyState == .valid {
                Button("Validate OpenAI Key") {
                    Task {
                        await model.refreshAPIKeyState()
                    }
                }
            }

            if let lastErrorMessage = model.lastErrorMessage, !lastErrorMessage.isEmpty {
                Text(lastErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            transcriptRecoveryPanel

            Divider()

            Button("Finalize Recording Now") {
                model.finalizeCurrentRecordingNow()
            }
            .disabled(!model.canFinalizeCurrentRecording)

            Button("Cancel Current Dictation") {
                model.cancelCurrentDictation()
            }
            .disabled(!model.canCancelCurrentDictation)

            Divider()

            Button("Paste Last Transcript") {
                model.pasteLastTranscript()
            }
            .disabled(model.lastTranscript?.isEmpty ?? true)

            Button("Copy Last Transcript") {
                model.copyLastTranscript()
            }
            .disabled(model.lastTranscript?.isEmpty ?? true)

            Button("Clear Last Transcript") {
                model.clearLastTranscript()
            }
            .disabled(model.lastTranscript?.isEmpty ?? true)

            Button("Refresh Status") {
                model.requestStatusRefresh()
            }

            Button("Open Settings") {
                model.openSettingsWindow()
            }

            Button("Reveal App In Finder") {
                model.revealAppInFinder()
            }

            Button("Relaunch Head Canon") {
                model.relaunchApp()
            }

            Button("Quit Head Canon") {
                model.quit()
            }
        }
        .padding(18)
        .frame(width: 430)
        .onAppear {
            apiKeyDraft = ""
        }
    }

    private func permissionRow(title: String, state: PermissionState) -> some View {
        permissionRow(title: title, stateTitle: state.title)
    }

    private func permissionRow(title: String, stateTitle: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(stateTitle)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
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
            return "Turn on transcript retention in Settings if you want a manual recovery copy after each dictation."
        }

        return "This area will keep the next successful transcription available for manual recovery."
    }

    private var transcriptRecoveryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last Transcript")
                .font(.subheadline.weight(.semibold))

            Text(recoveryTranscriptStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                Text(recoveryTranscriptDisplayText)
                    .font(.body)
                    .foregroundStyle(hasRetainedTranscript ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 140, maxHeight: 220)
            .padding(12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.25))
            }
            .accessibilityIdentifier("last-transcript-recovery-text")
        }
    }
}
