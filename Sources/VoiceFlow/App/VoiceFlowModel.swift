import AppKit
import Foundation
import Observation

enum WorkflowStatus: String {
    case setupRequired
    case ready
    case recording
    case transcribing
    case inserted
    case failed

    var title: String {
        switch self {
        case .setupRequired:
            "Setup Required"
        case .ready:
            "Ready"
        case .recording:
            "Recording"
        case .transcribing:
            "Transcribing"
        case .inserted:
            "Inserted"
        case .failed:
            "Needs Attention"
        }
    }
}

enum APIKeyState: Equatable {
    case missing
    case validating
    case valid
    case invalid(String)
    case networkUnavailable(String)

    var title: String {
        switch self {
        case .missing:
            "Missing"
        case .validating:
            "Checking"
        case .valid:
            "Valid"
        case .invalid:
            "Invalid"
        case .networkUnavailable:
            "Offline"
        }
    }

    var detail: String {
        switch self {
        case .missing:
            "Add an OpenAI API key to enable dictation."
        case .validating:
            "Validating the stored API key."
        case .valid:
            "The stored API key is ready."
        case .invalid(let message), .networkUnavailable(let message):
            message
        }
    }
}

enum SetupBlocker: Equatable, Identifiable {
    case microphone
    case accessibility
    case apiKeyMissing
    case apiKeyInvalid(String)
    case apiKeyOffline(String)

    var id: String {
        switch self {
        case .microphone:
            "microphone"
        case .accessibility:
            "accessibility"
        case .apiKeyMissing:
            "apiKeyMissing"
        case .apiKeyInvalid:
            "apiKeyInvalid"
        case .apiKeyOffline:
            "apiKeyOffline"
        }
    }

    var title: String {
        switch self {
        case .microphone:
            "Microphone access"
        case .accessibility:
            "Accessibility access"
        case .apiKeyMissing:
            "OpenAI API key"
        case .apiKeyInvalid:
            "OpenAI API key"
        case .apiKeyOffline:
            "Network validation"
        }
    }

    var detail: String {
        switch self {
        case .microphone:
            "Grant microphone access before starting dictation."
        case .accessibility:
            "Enable Accessibility access so Voice Flow can insert text into the focused app."
        case .apiKeyMissing:
            "Add an OpenAI API key to enable the current transcription backend."
        case .apiKeyInvalid(let message):
            message
        case .apiKeyOffline(let message):
            message
        }
    }
}

@MainActor
@Observable
final class VoiceFlowModel {
    @ObservationIgnored private let permissionsManager: any PermissionsManaging
    @ObservationIgnored private let audioCaptureService: any AudioCapturing
    @ObservationIgnored private let transcriptionBackend: any TranscriptionBackend
    @ObservationIgnored private let textInsertionService: any TextInsertionServicing
    @ObservationIgnored private let apiKeyStore: any APIKeyStoring
    @ObservationIgnored private let hotkeyManager: any HotkeyManaging

    let preferences: AppPreferences

    var permissionSnapshot = PermissionSnapshot()
    var workflowStatus: WorkflowStatus = .setupRequired
    var apiKeyState: APIKeyState = .missing
    var availableMicrophones: [MicrophoneDevice] = []
    var lastTranscript: String?
    var lastErrorMessage: String?
    var lastValidationDate: Date?
    @ObservationIgnored private var hasPresentedSetupWindow = false
    @ObservationIgnored private var activationObserver: NSObjectProtocol?
    @ObservationIgnored private var isRefreshingStatus = false

    init(
        preferences: AppPreferences = AppPreferences(),
        permissionsManager: (any PermissionsManaging)? = nil,
        audioCaptureService: (any AudioCapturing)? = nil,
        transcriptionBackend: (any TranscriptionBackend)? = nil,
        textInsertionService: (any TextInsertionServicing)? = nil,
        apiKeyStore: (any APIKeyStoring)? = nil,
        hotkeyManager: (any HotkeyManaging)? = nil
    ) {
        self.preferences = preferences
        self.permissionsManager = permissionsManager ?? PermissionsManager()
        self.audioCaptureService = audioCaptureService ?? AudioCaptureService()
        self.transcriptionBackend = transcriptionBackend ?? OpenAIBoundedTranscriptionBackend()
        self.textInsertionService = textInsertionService ?? TextInsertionService()
        self.apiKeyStore = apiKeyStore ?? KeychainAPIKeyStore()
        self.hotkeyManager = hotkeyManager ?? HotkeyManager()
    }

    var isReady: Bool {
        permissionSnapshot.isReady && apiKeyState == .valid
    }

