import AppKit
import Foundation
import Observation
import OSLog

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
    case unvalidated
    case validating
    case valid
    case invalid(String)
    case keychainError(String)
    case networkUnavailable(String)

    var title: String {
        switch self {
        case .missing:
            "Missing"
        case .unvalidated:
            "Needs Validation"
        case .validating:
            "Checking"
        case .valid:
            "Valid"
        case .invalid:
            "Invalid"
        case .keychainError:
            "Stored Key Error"
        case .networkUnavailable:
            "Offline"
        }
    }

    var detail: String {
        switch self {
        case .missing:
            "Add an OpenAI API key to enable dictation."
        case .unvalidated:
            "Validate the stored OpenAI API key before dictation can begin."
        case .validating:
            "Validating the stored API key."
        case .valid:
            "The stored API key is ready."
        case .invalid(let message), .keychainError(let message), .networkUnavailable(let message):
            message
        }
    }
}

enum SetupBlocker: Equatable, Identifiable {
    case microphone
    case accessibility
    case apiKeyMissing
    case apiKeyValidationRequired
    case apiKeyInvalid(String)
    case apiKeyStoreError(String)
    case apiKeyOffline(String)

    var id: String {
        switch self {
        case .microphone:
            "microphone"
        case .accessibility:
            "accessibility"
        case .apiKeyMissing:
            "apiKeyMissing"
        case .apiKeyValidationRequired:
            "apiKeyValidationRequired"
        case .apiKeyInvalid:
            "apiKeyInvalid"
        case .apiKeyStoreError:
            "apiKeyStoreError"
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
        case .apiKeyValidationRequired:
            "OpenAI API key"
        case .apiKeyInvalid:
            "OpenAI API key"
        case .apiKeyStoreError:
            "Stored API key"
        case .apiKeyOffline:
            "Network validation"
        }
    }

    var detail: String {
        switch self {
        case .microphone:
            "Grant microphone access before starting dictation."
        case .accessibility:
            "Enable Accessibility access so Head Canon can insert text into the focused app."
        case .apiKeyMissing:
            "Add an OpenAI API key to enable the current transcription backend."
        case .apiKeyValidationRequired:
            "Validate the stored OpenAI API key before starting dictation."
        case .apiKeyInvalid(let message):
            message
        case .apiKeyStoreError(let message):
            message
        case .apiKeyOffline(let message):
            message
        }
    }
}

enum DiagnosticFailureStage: String, Equatable, Identifiable {
    case permissionReadiness
    case hotkey
    case recordingStart
    case recordingStop
    case transcription
    case insertion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .permissionReadiness:
            "Permission / Readiness"
        case .hotkey:
            "Hotkey"
        case .recordingStart:
            "Recording Start"
        case .recordingStop:
            "Recording Stop"
        case .transcription:
            "Transcription"
        case .insertion:
            "Insertion"
        }
    }
}

struct DiagnosticEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let summary: String
    let stage: DiagnosticFailureStage?
    let isFailure: Bool
}

enum HotkeyReleaseSource: String, Equatable, Identifiable {
    case carbonKeyUp
    case globalModifierMonitor
    case localModifierMonitor
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .carbonKeyUp:
            "Carbon Key-Up"
        case .globalModifierMonitor:
            "Global Modifier Monitor"
        case .localModifierMonitor:
            "Local Modifier Monitor"
        case .unknown:
            "Unknown"
        }
    }
}

struct HotkeyReleaseContext: Equatable {
    let source: HotkeyReleaseSource
    let observedAt: Date
}

struct RecordingAttemptDiagnostics: Equatable {
    let hotkeyPressedAt: Date?
    let recordingStartedAt: Date?
    let hotkeyReleasedAt: Date?
    let processingStateShownAt: Date?
    let recordingFinalizedAt: Date?
    let transcriptionRequestStartedAt: Date?
    let transcriptionResponseCompletedAt: Date?
    let insertionCompletedAt: Date?
    let stopTrigger: HotkeyReleaseSource?
    let clipDuration: TimeInterval?
    let recordedFileSizeBytes: Int64?
    let transcriptCharacterCount: Int?
    let transcriptWordCount: Int?
    let transcriptionBackendID: String?
    let transcriptionRequestMode: String?
    let transcriptionFellBackFromStreaming: Bool?
    let transcriptionHTTPStatusCode: Int?
    let transcriptionRequestID: String?
    let transcriptionProcessingMS: Int?
    let transcriptionResponseContentType: String?

    var pressToRecordingStartDuration: TimeInterval? {
        elapsedTime(from: hotkeyPressedAt, to: recordingStartedAt)
    }

    var releaseToProcessingStateDuration: TimeInterval? {
        elapsedTime(from: hotkeyReleasedAt, to: processingStateShownAt)
    }

    var releaseToFinalizedDuration: TimeInterval? {
        elapsedTime(from: hotkeyReleasedAt, to: recordingFinalizedAt)
    }

    var finalizedToRequestStartDuration: TimeInterval? {
        elapsedTime(from: recordingFinalizedAt, to: transcriptionRequestStartedAt)
    }

    var requestToResponseDuration: TimeInterval? {
        elapsedTime(from: transcriptionRequestStartedAt, to: transcriptionResponseCompletedAt)
    }

    var responseToInsertionDuration: TimeInterval? {
        elapsedTime(from: transcriptionResponseCompletedAt, to: insertionCompletedAt)
    }

    var releaseToInsertionDuration: TimeInterval? {
        elapsedTime(from: hotkeyReleasedAt, to: insertionCompletedAt)
    }

    static let empty = RecordingAttemptDiagnostics(
        hotkeyPressedAt: nil,
        recordingStartedAt: nil,
        hotkeyReleasedAt: nil,
        processingStateShownAt: nil,
        recordingFinalizedAt: nil,
        transcriptionRequestStartedAt: nil,
        transcriptionResponseCompletedAt: nil,
        insertionCompletedAt: nil,
        stopTrigger: nil,
        clipDuration: nil,
        recordedFileSizeBytes: nil,
        transcriptCharacterCount: nil,
        transcriptWordCount: nil,
        transcriptionBackendID: nil,
        transcriptionRequestMode: nil,
        transcriptionFellBackFromStreaming: nil,
        transcriptionHTTPStatusCode: nil,
        transcriptionRequestID: nil,
        transcriptionProcessingMS: nil,
        transcriptionResponseContentType: nil
    )

