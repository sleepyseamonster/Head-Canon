import Foundation
import Testing
@testable import VoiceFlow

@Suite("Voice Flow Defaults")
struct VoiceFlowTests {
    @Test("Preferences default to v1 retention and fallback values")
    @MainActor
    func preferencesDefaultToSpecValues() {
        let suiteName = "VoiceFlowTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let preferences = AppPreferences(defaults: defaults)

        #expect(preferences.historyRetentionMode == .thirtyDays)
        #expect(preferences.pasteFallbackEnabled)
        #expect(preferences.hotkey == .defaultPushToTalk)
        #expect(preferences.selectedMicrophoneID == nil)
    }

    @Test("Setup blockers reflect missing permissions and key state")
    @MainActor
    func setupBlockersDescribeUnreadyState() {
        let model = VoiceFlowModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .denied,
                    accessibility: .denied
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: nil),
            hotkeyManager: StubHotkeyManager()
        )

        model.refreshPermissions()

        #expect(
            model.setupBlockers == [
                .microphone,
                .accessibility,
                .apiKeyMissing,
            ]
        )
        #expect(model.statusSummary == SetupBlocker.microphone.detail)
    }

    @Test("Ready state clears setup blockers")
    @MainActor
    func readyStateClearsSetupBlockers() {
        let model = VoiceFlowModel(
            permissionsManager: StubPermissionsManager(
                snapshot: PermissionSnapshot(
                    microphone: .granted,
                    accessibility: .granted
                )
            ),
            audioCaptureService: StubAudioCaptureService(),
            transcriptionBackend: StubTranscriptionBackend(),
            textInsertionService: StubTextInsertionService(),
            apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
            hotkeyManager: StubHotkeyManager()
        )

        model.permissionSnapshot = PermissionSnapshot(
            microphone: .granted,
            accessibility: .granted
        )
        model.apiKeyState = .valid

        #expect(model.setupBlockers.isEmpty)
        #expect(model.statusSummary == "Voice Flow is ready.")
        #expect(model.isReady)
    }

}

@Suite("Voice Flow Security")
struct VoiceFlowSecurityTests {
    @Test("Never store clears retained transcript immediately")
    @MainActor
    func neverStoreClearsRetainedTranscript() {
        let preferences = testPreferences()
        let model = makeReadyModel(preferences: preferences)

        model.lastTranscript = "secret"
        model.preferences.historyRetentionMode = .neverStore
        model.applyPrivacyPreferences()

        #expect(model.lastTranscript == nil)
        #expect(!model.shouldRetainTranscript)
    }

    @Test("Dictation does not retain transcript when history is disabled")
    @MainActor
    func dictationSkipsTranscriptRetentionWhenNeverStoreIsSelected() async {
        let preferences = testPreferences()
        preferences.historyRetentionMode = .neverStore

        let hotkeyManager = StubHotkeyManager()
        let textInsertionService = RecordingTextInsertionService()
        let model = makeReadyModel(
            preferences: preferences,
            transcriptionBackend: StubTranscriptionBackend(transcript: "secret"),
            textInsertionService: textInsertionService,
            hotkeyManager: hotkeyManager
        )

        await model.bootstrap()
        hotkeyManager.press()
        hotkeyManager.release()
        await waitForWorkflowCompletion(model)

        #expect(model.workflowStatus == .inserted)
        #expect(model.lastTranscript == nil)
        #expect(textInsertionService.insertedTexts == ["secret"])
    }

    @Test("Audio capture startup cleanup removes stale app recordings")
    @MainActor
    func audioCaptureStartupRemovesStaleRecordings() throws {
        let fileManager = FileManager.default
        let staleDirectory = AudioCaptureService.recordingsDirectoryURL

        try fileManager.createDirectory(at: staleDirectory, withIntermediateDirectories: true)

        let staleFileURL = staleDirectory.appendingPathComponent("voice-flow-stale").appendingPathExtension("m4a")
        try Data("stale".utf8).write(to: staleFileURL)
        #expect(fileManager.fileExists(atPath: staleFileURL.path))

        _ = AudioCaptureService()

        #expect(!fileManager.fileExists(atPath: staleFileURL.path))
    }