    var setupBlockers: [SetupBlocker] {
        var blockers: [SetupBlocker] = []

        if !permissionSnapshot.microphone.isGranted {
            blockers.append(.microphone)
        }

        if !permissionSnapshot.accessibility.isGranted {
            blockers.append(.accessibility)
        }

        switch apiKeyState {
        case .missing:
            blockers.append(.apiKeyMissing)
        case .invalid(let message):
            blockers.append(.apiKeyInvalid(message))
        case .networkUnavailable(let message):
            blockers.append(.apiKeyOffline(message))
        case .valid, .validating:
            break
        }

        return blockers
    }

    var menuBarSymbolName: String {
        switch workflowStatus {
        case .recording:
            "waveform.circle.fill"
        case .transcribing:
            "ellipsis.circle.fill"
        case .ready, .inserted:
            "mic.circle.fill"
        case .setupRequired, .failed:
            "exclamationmark.circle.fill"
        }
    }

    var statusSummary: String {
        setupBlockers.first?.detail ?? "Voice Flow is ready."
    }

    var currentAppPath: String {
        Bundle.main.bundleURL.path
    }

    var shouldRetainTranscript: Bool {
        preferences.historyRetentionMode != .neverStore
    }

    var historyRetentionSummary: String {
        preferences.historyRetentionMode.currentBehaviorDetail
    }

    func start() {
        Task {
            await bootstrap()
        }
    }

    func bootstrap() async {
        installLifecycleObservers()
        applyPrivacyPreferences()
        await refreshRuntimeStatus()
        registerHotkey()
        recalculateWorkflowStatus()
        presentSetupWindowIfNeeded()
    }

    func requestStatusRefresh(presentSetupWindow: Bool = false) {
        Task { @MainActor in
            await refreshRuntimeStatus(presentSetupWindow: presentSetupWindow)
        }
    }

    func refreshRuntimeStatus(presentSetupWindow: Bool = true) async {
        guard !isRefreshingStatus else {
            return
        }

        isRefreshingStatus = true
        defer {
            isRefreshingStatus = false
        }

        refreshPermissions()
        refreshMicrophones()
        await refreshAPIKeyState(presentSetupWindow: presentSetupWindow)
    }

    func refreshPermissions() {
        permissionSnapshot = permissionsManager.refreshStatus()
        recalculateWorkflowStatus()
    }

    func requestMicrophoneAccess() {
        Task { @MainActor in
            _ = await permissionsManager.requestMicrophoneAccess()
            refreshPermissions()
        }
    }

    func promptForAccessibility() {
        permissionsManager.promptForAccessibility()
        refreshPermissions()
        presentSetupWindowIfNeeded()
    }

    func refreshMicrophones() {
        availableMicrophones = audioCaptureService.availableInputDevices()

        let selectedMicrophoneIsAvailable = availableMicrophones.contains { device in
            device.id == preferences.selectedMicrophoneID
        }

        if preferences.selectedMicrophoneID != nil && !selectedMicrophoneIsAvailable {
            preferences.selectedMicrophoneID = nil
        }
    }

    func saveAPIKey(_ apiKey: String) async {
        do {
            try apiKeyStore.saveAPIKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
            await refreshAPIKeyState()
            if isReady {
                lastErrorMessage = nil
                hasPresentedSetupWindow = true
            }
        } catch {
            apiKeyState = .invalid(error.localizedDescription)
            workflowStatus = .failed
            lastErrorMessage = error.localizedDescription
        }
    }