    func withRecordingStarted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: timestamp,
            hotkeyReleasedAt: hotkeyReleasedAt,
            processingStateShownAt: processingStateShownAt,
            recordingFinalizedAt: recordingFinalizedAt,
            transcriptionRequestStartedAt: transcriptionRequestStartedAt,
            transcriptionResponseCompletedAt: transcriptionResponseCompletedAt,
            insertionCompletedAt: insertionCompletedAt,
            stopTrigger: stopTrigger,
            clipDuration: clipDuration,
            recordedFileSizeBytes: recordedFileSizeBytes,
            transcriptCharacterCount: transcriptCharacterCount,
            transcriptWordCount: transcriptWordCount,
            transcriptionBackendID: transcriptionBackendID,
            transcriptionRequestMode: transcriptionRequestMode,
            transcriptionFellBackFromStreaming: transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: transcriptionHTTPStatusCode,
            transcriptionRequestID: transcriptionRequestID,
            transcriptionProcessingMS: transcriptionProcessingMS,
            transcriptionResponseContentType: transcriptionResponseContentType
        )
    }

    func withHotkeyRelease(_ context: HotkeyReleaseContext) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: context.observedAt,
            processingStateShownAt: processingStateShownAt,
            recordingFinalizedAt: recordingFinalizedAt,
            transcriptionRequestStartedAt: transcriptionRequestStartedAt,
            transcriptionResponseCompletedAt: transcriptionResponseCompletedAt,
            insertionCompletedAt: insertionCompletedAt,
            stopTrigger: context.source,
            clipDuration: clipDuration,
            recordedFileSizeBytes: recordedFileSizeBytes,
            transcriptCharacterCount: transcriptCharacterCount,
            transcriptWordCount: transcriptWordCount,
            transcriptionBackendID: transcriptionBackendID,
            transcriptionRequestMode: transcriptionRequestMode,
            transcriptionFellBackFromStreaming: transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: transcriptionHTTPStatusCode,
            transcriptionRequestID: transcriptionRequestID,
            transcriptionProcessingMS: transcriptionProcessingMS,
            transcriptionResponseContentType: transcriptionResponseContentType
        )
    }

    func withFinalized(at timestamp: Date, clipDuration: TimeInterval?, fileSizeBytes: Int64?) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            processingStateShownAt: processingStateShownAt,
            recordingFinalizedAt: timestamp,
            transcriptionRequestStartedAt: transcriptionRequestStartedAt,
            transcriptionResponseCompletedAt: transcriptionResponseCompletedAt,
            insertionCompletedAt: insertionCompletedAt,
            stopTrigger: stopTrigger,
            clipDuration: clipDuration,
            recordedFileSizeBytes: fileSizeBytes,
            transcriptCharacterCount: transcriptCharacterCount,
            transcriptWordCount: transcriptWordCount,
            transcriptionBackendID: transcriptionBackendID,
            transcriptionRequestMode: transcriptionRequestMode,
            transcriptionFellBackFromStreaming: transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: transcriptionHTTPStatusCode,
            transcriptionRequestID: transcriptionRequestID,
            transcriptionProcessingMS: transcriptionProcessingMS,
            transcriptionResponseContentType: transcriptionResponseContentType
        )
    }

    func withTranscriptionResult(_ result: TranscriptionResult) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            processingStateShownAt: processingStateShownAt,
            recordingFinalizedAt: recordingFinalizedAt,
            transcriptionRequestStartedAt: transcriptionRequestStartedAt,
            transcriptionResponseCompletedAt: transcriptionResponseCompletedAt,
            insertionCompletedAt: insertionCompletedAt,
            stopTrigger: stopTrigger,
            clipDuration: clipDuration,
            recordedFileSizeBytes: recordedFileSizeBytes,
            transcriptCharacterCount: result.text.count,
            transcriptWordCount: result.text.split(whereSeparator: \.isWhitespace).count,
            transcriptionBackendID: result.backendID,
            transcriptionRequestMode: result.responseMetadata?.requestMode.title,
            transcriptionFellBackFromStreaming: result.responseMetadata?.fellBackFromStreaming,
            transcriptionHTTPStatusCode: result.responseMetadata?.httpStatusCode,
            transcriptionRequestID: result.responseMetadata?.requestID,
            transcriptionProcessingMS: result.responseMetadata?.openAIProcessingMS,
            transcriptionResponseContentType: result.responseMetadata?.contentType
        )
    }

    func withProcessingStateShown(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            processingStateShownAt: timestamp,
            recordingFinalizedAt: recordingFinalizedAt,
            transcriptionRequestStartedAt: transcriptionRequestStartedAt,
            transcriptionResponseCompletedAt: transcriptionResponseCompletedAt,
            insertionCompletedAt: insertionCompletedAt,
            stopTrigger: stopTrigger,
            clipDuration: clipDuration,
            recordedFileSizeBytes: recordedFileSizeBytes,
            transcriptCharacterCount: transcriptCharacterCount,
            transcriptWordCount: transcriptWordCount,
            transcriptionBackendID: transcriptionBackendID,
            transcriptionRequestMode: transcriptionRequestMode,
            transcriptionFellBackFromStreaming: transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: transcriptionHTTPStatusCode,
            transcriptionRequestID: transcriptionRequestID,
            transcriptionProcessingMS: transcriptionProcessingMS,
            transcriptionResponseContentType: transcriptionResponseContentType
        )
    }

    func withTranscriptionRequestStarted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            processingStateShownAt: processingStateShownAt,
            recordingFinalizedAt: recordingFinalizedAt,
            transcriptionRequestStartedAt: timestamp,
            transcriptionResponseCompletedAt: transcriptionResponseCompletedAt,
            insertionCompletedAt: insertionCompletedAt,
            stopTrigger: stopTrigger,
            clipDuration: clipDuration,
            recordedFileSizeBytes: recordedFileSizeBytes,
            transcriptCharacterCount: transcriptCharacterCount,
            transcriptWordCount: transcriptWordCount,
            transcriptionBackendID: transcriptionBackendID,
            transcriptionRequestMode: transcriptionRequestMode,
            transcriptionFellBackFromStreaming: transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: transcriptionHTTPStatusCode,
            transcriptionRequestID: transcriptionRequestID,
            transcriptionProcessingMS: transcriptionProcessingMS,
            transcriptionResponseContentType: transcriptionResponseContentType
        )
    }

    func withTranscriptionResponseCompleted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            processingStateShownAt: processingStateShownAt,
            recordingFinalizedAt: recordingFinalizedAt,
            transcriptionRequestStartedAt: transcriptionRequestStartedAt,
            transcriptionResponseCompletedAt: timestamp,
            insertionCompletedAt: insertionCompletedAt,
            stopTrigger: stopTrigger,
            clipDuration: clipDuration,
            recordedFileSizeBytes: recordedFileSizeBytes,
            transcriptCharacterCount: transcriptCharacterCount,
            transcriptWordCount: transcriptWordCount,
            transcriptionBackendID: transcriptionBackendID,
            transcriptionRequestMode: transcriptionRequestMode,
            transcriptionFellBackFromStreaming: transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: transcriptionHTTPStatusCode,
            transcriptionRequestID: transcriptionRequestID,
            transcriptionProcessingMS: transcriptionProcessingMS,
            transcriptionResponseContentType: transcriptionResponseContentType
        )
    }

    func withInsertionCompleted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            processingStateShownAt: processingStateShownAt,
            recordingFinalizedAt: recordingFinalizedAt,
            transcriptionRequestStartedAt: transcriptionRequestStartedAt,
            transcriptionResponseCompletedAt: transcriptionResponseCompletedAt,
            insertionCompletedAt: timestamp,
            stopTrigger: stopTrigger,
            clipDuration: clipDuration,
            recordedFileSizeBytes: recordedFileSizeBytes,
            transcriptCharacterCount: transcriptCharacterCount,
            transcriptWordCount: transcriptWordCount,
            transcriptionBackendID: transcriptionBackendID,
            transcriptionRequestMode: transcriptionRequestMode,
            transcriptionFellBackFromStreaming: transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: transcriptionHTTPStatusCode,
            transcriptionRequestID: transcriptionRequestID,
            transcriptionProcessingMS: transcriptionProcessingMS,
            transcriptionResponseContentType: transcriptionResponseContentType
        )
    }

    private func elapsedTime(from start: Date?, to end: Date?) -> TimeInterval? {
        guard let start, let end else {
            return nil
        }

        return end.timeIntervalSince(start)
    }
}

private actor TranscriptionTimeoutRace {
    private var continuation: CheckedContinuation<TranscriptionResult, Error>?
    private var didComplete = false

    init(continuation: CheckedContinuation<TranscriptionResult, Error>) {
        self.continuation = continuation
    }

    func complete(with result: Result<TranscriptionResult, Error>) -> Bool {
        guard !didComplete, let continuation else {
            return false
        }

        didComplete = true
        self.continuation = nil
        continuation.resume(with: result)
        return true
    }
}

enum SetupAction: Equatable {
    case requestMicrophoneAccess
    case openMicrophoneSettings
    case promptAccessibility
    case openAccessibilitySettings
    case relaunchForAccessibility

    var title: String {
        switch self {
        case .requestMicrophoneAccess:
            "Grant"
        case .openMicrophoneSettings:
            "Open Settings"
        case .promptAccessibility:
            "Enable"
        case .openAccessibilitySettings:
            "Open Settings"
        case .relaunchForAccessibility:
            "Relaunch"
        }
    }
}

@MainActor
@Observable
final class HeadCanonModel {
    @ObservationIgnored private let permissionsManager: any PermissionsManaging
    @ObservationIgnored private let permissionDebugService: any PermissionDebugging
    @ObservationIgnored private let audioCaptureService: any AudioCapturing
    @ObservationIgnored private let transcriptionBackend: any TranscriptionBackend
    @ObservationIgnored private let textInsertionService: any TextInsertionServicing
    @ObservationIgnored private let apiKeyStore: any APIKeyStoring
    @ObservationIgnored private let diagnosticsStore: any DiagnosticsStoring
    @ObservationIgnored private let hotkeyManager: any HotkeyManaging
    @ObservationIgnored private let statusOverlay: any StatusOverlayPresenting

    let preferences: AppPreferences