    @Test("User can manually clear retained transcript")
    @MainActor
    func clearLastTranscriptRemovesSessionState() {
        let model = makeReadyModel()

        model.lastTranscript = "secret"
        model.clearLastTranscript()

        #expect(model.lastTranscript == nil)
    }
}

@MainActor
private func testPreferences() -> AppPreferences {
    let suiteName = "VoiceFlowTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return AppPreferences(defaults: defaults)
}

@MainActor
private func makeReadyModel(
    preferences: AppPreferences = testPreferences(),
    transcriptionBackend: any TranscriptionBackend = StubTranscriptionBackend(),
    textInsertionService: any TextInsertionServicing = StubTextInsertionService(),
    hotkeyManager: StubHotkeyManager = StubHotkeyManager()
) -> VoiceFlowModel {
    VoiceFlowModel(
        preferences: preferences,
        permissionsManager: StubPermissionsManager(
            snapshot: PermissionSnapshot(
                microphone: .granted,
                accessibility: .granted
            )
        ),
        audioCaptureService: StubAudioCaptureService(),
        transcriptionBackend: transcriptionBackend,
        textInsertionService: textInsertionService,
        apiKeyStore: StubAPIKeyStore(apiKey: "test-key"),
        hotkeyManager: hotkeyManager
    )
}

@MainActor
private func waitForWorkflowCompletion(_ model: VoiceFlowModel) async {
    for _ in 0..<20 {
        if model.workflowStatus == .inserted || model.workflowStatus == .failed {
            return
        }
        await Task.yield()
    }
}

private struct StubPermissionsManager: PermissionsManaging {
    let snapshot: PermissionSnapshot

    func refreshStatus() -> PermissionSnapshot {
        snapshot
    }

    func requestMicrophoneAccess() async -> PermissionState {
        snapshot.microphone
    }

    func promptForAccessibility() {}
}

@MainActor
private final class StubAudioCaptureService: AudioCapturing {
    var isRecording = false

    func availableInputDevices() -> [MicrophoneDevice] {
        []
    }

    func startRecording(preferredDeviceID: String?) throws {
        isRecording = true
    }

    func stopRecording() async throws -> BoundedAudioInput {
        isRecording = false
        return BoundedAudioInput(
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            mimeType: "audio/mp4",
            duration: nil
        )
    }

    func cancelRecording() {
        isRecording = false
    }
}

private struct StubTranscriptionBackend: TranscriptionBackend {
    let id = "stub"
    var transcript = "stub"

    func validateConfiguration(apiKey: String) async throws {}

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        TranscriptionResult(text: transcript, backendID: id, duration: nil)
    }
}

private struct StubTextInsertionService: TextInsertionServicing {
    func insert(_ text: String, preservingClipboard: Bool) async throws {}
}

@MainActor
private final class RecordingTextInsertionService: TextInsertionServicing {
    private(set) var insertedTexts: [String] = []

    func insert(_ text: String, preservingClipboard: Bool) async throws {
        insertedTexts.append(text)
    }
}

private struct StubAPIKeyStore: APIKeyStoring {
    let apiKey: String?

    func loadAPIKey() -> String? {
        apiKey
    }

    func saveAPIKey(_ apiKey: String) throws {}

    func removeAPIKey() throws {}
}

@MainActor
private final class StubHotkeyManager: HotkeyManaging {
    private var onPress: (@MainActor () -> Void)?
    private var onRelease: (@MainActor () -> Void)?

    func register(
        shortcut: HotkeyShortcut,
        onPress: @escaping @MainActor () -> Void,
        onRelease: @escaping @MainActor () -> Void
    ) throws {
        self.onPress = onPress
        self.onRelease = onRelease
    }

    func unregister() {
        onPress = nil
        onRelease = nil
    }

    func press() {
        onPress?()
    }

    func release() {
        onRelease?()
    }
}