    func removeAPIKey() {
        do {
            try apiKeyStore.removeAPIKey()
            apiKeyState = .missing
            recalculateWorkflowStatus()
            presentSetupWindowIfNeeded(force: true)
        } catch {
            apiKeyState = .invalid(error.localizedDescription)
            workflowStatus = .failed
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshAPIKeyState() async {
        await refreshAPIKeyState(presentSetupWindow: true)
    }

    func refreshAPIKeyState(presentSetupWindow: Bool) async {
        guard let apiKey = apiKeyStore.loadAPIKey(), !apiKey.isEmpty else {
            apiKeyState = .missing
            recalculateWorkflowStatus()
            if presentSetupWindow {
                presentSetupWindowIfNeeded()
            }
            return
        }

        apiKeyState = .validating

        do {
            try await transcriptionBackend.validateConfiguration(apiKey: apiKey)
            apiKeyState = .valid
            lastValidationDate = Date()
            lastErrorMessage = nil
        } catch let error as TranscriptionBackendError {
            switch error {
            case .invalidAPIKey:
                apiKeyState = .invalid("The stored OpenAI API key was rejected.")
            case .networkUnavailable:
                apiKeyState = .networkUnavailable("Voice Flow could not reach OpenAI to validate the key.")
            case .unexpectedResponse(let statusCode):
                apiKeyState = .invalid("OpenAI returned an unexpected status code: \(statusCode).")
            case .invalidResponse:
                apiKeyState = .invalid("OpenAI returned an invalid validation response.")
            case .serializationFailure, .notImplemented:
                apiKeyState = .invalid("Voice Flow could not validate the stored API key.")
            }
        } catch {
            apiKeyState = .invalid(error.localizedDescription)
        }

        recalculateWorkflowStatus()
        if presentSetupWindow {
            presentSetupWindowIfNeeded()
        }
    }

    func pasteLastTranscript() {
        applyPrivacyPreferences()

        guard let lastTranscript, !lastTranscript.isEmpty else {
            return
        }

        Task {
            @MainActor in
            do {
                try await textInsertionService.insert(lastTranscript, preservingClipboard: preferences.pasteFallbackEnabled)
                workflowStatus = .inserted
            } catch {
                workflowStatus = .failed
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    func openSettingsWindow() {
        SettingsWindowController.shared.show(model: self)
        hasPresentedSetupWindow = true
        requestStatusRefresh()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    func revealAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    func copyAppPath() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentAppPath, forType: .string)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
            return
        }

        openSystemSettings()
    }

    func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
            return
        }

        openSystemSettings()
    }

    func openSystemSettings() {
        if let settingsAppURL = URL(string: "file:///System/Applications/System%20Settings.app") {
            NSWorkspace.shared.open(settingsAppURL)
        }
    }

    func relaunchApp() {
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.open(appURL)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }

    func resetHotkeyToDefault() {
        preferences.hotkey = .defaultPushToTalk
        registerHotkey()
    }

    func clearLastTranscript() {
        lastTranscript = nil
    }

    func applyPrivacyPreferences() {
        if !shouldRetainTranscript {
            lastTranscript = nil
        }
    }

    private func registerHotkey() {
        do {
            try hotkeyManager.register(
                shortcut: preferences.hotkey,
                onPress: { [weak self] in
                    self?.handleHotkeyPressed()
                },
                onRelease: { [weak self] in
                    self?.handleHotkeyReleased()
                }
            )
        } catch {
            workflowStatus = .failed
            lastErrorMessage = "Failed to register the global hotkey: \(error.localizedDescription)"
        }
    }

    private func installLifecycleObservers() {
        guard activationObserver == nil else {
            return
        }

        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.requestStatusRefresh()
            }
        }
    }

    private func handleHotkeyPressed() {
        guard isReady else {
            workflowStatus = .setupRequired
            lastErrorMessage = setupBlockers.first?.detail
            presentSetupWindowIfNeeded(force: true)
            return
        }

        guard !audioCaptureService.isRecording else {
            return
        }

        do {
            try audioCaptureService.startRecording(preferredDeviceID: preferences.selectedMicrophoneID)
            workflowStatus = .recording
            lastErrorMessage = nil
        } catch {
            workflowStatus = .failed
            lastErrorMessage = error.localizedDescription
        }
    }

    private func handleHotkeyReleased() {
        Task { @MainActor in
            guard audioCaptureService.isRecording else {
                return
            }

            let input: BoundedAudioInput

            do {
                input = try await audioCaptureService.stopRecording()
            } catch {
                workflowStatus = .failed
                lastErrorMessage = error.localizedDescription
                return
            }

            workflowStatus = .transcribing
            lastErrorMessage = nil
            await transcribeAndInsert(input)
        }
    }

    private func transcribeAndInsert(_ input: BoundedAudioInput) async {
        defer {
            try? FileManager.default.removeItem(at: input.fileURL)
        }

        guard let apiKey = apiKeyStore.loadAPIKey(), !apiKey.isEmpty else {
            apiKeyState = .missing
            workflowStatus = .setupRequired
            lastErrorMessage = APIKeyState.missing.detail
            presentSetupWindowIfNeeded(force: true)
            return
        }

        do {
            let result = try await transcriptionBackend.transcribe(input, apiKey: apiKey)
            retainTranscriptIfAllowed(result.text)

            try await textInsertionService.insert(
                result.text,
                preservingClipboard: preferences.pasteFallbackEnabled
            )

            workflowStatus = .inserted
            lastErrorMessage = nil
        } catch let error as TranscriptionBackendError {
            workflowStatus = .failed
            lastErrorMessage = error.localizedDescription
        } catch {
            workflowStatus = .failed
            lastErrorMessage = error.localizedDescription
        }
    }

    private func retainTranscriptIfAllowed(_ text: String) {
        lastTranscript = shouldRetainTranscript ? text : nil
    }

    private func recalculateWorkflowStatus() {
        if !permissionSnapshot.isReady || apiKeyState != .valid {
            workflowStatus = .setupRequired
        } else if workflowStatus != .recording && workflowStatus != .transcribing {
            workflowStatus = .ready
        }
    }

    private func presentSetupWindowIfNeeded() {
        presentSetupWindowIfNeeded(force: false)
    }

    private func presentSetupWindowIfNeeded(force: Bool) {
        guard !isReady else {
            return
        }

        if !force && hasPresentedSetupWindow {
            return
        }

        hasPresentedSetupWindow = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.openSettingsWindow()
        }
    }
}