    var permissionSnapshot = PermissionSnapshot()
    var workflowStatus: WorkflowStatus = .setupRequired
    var apiKeyState: APIKeyState = .missing
    var availableMicrophones: [MicrophoneDevice] = []
    var lastTranscript: String?
    var lastErrorMessage: String?
    var lastValidationDate: Date?
    var lastPermissionRefreshDate: Date?
    var lastPermissionSelfTestDate: Date?
    var lastFailureStage: DiagnosticFailureStage?
    var lastDiagnosticEvent: DiagnosticEvent?
    var diagnosticEvents: [DiagnosticEvent] = []
    var lastRecordingAttemptDiagnostics: RecordingAttemptDiagnostics?
    var lastCapturedInsertionReport: InsertionAttemptReport?
    var lastInsertionAttemptReport: InsertionAttemptReport?
    var permissionDebugSnapshot: PermissionDebugSnapshot = .empty
    var permissionSelfTestResults: [PermissionSelfTestResult] = []
    @ObservationIgnored private var hasPresentedSetupWindow = false
    @ObservationIgnored private var hasPresentedLaunchWindow = false
    @ObservationIgnored private var activationObserver: NSObjectProtocol?
    @ObservationIgnored private var workspaceActivationObserver: NSObjectProtocol?
    @ObservationIgnored private var isRefreshingStatus = false
    @ObservationIgnored private var cachedAPIKey: String?
    @ObservationIgnored private var permissionRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var activeTranscriptionAttemptID: UUID?
    @ObservationIgnored private var currentAttemptID: UUID?
    @ObservationIgnored private let diagnosticsSessionID = UUID()
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "local.headcanon.app",
        category: "app-model"
    )
    @ObservationIgnored private let transcriptionTimeout: Duration

    init(
        preferences: AppPreferences = AppPreferences(),
        permissionsManager: (any PermissionsManaging)? = nil,
        permissionDebugService: (any PermissionDebugging)? = nil,
        audioCaptureService: (any AudioCapturing)? = nil,
        transcriptionBackend: (any TranscriptionBackend)? = nil,
        textInsertionService: (any TextInsertionServicing)? = nil,
        apiKeyStore: (any APIKeyStoring)? = nil,
        diagnosticsStore: (any DiagnosticsStoring)? = nil,
        hotkeyManager: (any HotkeyManaging)? = nil,
        statusOverlay: (any StatusOverlayPresenting)? = nil,
        transcriptionTimeout: Duration = .seconds(30)
    ) {
        self.preferences = preferences
        self.permissionsManager = permissionsManager ?? PermissionsManager()
        self.permissionDebugService = permissionDebugService ?? PermissionDebugService()
        self.audioCaptureService = audioCaptureService ?? AudioCaptureService()
        self.transcriptionBackend = transcriptionBackend ?? OpenAIBoundedTranscriptionBackend(
            modelProvider: { preferences.openAITranscriptionModel }
        )
        self.textInsertionService = textInsertionService ?? TextInsertionService()
        self.apiKeyStore = apiKeyStore ?? SecureAPIKeyStore()
        self.diagnosticsStore = diagnosticsStore ?? DiagnosticsStore()
        self.hotkeyManager = hotkeyManager ?? HotkeyManager()
        self.statusOverlay = statusOverlay ?? StatusOverlayController.shared
        self.transcriptionTimeout = transcriptionTimeout
        self.lastValidationDate = preferences.lastValidationDate
    }

    var isReady: Bool {
        permissionSnapshot.isReady && apiKeyAllowsDictation
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
        case .unvalidated:
            blockers.append(.apiKeyValidationRequired)
        case .invalid(let message):
            blockers.append(.apiKeyInvalid(message))
        case .keychainError(let message):
            blockers.append(.apiKeyStoreError(message))
        case .networkUnavailable(let message):
            if !apiKeyAllowsDictation {
                blockers.append(.apiKeyOffline(message))
            }
        case .valid, .validating:
            if !apiKeyAllowsDictation {
                blockers.append(.apiKeyValidationRequired)
            }
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
        setupBlockers.first?.detail ?? "Head Canon is ready."
    }

    var checkpointSummary: String {
        if !isRunningFromInstalledApplications {
            return "Launch the installed app from /Applications before testing permissions or dictation."
        }

        if !permissionSnapshot.microphone.isGranted {
            return "Blocked on microphone access."
        }

        if !permissionSnapshot.accessibility.isGranted {
            return "Blocked on Accessibility access."
        }

        switch apiKeyState {
        case .missing:
            return "Blocked on adding an OpenAI API key."
        case .unvalidated:
            return "Blocked on validating the stored OpenAI API key."
        case .validating:
            return "Validating the stored OpenAI API key."
        case .invalid(let message), .keychainError(let message), .networkUnavailable(let message):
            return message
        case .valid:
            break
        }

        if isReady && workflowStatus != .recording && workflowStatus != .transcribing && workflowStatus != .failed {
            return "Ready for the TextEdit dictation smoke test."
        }

        switch workflowStatus {
        case .setupRequired:
            return "Setup is still incomplete."
        case .ready:
            return "Ready for the TextEdit dictation smoke test."
        case .recording:
            return "Recording is in progress."
        case .transcribing:
            return "Transcription is in progress."
        case .inserted:
            return "The last transcript was inserted successfully."
        case .failed:
            return lastErrorMessage ?? "The last dictation attempt failed."
        }
    }

    var diagnosticsReport: String {
        let lines = [
            "Head Canon Diagnostics Report",
            "Generated: \(Date().formatted(date: .abbreviated, time: .standard))",
            "Bundle path: \(permissionDebugSnapshot.bundlePath)",
            "Bundle identifier: \(permissionDebugSnapshot.bundleIdentifier)",
            "Installed bundle: \(permissionDebugSnapshot.isInstalledBundle)",
            "Microphone state: \(permissionDebugSnapshot.microphoneState.title)",
            "Accessibility state: \(permissionDebugSnapshot.accessibilityState.title)",
            "AX trust check: \(permissionDebugSnapshot.accessibilityTrusted)",
            "Accessibility prompted: \(permissionDebugSnapshot.accessibilityPrompted)",
            "Accessibility relaunch requested: \(permissionDebugSnapshot.accessibilityRelaunchRequested)",
            "Accessibility diagnosis: \(permissionDebugSnapshot.diagnosis.title)",
            "Diagnosis detail: \(permissionDebugSnapshot.diagnosis.detail)",
            "Next action: \(permissionDebugSnapshot.diagnosis.nextAction)",
            "Last permission refresh: \(permissionDebugSnapshot.lastPermissionRefreshDate?.formatted(date: .abbreviated, time: .standard) ?? "Never")",
            "Last self-test run: \(permissionDebugSnapshot.lastSelfTestDate?.formatted(date: .abbreviated, time: .standard) ?? "Never")",
            "Last failure stage: \(lastFailureStage?.title ?? "None")",
            "Last event: \(lastDiagnosticEvent?.summary ?? "None")",
        ]

        let selfTests = permissionSelfTestResults.map { result in
            "- \(result.kind.title): \(result.status.title) — \(result.summary) (\(result.detail))"
        }

        return (
            lines
            + ["Self-tests:"]
            + (selfTests.isEmpty ? ["- None run yet"] : selfTests)
            + [""]
            + recordingDiagnosticReportLines
            + [""]
            + insertionDiagnosticReportLines
        ).joined(separator: "\n")
    }

    private var recordingDiagnosticReportLines: [String] {
        guard let report = lastRecordingAttemptDiagnostics else {
            return [
                "Latest recording attempt:",
                "- No recording metrics captured yet.",
            ]
        }

        return [
            "Latest recording attempt:",
            "- Hotkey pressed at: \(formattedTimestamp(report.hotkeyPressedAt))",
            "- Recording started at: \(formattedTimestamp(report.recordingStartedAt))",
            "- Press to recording start: \(formattedDuration(report.pressToRecordingStartDuration))",
            "- Hotkey released at: \(formattedTimestamp(report.hotkeyReleasedAt))",
            "- Processing state shown at: \(formattedTimestamp(report.processingStateShownAt))",
            "- Release to processing state: \(formattedDuration(report.releaseToProcessingStateDuration))",
            "- Recording finalized at: \(formattedTimestamp(report.recordingFinalizedAt))",
            "- Release to recording finalized: \(formattedDuration(report.releaseToFinalizedDuration))",
            "- Transcription request started at: \(formattedTimestamp(report.transcriptionRequestStartedAt))",
            "- Recording finalized to request start: \(formattedDuration(report.finalizedToRequestStartDuration))",
            "- Transcription response completed at: \(formattedTimestamp(report.transcriptionResponseCompletedAt))",
            "- Request start to response complete: \(formattedDuration(report.requestToResponseDuration))",
            "- Insertion completed at: \(formattedTimestamp(report.insertionCompletedAt))",
            "- Response complete to insertion complete: \(formattedDuration(report.responseToInsertionDuration))",
            "- Hotkey release to insertion complete: \(formattedDuration(report.releaseToInsertionDuration))",
            "- Stop trigger: \(report.stopTrigger?.title ?? "Unknown")",
            "- Clip duration: \(formattedDuration(report.clipDuration))",
            "- Recorded file size: \(formattedFileSize(report.recordedFileSizeBytes))",
            "- Transcript characters: \(formattedCount(report.transcriptCharacterCount))",
            "- Transcript words: \(formattedCount(report.transcriptWordCount))",
            "- Transcription backend: \(report.transcriptionBackendID ?? "Unknown")",
            "- Transcription request mode: \(report.transcriptionRequestMode ?? "Unknown")",
            "- Streaming fallback used: \(formattedBool(report.transcriptionFellBackFromStreaming))",
            "- Transcription HTTP status: \(formattedCount(report.transcriptionHTTPStatusCode))",
            "- Transcription request ID: \(report.transcriptionRequestID ?? "Unknown")",
            "- OpenAI processing time: \(formattedMilliseconds(report.transcriptionProcessingMS))",
            "- Response content type: \(report.transcriptionResponseContentType ?? "Unknown")",
        ]
    }

    private var insertionDiagnosticReportLines: [String] {
        guard lastCapturedInsertionReport != nil || lastInsertionAttemptReport != nil else {
            return [
                "Insertion routing:",
                "- No insertion target analysis has been captured yet.",
            ]
        }

        return ["Insertion routing:"]
            + insertionDiagnosticSectionLines(lastCapturedInsertionReport)
            + [""]
            + insertionDiagnosticSectionLines(lastInsertionAttemptReport)
    }

    private func insertionDiagnosticSectionLines(_ report: InsertionAttemptReport?) -> [String] {
        guard let report else {
            return ["- No report captured."]
        }

        let rejected = report.rejectedStrategies.isEmpty
            ? ["- None"]
            : report.rejectedStrategies.map { rejection in
                "- \(rejection.strategy.title): \(rejection.reason)"
            }

        let failurePrediction = report.predictedFailureClass?.title ?? "None predicted"

        return [
            "\(report.observationLabel):",
            "- Observed at: \(report.observedAt.formatted(date: .abbreviated, time: .standard))",
            "- App: \(report.capabilities.applicationName)",
            "- Bundle identifier: \(report.capabilities.bundleIdentifier ?? "Unknown")",
            "- Context kind: \(report.capabilities.contextKind.title)",
            "- Capability profile: \(report.capabilities.capabilityProfile.title)",
            "- Target: \(report.capabilities.targetLabel)",
            "- Role: \(report.capabilities.role ?? "Unknown")",
            "- Subrole: \(report.capabilities.subrole ?? "Unknown")",
            "- Placeholder present: \(report.capabilities.hasPlaceholderValue)",
            "- Placeholder likely active: \(report.capabilities.placeholderLikelyActive)",
            "- Placeholder ambiguous value detected: \(report.capabilities.placeholderAmbiguousValueDetected)",
            "- Direct insert compatible: \(report.capabilities.directInsertCompatible)",
            "- Paste compatible: \(report.capabilities.pasteCompatible)",
            "- Editable: \(report.capabilities.editable)",
            "- Secure: \(report.capabilities.secure)",
            "- Planned strategy: \(report.chosenStrategy.title)",
            "- Applied strategy: \(report.appliedStrategy?.title ?? "Not executed")",
            "- Placeholder handling: \(report.placeholderHandlingOutcome?.title ?? "Unknown")",
            "- Strategy reason: \(report.strategyReason)",
            "- Predicted failure class: \(failurePrediction)",
            "- Rejected strategies:",
        ] + rejected
    }

    var microphoneSetupAction: SetupAction? {
        switch permissionSnapshot.microphone {
        case .granted:
            nil
        case .notDetermined, .denied:
            .requestMicrophoneAccess
        case .restricted, .pending:
            .openMicrophoneSettings
        }
    }

    var accessibilitySetupAction: SetupAction? {
        switch permissionSnapshot.accessibility {
        case .granted:
            nil
        case .notDetermined:
            .promptAccessibility
        case .pending:
            .relaunchForAccessibility
        case .denied, .restricted:
            .openAccessibilitySettings
        }
    }

    var currentAppPath: String {
        Bundle.main.bundleURL.path
    }

    var isRunningFromInstalledApplications: Bool {
        Self.isInstalledApplicationsBundle(path: currentAppPath)
    }

    var runtimeWarningMessage: String? {
        guard !isRunningFromInstalledApplications else {
            return nil
        }

        return "This copy is running outside /Applications. Open /Applications/HeadCanon.app so macOS can keep Microphone and Accessibility approvals attached to one installed app bundle."
    }

    var shouldRetainTranscript: Bool {
        preferences.historyRetentionMode != .neverStore
    }

    var historyRetentionSummary: String {
        preferences.historyRetentionMode.currentBehaviorDetail
    }

    private var hasStoredAPIKey: Bool {
        guard let cachedAPIKey else {
            return false
        }

        return !cachedAPIKey.isEmpty
    }

    private var apiKeyAllowsDictation: Bool {
        switch apiKeyState {
        case .valid:
            return hasStoredAPIKey
        case .networkUnavailable:
            guard let cachedAPIKey else {
                return false
            }
            return hasStoredAPIKey && preferences.hasCachedValidation(for: cachedAPIKey)
        case .missing, .unvalidated, .validating, .invalid, .keychainError:
            return false
        }
    }

    func start() {
        Task {
            await bootstrap()
        }
    }

    func bootstrap() async {
        installLifecycleObservers()
        applyPrivacyPreferences()
        cachedAPIKey = loadAPIKeyFromStore()
        logger.notice("Bootstrapping app from \(Bundle.main.bundleURL.path, privacy: .public)")
        recordDiagnosticEvent(
            "Bootstrapped app from \(Bundle.main.bundleURL.path)",
            isFailure: false
        )
        await refreshRuntimeStatus(validateAPIKeyRemotely: false, presentSetupWindow: false)
        registerHotkey()
        recalculateWorkflowStatus()
        presentLaunchWindowIfNeeded()
        if !isReady {
            presentSetupWindowIfNeeded(force: true)
        }
    }

    func requestStatusRefresh(validateAPIKeyRemotely: Bool = false, presentSetupWindow: Bool = false) {
        Task { @MainActor in
            await refreshRuntimeStatus(
                validateAPIKeyRemotely: validateAPIKeyRemotely,
                presentSetupWindow: presentSetupWindow
            )
        }
    }

    func refreshRuntimeStatus(validateAPIKeyRemotely: Bool = false, presentSetupWindow: Bool = true) async {
        guard !isRefreshingStatus else {
            return
        }

        isRefreshingStatus = true
        defer {
            isRefreshingStatus = false
        }

        refreshPermissions()
        refreshMicrophones()
        await refreshAPIKeyState(
            validateRemotely: validateAPIKeyRemotely,
            presentSetupWindow: presentSetupWindow
        )
    }

    func refreshPermissions() {
        let previousSnapshot = permissionSnapshot
        permissionSnapshot = permissionsManager.refreshStatus()
        lastPermissionRefreshDate = Date()
        if permissionSnapshot.accessibility.isGranted {
            UserDefaults.standard.removeObject(forKey: PermissionDebugDefaultsKeys.accessibilityRelaunchRequested)
        }
        refreshPermissionDebugSnapshot()
        if previousSnapshot != permissionSnapshot {
            recordDiagnosticEvent(
                "Permissions updated: Microphone \(permissionSnapshot.microphone.title) · Accessibility \(permissionSnapshot.accessibility.title)",
                isFailure: false
            )
        }
        updatePermissionRefreshLoop()
        recalculateWorkflowStatus()
    }

    func requestMicrophoneAccess() {
        Task { @MainActor in
            let result = await permissionsManager.requestMicrophoneAccess()
            refreshPermissions()

            if result == .denied && permissionSnapshot.microphone == .denied {
                recordDiagnosticEvent(
                    "Microphone request did not prompt or was denied. Opening System Settings.",
                    stage: .permissionReadiness,
                    isFailure: false
                )
                openMicrophoneSettings()
            }
        }
    }

    func promptForAccessibility() {
        permissionsManager.promptForAccessibility()
        recordDiagnosticEvent(
            "Prompted for Accessibility access for the current app bundle.",
            isFailure: false
        )
        refreshPermissions()
    }

    func refreshPermissionDebugger() {
        refreshPermissions()
        recordDiagnosticEvent(
            "Refreshed the permission debugger snapshot.",
            stage: .permissionReadiness,
            isFailure: false
        )
    }

    func runPermissionSelfTests() {
        permissionSelfTestResults = permissionDebugService.runSelfTests(using: permissionDebugSnapshot)
        lastPermissionSelfTestDate = Date()
        refreshPermissionDebugSnapshot()

        if let failingResult = permissionSelfTestResults.first(where: { $0.status == .failed }) {
            recordFailure(.permissionReadiness, message: "\(failingResult.kind.title) failed: \(failingResult.summary)")
        } else {
            recordDiagnosticEvent(
                "Permission self-tests completed successfully.",
                stage: .permissionReadiness,
                isFailure: false
            )
        }
    }

    func copyDiagnosticsReport() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(diagnosticsReport, forType: .string)
        recordDiagnosticEvent(
            "Copied the full diagnostics report.",
            isFailure: false
        )
    }

    func performSetupAction(_ action: SetupAction) {
        switch action {
        case .requestMicrophoneAccess:
            requestMicrophoneAccess()
        case .openMicrophoneSettings:
            openMicrophoneSettings()
        case .promptAccessibility:
            promptForAccessibility()
        case .openAccessibilitySettings:
            openAccessibilitySettings()
        case .relaunchForAccessibility:
            relaunchApp()
        }
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
            let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try apiKeyStore.saveAPIKey(trimmedAPIKey)
            cachedAPIKey = trimmedAPIKey
            await refreshAPIKeyState(validateRemotely: true)
            if isReady {
                lastErrorMessage = nil
                hasPresentedSetupWindow = true
            }
        } catch {
            apiKeyState = apiKeyErrorState(for: error)
            preferences.clearValidatedAPIKeyState()
            setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
        }
    }

    func removeAPIKey() {
        do {
            try apiKeyStore.removeAPIKey()
            cachedAPIKey = nil
            apiKeyState = .missing
            lastValidationDate = nil
            preferences.clearValidatedAPIKeyState()
            recalculateWorkflowStatus()
            presentSetupWindowIfNeeded(force: true)
        } catch {
            apiKeyState = apiKeyErrorState(for: error)
            setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
        }
    }

    func refreshAPIKeyState() async {
        await refreshAPIKeyState(validateRemotely: true, presentSetupWindow: true)
    }

    func validateAPIKeyRemotely() async {
        await refreshAPIKeyState(validateRemotely: true, presentSetupWindow: true)
    }

    func refreshAPIKeyState(validateRemotely: Bool, presentSetupWindow: Bool = true) async {
        if cachedAPIKey == nil {
            cachedAPIKey = loadAPIKeyFromStore()
        }

        guard let apiKey = cachedAPIKey, !apiKey.isEmpty else {
            if case .keychainError = apiKeyState {
                recalculateWorkflowStatus()
                if presentSetupWindow {
                    presentSetupWindowIfNeeded()
                }
                return
            }

            apiKeyState = .missing
            lastValidationDate = nil
            preferences.clearValidatedAPIKeyState()
            recalculateWorkflowStatus()
            if presentSetupWindow {
                presentSetupWindowIfNeeded()
            }
            return
        }

        guard validateRemotely else {
            apiKeyState = preferences.hasCachedValidation(for: apiKey) ? .valid : .unvalidated
            lastValidationDate = preferences.hasCachedValidation(for: apiKey) ? preferences.lastValidationDate : nil
            lastErrorMessage = nil
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
            let validationDate = Date()
            lastValidationDate = validationDate
            preferences.persistValidatedAPIKey(apiKey, validatedAt: validationDate)
            lastErrorMessage = nil
        } catch let error as TranscriptionBackendError {
            switch error {
            case .invalidAPIKey:
                apiKeyState = .invalid("The stored OpenAI API key was rejected.")
                lastValidationDate = nil
                preferences.clearValidatedAPIKeyState()
            case .networkUnavailable:
                apiKeyState = .networkUnavailable("Head Canon could not reach OpenAI to validate the key.")
                lastValidationDate = preferences.hasCachedValidation(for: apiKey) ? preferences.lastValidationDate : nil
            case .timeout:
                apiKeyState = .networkUnavailable("Head Canon timed out while validating the stored API key.")
                lastValidationDate = preferences.hasCachedValidation(for: apiKey) ? preferences.lastValidationDate : nil
            case .unexpectedResponse(let statusCode):
                apiKeyState = .invalid("OpenAI returned an unexpected status code: \(statusCode).")
                lastValidationDate = nil
                preferences.clearValidatedAPIKeyState()
            case .invalidResponse:
                apiKeyState = .invalid("OpenAI returned an invalid validation response.")
                lastValidationDate = nil
                preferences.clearValidatedAPIKeyState()
            case .serializationFailure, .notImplemented:
                apiKeyState = .invalid("Head Canon could not validate the stored API key.")
                lastValidationDate = nil
                preferences.clearValidatedAPIKeyState()
            }
        } catch {
            apiKeyState = .invalid(error.localizedDescription)
            lastValidationDate = nil
            preferences.clearValidatedAPIKeyState()
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

        lastRecordingAttemptDiagnostics = .empty
        currentAttemptID = UUID()
        lastCapturedInsertionReport = nil
        lastInsertionAttemptReport = nil

        Task {
            @MainActor in
            do {
                lastInsertionAttemptReport = try await textInsertionService.insert(
                    lastTranscript,
                    target: nil,
                    allowPasteFallback: preferences.pasteFallbackEnabled,
                    observationLabel: "Current Context"
                )
                recordDiagnosticEvent("Recovered the last transcript into the current target context.", stage: .insertion, isFailure: false)
                setWorkflowStatus(.inserted)
                persistCurrentAttempt(terminalState: .inserted)
            } catch {
                recordFailure(.insertion, message: error.localizedDescription)
                setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
                persistCurrentAttempt(
                    terminalState: .failed,
                    failureStage: .insertion,
                    failureMessage: error.localizedDescription
                )
            }
        }
    }

    func openSettingsWindow() {
        SettingsWindowController.shared.show(model: self)
        hasPresentedSetupWindow = true
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

    func openDiagnosticsFolder() {
        let diagnosticsStore = self.diagnosticsStore
        let logger = self.logger

        Task {
            do {
                let directoryURL = try await diagnosticsStore.diagnosticsDirectoryURL()
                await MainActor.run {
                    NSWorkspace.shared.activateFileViewerSelecting([directoryURL])
                }
            } catch {
                logger.error("Failed to open diagnostics folder: \(error.localizedDescription, privacy: .public)")
            }
        }
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
        UserDefaults.standard.set(true, forKey: PermissionDebugDefaultsKeys.accessibilityRelaunchRequested)
        refreshPermissionDebugSnapshot()
        recordDiagnosticEvent(
            "Queued relaunch for \(appURL.path).",
            stage: .permissionReadiness,
            isFailure: false
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c",
            "sleep 1; open \"$1\"",
            "headcanon-relaunch",
            appURL.path,
        ]

        do {
            try process.run()
        } catch {
            recordFailure(.permissionReadiness, message: "Failed to relaunch Head Canon: \(error.localizedDescription)")
            setWorkflowStatus(
                .failed,
                errorMessage: "Failed to relaunch Head Canon: \(error.localizedDescription)"
            )
            return
        }

        NSApplication.shared.terminate(nil)
    }

    func resetHotkeyToDefault() {
        preferences.hotkey = .defaultPushToTalk
        registerHotkey()
    }

    func setHotkey(_ shortcut: HotkeyShortcut) {
        guard preferences.hotkey != shortcut else {
            return
        }

        preferences.hotkey = shortcut
        registerHotkey()
    }

    func clearLastTranscript() {
        lastTranscript = nil
    }

    func clearDiagnosticHistory() {
        diagnosticEvents.removeAll()
        lastDiagnosticEvent = nil
        lastFailureStage = nil
        lastRecordingAttemptDiagnostics = nil
        lastCapturedInsertionReport = nil
        lastInsertionAttemptReport = nil

        let diagnosticsStore = self.diagnosticsStore
        let logger = self.logger
        Task {
            do {
                try await diagnosticsStore.clear()
            } catch {
                logger.error("Failed to clear persistent diagnostics: \(error.localizedDescription, privacy: .public)")
            }
        }
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
                onRelease: { [weak self] context in
                    self?.handleHotkeyReleased(context)
                }
            )
            recordDiagnosticEvent(
                "Registered hotkey: \(preferences.hotkey.displayString)",
                stage: .hotkey,
                isFailure: false
            )
        } catch {
            recordFailure(.hotkey, message: "Failed to register the hotkey: \(error.localizedDescription)")
            setWorkflowStatus(
                .failed,
                errorMessage: "Failed to register the hotkey: \(error.localizedDescription)"
            )
        }
    }

    func analyzeFocusedInsertionTarget() {
        lastCapturedInsertionReport = nil
        lastInsertionAttemptReport = nil
        recordDiagnosticEvent(
            "Preparing insertion-target analysis. Head Canon will briefly hide to inspect the previously active app.",
            stage: .insertion,
            isFailure: false
        )

        NSApplication.shared.hide(nil)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))

            do {
                lastInsertionAttemptReport = try textInsertionService.planInsertion(
                    target: nil,
                    allowPasteFallback: preferences.pasteFallbackEnabled,
                    observationLabel: "Analysis-Time Context"
                )

                if let report = lastInsertionAttemptReport {
                    recordDiagnosticEvent(
                        "Insertion target analyzed for \(report.capabilities.applicationName) using \(report.chosenStrategy.title).",
                        stage: .insertion,
                        isFailure: false
                    )
                }
            } catch {
                lastInsertionAttemptReport = nil
                recordFailure(.insertion, message: error.localizedDescription)
            }

            SettingsWindowController.shared.show(model: self)
        }
    }

    private func installLifecycleObservers() {
        if activationObserver == nil {
            activationObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshPermissions()
                    self?.refreshMicrophones()
                }
            }
        }

        if workspaceActivationObserver == nil {
            workspaceActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshPermissions()
                }
            }
        }
    }

    private func startPermissionRefreshLoop() {
        guard permissionRefreshTask == nil else {
            return
        }

        permissionRefreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else {
                    return
                }
                self.refreshPermissionsIfNeeded()
            }
        }
    }

    private func refreshPermissionsIfNeeded() {
        guard !permissionSnapshot.accessibility.isGranted else {
            stopPermissionRefreshLoop()
            return
        }

        refreshPermissions()
    }

    private func stopPermissionRefreshLoop() {
        permissionRefreshTask?.cancel()
        permissionRefreshTask = nil
    }

    private func updatePermissionRefreshLoop() {
        if permissionSnapshot.accessibility.isGranted {
            stopPermissionRefreshLoop()
        } else {
            startPermissionRefreshLoop()
        }
    }

    private func handleHotkeyPressed() {
        let now = Date()
        recordDiagnosticEvent("Observed hotkey press.", stage: .hotkey, isFailure: false)

        guard isReady else {
            recordFailure(
                .permissionReadiness,
                message: setupBlockers.first?.detail ?? "Head Canon is not ready for dictation yet."
            )
            setWorkflowStatus(.setupRequired, errorMessage: setupBlockers.first?.detail)
            presentSetupWindowIfNeeded(force: true)
            return
        }

        guard workflowStatus != .transcribing else {
            recordDiagnosticEvent(
                "Ignored hotkey press because transcription is still in progress.",
                stage: .transcription,
                isFailure: false
            )
            return
        }

        guard !audioCaptureService.isRecording else {
            recordDiagnosticEvent("Ignored hotkey press because recording is already active.", stage: .hotkey, isFailure: false)
            return
        }

        lastRecordingAttemptDiagnostics = RecordingAttemptDiagnostics(
            hotkeyPressedAt: now,
            recordingStartedAt: nil,
            hotkeyReleasedAt: nil,
            processingStateShownAt: nil,
            recordingFinalizedAt: nil,
            transcriptionRequestStartedAt: nil,
            transcriptionResponseCompletedAt: nil,
            insertionCompletedAt: nil,
            stopTrigger: nil,
            clipDuration: nil,
            recordedFileSizeBytes: nil,
            transcriptCharacterCount: nil,
            transcriptWordCount: nil,
            transcriptionBackendID: nil,
            transcriptionRequestMode: nil,
            transcriptionFellBackFromStreaming: nil,
            transcriptionHTTPStatusCode: nil,
            transcriptionRequestID: nil,
            transcriptionProcessingMS: nil,
            transcriptionResponseContentType: nil
        )
        currentAttemptID = UUID()

        do {
            try audioCaptureService.startRecording(preferredDeviceID: preferences.selectedMicrophoneID)
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withRecordingStarted(at: Date())
            recordDiagnosticEvent("Recording started from the global hotkey.", stage: .recordingStart, isFailure: false)
            setWorkflowStatus(.recording)
        } catch {
            recordFailure(.recordingStart, message: error.localizedDescription)
            persistCurrentAttempt(
                terminalState: .failed,
                failureStage: .recordingStart,
                failureMessage: error.localizedDescription
            )
            setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
        }
    }

    private func handleHotkeyReleased(_ context: HotkeyReleaseContext) {
        Task { @MainActor in
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withHotkeyRelease(context)
            guard audioCaptureService.isRecording else {
                recordDiagnosticEvent(
                    "Observed hotkey release from \(context.source.title) without an active recording.",
                    stage: .hotkey,
                    isFailure: false
                )
                return
            }

            let processingStateTimestamp = Date()
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withProcessingStateShown(at: processingStateTimestamp)
            recordDiagnosticEvent(
                "Hotkey released via \(context.source.title). Moving immediately into processing state.",
                stage: .hotkey,
                isFailure: false
            )
            setWorkflowStatus(.transcribing)

            let insertionTarget: (any TextInsertionTargetHandle)?
            let insertionTargetError: String?

            do {
                insertionTarget = try textInsertionService.captureFocusedTarget()
                insertionTargetError = nil
                lastCapturedInsertionReport = try? textInsertionService.planInsertion(
                    target: insertionTarget,
                    allowPasteFallback: preferences.pasteFallbackEnabled,
                    observationLabel: "Release-Time Context"
                )
            } catch {
                insertionTarget = nil
                insertionTargetError = error.localizedDescription
                lastCapturedInsertionReport = nil
            }

            let input: BoundedAudioInput

            do {
                input = try await audioCaptureService.stopRecording()
            } catch {
                recordFailure(.recordingStop, message: error.localizedDescription)
                persistCurrentAttempt(
                    terminalState: .failed,
                    failureStage: .recordingStop,
                    failureMessage: error.localizedDescription
                )
                setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
                return
            }

            let finalizedAt = Date()
            let fileSizeBytes = fileSizeInBytes(at: input.fileURL)
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withFinalized(
                at: finalizedAt,
                clipDuration: input.duration,
                fileSizeBytes: fileSizeBytes
            )

            recordDiagnosticEvent(
                "Recording finalized via \(context.source.title). Clip \(formattedDuration(input.duration)) · \(formattedFileSize(fileSizeBytes)). Starting transcription.",
                stage: .recordingStop,
                isFailure: false
            )
            let attemptID = UUID()
            activeTranscriptionAttemptID = attemptID
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionRequestStarted(at: Date())
            recordDiagnosticEvent(
                "Transcription request started with a \(Int(transcriptionTimeout.timeInterval.rounded())) second timeout.",
                stage: .transcription,
                isFailure: false
            )
            await transcribeAndInsert(
                input,
                insertionTarget: insertionTarget,
                insertionTargetError: insertionTargetError,
                attemptID: attemptID
            )
        }
    }

    private func transcribeAndInsert(
        _ input: BoundedAudioInput,
        insertionTarget: (any TextInsertionTargetHandle)?,
        insertionTargetError: String?,
        attemptID: UUID
    ) async {
        defer {
            try? FileManager.default.removeItem(at: input.fileURL)
            if activeTranscriptionAttemptID == attemptID {
                activeTranscriptionAttemptID = nil
            }
        }

        if cachedAPIKey == nil {
            cachedAPIKey = loadAPIKeyFromStore()
        }

        guard let apiKey = cachedAPIKey, !apiKey.isEmpty else {
            apiKeyState = .missing
            recordFailure(.permissionReadiness, message: APIKeyState.missing.detail)
            persistCurrentAttempt(
                terminalState: .failed,
                failureStage: .permissionReadiness,
                failureMessage: APIKeyState.missing.detail
            )
            setWorkflowStatus(.setupRequired, errorMessage: APIKeyState.missing.detail)
            presentSetupWindowIfNeeded(force: true)
            return
        }

        do {
            let result = try await transcribeWithTimeout(input, apiKey: apiKey)
            guard activeTranscriptionAttemptID == attemptID else {
                recordDiagnosticEvent(
                    "Ignored stale transcription completion from \(result.backendID).",
                    stage: .transcription,
                    isFailure: false
                )
                return
            }
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResponseCompleted(at: Date())
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResult(result)
            recordDiagnosticEvent(
                "Transcription succeeded via \(result.backendID). \(result.text.count) chars · \(result.text.split(whereSeparator: \.isWhitespace).count) words from \(formattedDuration(result.duration)).",
                stage: .transcription,
                isFailure: false
            )
            if result.responseMetadata?.fellBackFromStreaming == true {
                recordDiagnosticEvent(
                    "Streamed transcription fell back to the standard response path for this turn.",
                    stage: .transcription,
                    isFailure: false
                )
            }
            retainTranscriptIfAllowed(result.text)

            guard let insertionTarget else {
                lastInsertionAttemptReport = nil
                recordFailure(
                    .insertion,
                    message: insertionTargetError ?? TextInsertionError.focusUnavailable.localizedDescription
                )
                setWorkflowStatus(
                    .failed,
                    errorMessage: insertionTargetError ?? TextInsertionError.focusUnavailable.localizedDescription
                )
                persistCurrentAttempt(
                    terminalState: .failed,
                    failureStage: .insertion,
                    failureMessage: insertionTargetError ?? TextInsertionError.focusUnavailable.localizedDescription
                )
                return
            }

            lastInsertionAttemptReport = try textInsertionService.planInsertion(
                target: insertionTarget,
                allowPasteFallback: preferences.pasteFallbackEnabled,
                observationLabel: "Insert-Time Context"
            )

            lastInsertionAttemptReport = try await textInsertionService.insert(
                result.text,
                target: insertionTarget,
                allowPasteFallback: preferences.pasteFallbackEnabled,
                observationLabel: "Insert-Time Context"
            )

            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withInsertionCompleted(at: Date())
            recordDiagnosticEvent("Transcript inserted into the intended target context.", stage: .insertion, isFailure: false)
            setWorkflowStatus(.inserted)
            persistCurrentAttempt(terminalState: .inserted)
        } catch let error as TranscriptionBackendError {
            guard activeTranscriptionAttemptID == attemptID else {
                return
            }
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResponseCompleted(at: Date())
            if case .invalidAPIKey = error {
                apiKeyState = .invalid("The stored OpenAI API key was rejected.")
                lastValidationDate = nil
                preferences.clearValidatedAPIKeyState()
            }
            recordFailure(.transcription, message: error.localizedDescription)
            let terminalState: DictationAttemptTerminalState = if case .timeout = error {
                .timedOut
            } else {
                .failed
            }
            persistCurrentAttempt(
                terminalState: terminalState,
                failureStage: .transcription,
                failureMessage: error.localizedDescription
            )
            setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
        } catch is CancellationError {
            guard activeTranscriptionAttemptID == attemptID else {
                return
            }
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResponseCompleted(at: Date())
            recordFailure(.transcription, message: "Head Canon canceled the transcription request.")
            persistCurrentAttempt(
                terminalState: .canceled,
                failureStage: .transcription,
                failureMessage: "Head Canon canceled the transcription request."
            )
            setWorkflowStatus(.failed, errorMessage: "Head Canon canceled the transcription request.")
        } catch {
            guard activeTranscriptionAttemptID == attemptID else {
                return
            }
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResponseCompleted(at: Date())
            recordFailure(.insertion, message: error.localizedDescription)
            persistCurrentAttempt(
                terminalState: .failed,
                failureStage: .insertion,
                failureMessage: error.localizedDescription
            )
            setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
        }
    }

    private func retainTranscriptIfAllowed(_ text: String) {
        lastTranscript = shouldRetainTranscript ? text : nil
    }

    private func refreshPermissionDebugSnapshot() {
        permissionDebugSnapshot = permissionDebugService.snapshot(
            for: PermissionDebugContext(
                bundlePath: currentAppPath,
                bundleIdentifier: Bundle.main.bundleIdentifier ?? "local.headcanon.app",
                isInstalledBundle: isRunningFromInstalledApplications,
                microphoneState: permissionSnapshot.microphone,
                accessibilityState: permissionSnapshot.accessibility,
                lastPermissionRefreshDate: lastPermissionRefreshDate,
                lastSelfTestDate: lastPermissionSelfTestDate
            )
        )
    }

    private func recalculateWorkflowStatus() {
        guard workflowStatus != .recording && workflowStatus != .transcribing else {
            return
        }

        if !permissionSnapshot.isReady || !apiKeyAllowsDictation {
            setWorkflowStatus(.setupRequired)
        } else {
            setWorkflowStatus(.ready)
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

    private func presentLaunchWindowIfNeeded() {
        guard !hasPresentedLaunchWindow else {
            return
        }

        hasPresentedLaunchWindow = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.openSettingsWindow()
        }
    }

    private func setWorkflowStatus(_ status: WorkflowStatus, errorMessage: String? = nil) {
        workflowStatus = status
        lastErrorMessage = errorMessage
        statusOverlay.update(status: status, detail: overlayDetail(for: status, errorMessage: errorMessage))
    }

    private func recordFailure(_ stage: DiagnosticFailureStage, message: String) {
        lastFailureStage = stage
        recordDiagnosticEvent(message, stage: stage, isFailure: true)
    }

    private func recordDiagnosticEvent(
        _ summary: String,
        stage: DiagnosticFailureStage? = nil,
        isFailure: Bool
    ) {
        let event = DiagnosticEvent(
            timestamp: Date(),
            summary: summary,
            stage: stage,
            isFailure: isFailure
        )
        lastDiagnosticEvent = event
        diagnosticEvents.insert(event, at: 0)
        if diagnosticEvents.count > 8 {
            diagnosticEvents.removeLast(diagnosticEvents.count - 8)
        }
    }

    private func persistCurrentAttempt(
        terminalState: DictationAttemptTerminalState,
        failureStage: DiagnosticFailureStage? = nil,
        failureMessage: String? = nil
    ) {
        guard let record = makePersistentAttemptRecord(
            terminalState: terminalState,
            failureStage: failureStage,
            failureMessage: failureMessage
        ) else {
            return
        }

        let diagnosticsStore = self.diagnosticsStore
        let logger = self.logger
        Task {
            do {
                try await diagnosticsStore.persist(record)
            } catch {
                logger.error("Failed to persist diagnostics record: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func makePersistentAttemptRecord(
        terminalState: DictationAttemptTerminalState,
        failureStage: DiagnosticFailureStage?,
        failureMessage: String?
    ) -> DictationAttemptRecord? {
        guard let attemptID = currentAttemptID else {
            return nil
        }

        currentAttemptID = nil
        let metrics = lastRecordingAttemptDiagnostics ?? .empty
        let releaseTimeInsertionReport = lastCapturedInsertionReport
        let insertionReport = lastInsertionAttemptReport ?? lastCapturedInsertionReport

        return DictationAttemptRecord(
            schemaVersion: DictationAttemptRecord.schemaVersion,
            attemptID: attemptID,
            sessionID: diagnosticsSessionID,
            completedAt: Date(),
            terminalState: terminalState,
            hotkeyDisplayString: preferences.hotkey.displayString,
            bundle: DictationAttemptBundleRecord(
                path: currentAppPath,
                identifier: Bundle.main.bundleIdentifier ?? "local.headcanon.app",
                isInstalledBundle: isRunningFromInstalledApplications
            ),
            timing: DictationAttemptTimingRecord(
                hotkeyPressedAt: metrics.hotkeyPressedAt,
                recordingStartedAt: metrics.recordingStartedAt,
                hotkeyReleasedAt: metrics.hotkeyReleasedAt,
                processingStateShownAt: metrics.processingStateShownAt,
                recordingFinalizedAt: metrics.recordingFinalizedAt,
                transcriptionRequestStartedAt: metrics.transcriptionRequestStartedAt,
                transcriptionResponseCompletedAt: metrics.transcriptionResponseCompletedAt,
                insertionCompletedAt: metrics.insertionCompletedAt,
                stopTrigger: metrics.stopTrigger?.rawValue,
                pressToRecordingStartDurationMS: durationMilliseconds(metrics.pressToRecordingStartDuration),
                releaseToProcessingStateDurationMS: durationMilliseconds(metrics.releaseToProcessingStateDuration),
                releaseToFinalizedDurationMS: durationMilliseconds(metrics.releaseToFinalizedDuration),
                finalizedToRequestStartDurationMS: durationMilliseconds(metrics.finalizedToRequestStartDuration),
                requestToResponseDurationMS: durationMilliseconds(metrics.requestToResponseDuration),
                responseToInsertionDurationMS: durationMilliseconds(metrics.responseToInsertionDuration),
                releaseToInsertionDurationMS: durationMilliseconds(metrics.releaseToInsertionDuration)
            ),
            audio: DictationAttemptAudioRecord(
                clipDurationMS: durationMilliseconds(metrics.clipDuration),
                recordedFileSizeBytes: metrics.recordedFileSizeBytes
            ),
            transcript: DictationAttemptTranscriptRecord(
                characterCount: metrics.transcriptCharacterCount,
                wordCount: metrics.transcriptWordCount
            ),
            backend: DictationAttemptBackendRecord(
                identifier: metrics.transcriptionBackendID,
                requestMode: metrics.transcriptionRequestMode,
                fellBackFromStreaming: metrics.transcriptionFellBackFromStreaming,
                httpStatusCode: metrics.transcriptionHTTPStatusCode,
                requestID: metrics.transcriptionRequestID,
                openAIProcessingMS: metrics.transcriptionProcessingMS,
                responseContentType: metrics.transcriptionResponseContentType
            ),
            releaseTimeInsertion: releaseTimeInsertionReport.map { report in
                DictationAttemptInsertionRecord(
                    observationLabel: report.observationLabel,
                    applicationName: report.capabilities.applicationName,
                    bundleIdentifier: report.capabilities.bundleIdentifier,
                    target: report.capabilities.targetLabel,
                    contextKind: report.capabilities.contextKind.rawValue,
                    capabilityProfile: report.capabilities.capabilityProfile.rawValue,
                    chosenStrategy: report.chosenStrategy.rawValue,
                    appliedStrategy: report.appliedStrategy?.rawValue,
                    strategyReason: report.strategyReason,
                    predictedFailureClass: report.predictedFailureClass?.rawValue,
                    placeholderPresent: report.capabilities.hasPlaceholderValue,
                    placeholderLikelyActive: report.capabilities.placeholderLikelyActive,
                    placeholderAmbiguousValueDetected: report.capabilities.placeholderAmbiguousValueDetected,
                    placeholderHandlingOutcome: report.placeholderHandlingOutcome?.rawValue,
                    valueReadable: report.capabilities.valueReadable,
                    valueSettable: report.capabilities.valueSettable,
                    selectedTextRangeReadable: report.capabilities.selectedTextRangeReadable,
                    selectedTextReadable: report.capabilities.selectedTextReadable,
                    editable: report.capabilities.editable,
                    secure: report.capabilities.secure,
                    pasteCompatible: report.capabilities.pasteCompatible,
                    directInsertCompatible: report.capabilities.directInsertCompatible
                )
            },
            insertion: insertionReport.map { report in
                DictationAttemptInsertionRecord(
                    observationLabel: report.observationLabel,
                    applicationName: report.capabilities.applicationName,
                    bundleIdentifier: report.capabilities.bundleIdentifier,
                    target: report.capabilities.targetLabel,
                    contextKind: report.capabilities.contextKind.rawValue,
                    capabilityProfile: report.capabilities.capabilityProfile.rawValue,
                    chosenStrategy: report.chosenStrategy.rawValue,
                    appliedStrategy: report.appliedStrategy?.rawValue,
                    strategyReason: report.strategyReason,
                    predictedFailureClass: report.predictedFailureClass?.rawValue,
                    placeholderPresent: report.capabilities.hasPlaceholderValue,
                    placeholderLikelyActive: report.capabilities.placeholderLikelyActive,
                    placeholderAmbiguousValueDetected: report.capabilities.placeholderAmbiguousValueDetected,
                    placeholderHandlingOutcome: report.placeholderHandlingOutcome?.rawValue,
                    valueReadable: report.capabilities.valueReadable,
                    valueSettable: report.capabilities.valueSettable,
                    selectedTextRangeReadable: report.capabilities.selectedTextRangeReadable,
                    selectedTextReadable: report.capabilities.selectedTextReadable,
                    editable: report.capabilities.editable,
                    secure: report.capabilities.secure,
                    pasteCompatible: report.capabilities.pasteCompatible,
                    directInsertCompatible: report.capabilities.directInsertCompatible
                )
            },
            failure: failureStage.map { stage in
                DictationAttemptFailureRecord(
                    stage: stage.rawValue,
                    message: failureMessage ?? lastErrorMessage ?? "Unknown failure."
                )
            }
        )
    }

    private func formattedTimestamp(_ timestamp: Date?) -> String {
        timestamp?.formatted(date: .abbreviated, time: .standard) ?? "Unknown"
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

    private func formattedCount(_ count: Int?) -> String {
        guard let count else {
            return "Unknown"
        }

        return String(count)
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

    private func durationMilliseconds(_ duration: TimeInterval?) -> Int? {
        guard let duration else {
            return nil
        }

        return Int((duration * 1000).rounded())
    }

    private func transcribeWithTimeout(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        let backend = transcriptionBackend
        let timeout = transcriptionTimeout

        return try await withCheckedThrowingContinuation { continuation in
            let race = TranscriptionTimeoutRace(continuation: continuation)

            Task { @MainActor [backend] in
                let result: Result<TranscriptionResult, Error>

                do {
                    result = .success(try await backend.transcribe(input, apiKey: apiKey))
                } catch {
                    result = .failure(error)
                }

                _ = await race.complete(with: result)
            }

            Task { [timeout] in
                do {
                    try await Task.sleep(for: timeout)
                } catch {
                    return
                }

                _ = await race.complete(
                    with: .failure(TranscriptionBackendError.timeout(timeout.timeInterval))
                )
            }
        }
    }

    private func fileSizeInBytes(at fileURL: URL) -> Int64? {
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let size = attributes[.size] as? NSNumber
        else {
            return nil
        }

        return size.int64Value
    }

    private func loadAPIKeyFromStore() -> String? {
        do {
            guard let apiKey = try apiKeyStore.loadAPIKey() else {
                return nil
            }

            let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedAPIKey.isEmpty ? nil : trimmedAPIKey
        } catch {
            handleAPIKeyLoadFailure(error)
            return nil
        }
    }

    private func handleAPIKeyLoadFailure(_ error: Error) {
        cachedAPIKey = nil
        lastValidationDate = nil
        preferences.clearValidatedAPIKeyState()
        apiKeyState = .keychainError(error.localizedDescription)
    }

    private func apiKeyErrorState(for error: Error) -> APIKeyState {
        if error is APIKeyStoreError {
            return .keychainError(error.localizedDescription)
        }

        return .invalid(error.localizedDescription)
    }

    private func overlayDetail(for status: WorkflowStatus, errorMessage: String?) -> String? {
        if let errorMessage, !errorMessage.isEmpty {
            return errorMessage
        }

        switch status {
        case .setupRequired, .ready:
            return nil
        case .recording:
            return "Speak now. Release the keys to transcribe."
        case .transcribing:
            return "Converting your recording into text."
        case .inserted:
            return "Transcript inserted into the active app."
        case .failed:
            return "Head Canon hit an error."
        }
    }

    private static func isInstalledApplicationsBundle(path: String) -> Bool {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        return standardizedPath.hasPrefix("/Applications/")
            || standardizedPath.hasPrefix(NSHomeDirectory() + "/Applications/")
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
