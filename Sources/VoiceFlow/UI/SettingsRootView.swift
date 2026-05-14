import SwiftUI

struct SettingsRootView: View {
    @Bindable var model: VoiceFlowModel
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
                settingsForm
                setupHelp
                verificationMatrix
            }
            .padding(24)
        }
        .onAppear {
            apiKeyDraft = ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Voice Flow v1")
                    .font(.largeTitle.weight(.semibold))
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
                    Text("Voice Flow v1 uses an OpenAI-hosted transcription backend. Audio is not sent off-device silently, but this backend is network-backed.")
                        .font(.subheadline)
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
                            model.requestStatusRefresh()
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
                    HStack {
                        Text("Hotkey")
                        Spacer()
                        Text(model.preferences.hotkey.displayString)
                            .foregroundStyle(.secondary)
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

            GroupBox("App Identity") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Voice Flow must be granted permissions for this exact app bundle:")
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
                        "Transcript History",
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
                        "Use paste fallback when direct insertion fails",
                        isOn: Binding(
                            get: { model.preferences.pasteFallbackEnabled },
                            set: { model.preferences.pasteFallbackEnabled = $0 }
                        )
                    )

                    if let lastTranscript = model.lastTranscript, !lastTranscript.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last Transcript")
                                .font(.headline)
                            Text(lastTranscript)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding(.top, 4)
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

    private var setupHelp: some View {
        GroupBox("Setup Help") {
            VStack(alignment: .leading, spacing: 12) {
                Text("If Accessibility keeps showing Denied, grant access to this exact app bundle, then relaunch and refresh:")
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
                    Text("2. Remove old VoiceFlow entries if needed.")
                    Text("3. Add or re-enable this exact app bundle.")
                    Text("4. Return here, relaunch the app, then click Refresh Status.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

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
}
