import AppKit
import Foundation
import Observation
import OSLog

enum WorkflowStatus: String {
    case setupRequired
    case ready
    case recording
    case finalizingRecording
    case startingTranscription
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
        case .finalizingRecording:
            "Finalizing"
        case .startingTranscription:
            "Starting Transcription"
        case .transcribing:
            "Transcribing"
        case .inserted:
            "Inserted"
        case .failed:
            "Needs Attention"
        }
    }

    var blocksNewDictation: Bool {
        switch self {
        case .recording, .finalizingRecording, .startingTranscription, .transcribing:
            true
        case .setupRequired, .ready, .inserted, .failed:
            false
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
    case diskSpaceLow(String)

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
        case .diskSpaceLow:
            "diskSpaceLow"
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
        case .diskSpaceLow:
            "Disk space"
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
        case .diskSpaceLow(let message):
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

enum ClipboardRecoveryReason: String, Equatable, Codable {
    case missingInsertionTarget
    case insertionSafetyBlock
    case insertionFailure
}

struct ClipboardRecoveryState: Equatable {
    let transcriptCopied: Bool
    let reason: ClipboardRecoveryReason
}

enum HotkeyReleaseSource: String, Equatable, Identifiable {
    case carbonKeyUp
    case globalModifierMonitor
    case localModifierMonitor
    case modifierStateWatchdog
    case recordingReleaseWatchdog
    case recordingDurationLimit
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
        case .modifierStateWatchdog:
            "Modifier State Watchdog"
        case .recordingReleaseWatchdog:
            "Recording Release Watchdog"
        case .recordingDurationLimit:
            "Recording Duration Limit"
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
    let finalizingStateShownAt: Date?
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
    let transcriptionResponseHeadersReceivedMS: Int?
    let transcriptionTransportFailureStage: String?
    let transcriptionNetworkErrorDomain: String?
    let transcriptionNetworkErrorCode: Int?
    let transcriptionNetworkErrorCodeName: String?
    let transcriptionResponseBodyByteCount: Int?
    let transcriptionResponseBodyUTF8Decodable: Bool?
    let transcriptionResponseBodyTrimmedCharacterCount: Int?
    let transcriptionResponseContentLengthBytes: Int?

    var pressToRecordingStartDuration: TimeInterval? {
        elapsedTime(from: hotkeyPressedAt, to: recordingStartedAt)
    }

    var releaseToFinalizingStateDuration: TimeInterval? {
        elapsedTime(from: hotkeyReleasedAt, to: finalizingStateShownAt)
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
        finalizingStateShownAt: nil,
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
        transcriptionResponseContentType: nil,
        transcriptionResponseHeadersReceivedMS: nil,
        transcriptionTransportFailureStage: nil,
        transcriptionNetworkErrorDomain: nil,
        transcriptionNetworkErrorCode: nil,
        transcriptionNetworkErrorCodeName: nil,
        transcriptionResponseBodyByteCount: nil,
        transcriptionResponseBodyUTF8Decodable: nil,
        transcriptionResponseBodyTrimmedCharacterCount: nil,
        transcriptionResponseContentLengthBytes: nil
    )

    func withRecordingStarted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: timestamp,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionResponseContentType: transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: transcriptionResponseContentLengthBytes
        )
    }

    func withHotkeyRelease(_ context: HotkeyReleaseContext) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: context.observedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionResponseContentType: transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: transcriptionResponseContentLengthBytes
        )
    }

    func withFinalized(at timestamp: Date, clipDuration: TimeInterval?, fileSizeBytes: Int64?) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionResponseContentType: transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: transcriptionResponseContentLengthBytes
        )
    }

    func withTranscriptionResult(_ result: TranscriptionResult) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionResponseContentType: result.responseMetadata?.contentType,
            transcriptionResponseHeadersReceivedMS: result.responseMetadata?.responseHeadersReceivedMS,
            transcriptionTransportFailureStage: nil,
            transcriptionNetworkErrorDomain: nil,
            transcriptionNetworkErrorCode: nil,
            transcriptionNetworkErrorCodeName: nil,
            transcriptionResponseBodyByteCount: nil,
            transcriptionResponseBodyUTF8Decodable: nil,
            transcriptionResponseBodyTrimmedCharacterCount: nil,
            transcriptionResponseContentLengthBytes: nil
        )
    }

    func withTranscriptionFailureContext(_ context: TranscriptionFailureContext?) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionRequestMode: context?.requestMode.title ?? transcriptionRequestMode,
            transcriptionFellBackFromStreaming: context?.fellBackFromStreaming ?? transcriptionFellBackFromStreaming,
            transcriptionHTTPStatusCode: context?.httpStatusCode ?? transcriptionHTTPStatusCode,
            transcriptionRequestID: context?.requestID ?? transcriptionRequestID,
            transcriptionProcessingMS: context?.openAIProcessingMS ?? transcriptionProcessingMS,
            transcriptionResponseContentType: context?.contentType ?? transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: context?.responseHeadersReceivedMS ?? transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: context?.transportFailureStage?.rawValue ?? transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: context?.networkErrorDomain ?? transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: context?.networkErrorCode ?? transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: context?.networkErrorCodeName ?? transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: context?.responseBodyByteCount ?? transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: context?.responseBodyUTF8Decodable ?? transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: context?.responseBodyTrimmedCharacterCount ?? transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: context?.responseContentLengthBytes ?? transcriptionResponseContentLengthBytes
        )
    }

    func withFinalizingStateShown(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: timestamp,
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
            transcriptionResponseContentType: transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: transcriptionResponseContentLengthBytes
        )
    }

    func withTranscriptionRequestStarted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionResponseContentType: transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: transcriptionResponseContentLengthBytes
        )
    }

    func withTranscriptionResponseCompleted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionResponseContentType: transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: transcriptionResponseContentLengthBytes
        )
    }

    func withInsertionCompleted(at timestamp: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: recordingStartedAt,
            hotkeyReleasedAt: hotkeyReleasedAt,
            finalizingStateShownAt: finalizingStateShownAt,
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
            transcriptionResponseContentType: transcriptionResponseContentType,
            transcriptionResponseHeadersReceivedMS: transcriptionResponseHeadersReceivedMS,
            transcriptionTransportFailureStage: transcriptionTransportFailureStage,
            transcriptionNetworkErrorDomain: transcriptionNetworkErrorDomain,
            transcriptionNetworkErrorCode: transcriptionNetworkErrorCode,
            transcriptionNetworkErrorCodeName: transcriptionNetworkErrorCodeName,
            transcriptionResponseBodyByteCount: transcriptionResponseBodyByteCount,
            transcriptionResponseBodyUTF8Decodable: transcriptionResponseBodyUTF8Decodable,
            transcriptionResponseBodyTrimmedCharacterCount: transcriptionResponseBodyTrimmedCharacterCount,
            transcriptionResponseContentLengthBytes: transcriptionResponseContentLengthBytes
        )
    }

    private func elapsedTime(from start: Date?, to end: Date?) -> TimeInterval? {
        guard let start, let end else {
            return nil
        }

        return end.timeIntervalSince(start)
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
    @ObservationIgnored private let clipboardWriter: any ClipboardWriting
    @ObservationIgnored private let diskSpaceReadinessService: DiskSpaceReadinessService

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
    var lastAttemptTruthState: DictationAttemptTruthState?
    var lastDiagnosticEvent: DiagnosticEvent?
    var diagnosticEvents: [DiagnosticEvent] = []
    var lastRecordingAttemptDiagnostics: RecordingAttemptDiagnostics?
    var lastCapturedInsertionReport: InsertionAttemptReport?
    var lastInsertionAttemptReport: InsertionAttemptReport?
    var lastClipboardRecovery: ClipboardRecoveryState?
    var permissionDebugSnapshot: PermissionDebugSnapshot = .empty
    var permissionSelfTestResults: [PermissionSelfTestResult] = []
    var diskSpaceReadiness: DiskSpaceReadiness?
    var browserCompanionStatus: BrowserCompanionStatus = .empty
    @ObservationIgnored private var hasPresentedSetupWindow = false
    @ObservationIgnored private var hasPresentedLaunchWindow = false
    @ObservationIgnored private var activationObserver: NSObjectProtocol?
    @ObservationIgnored private var workspaceActivationObserver: NSObjectProtocol?
    @ObservationIgnored private var isRefreshingStatus = false
    @ObservationIgnored private var cachedAPIKey: String?
    @ObservationIgnored private var permissionRefreshTask: Task<Void, Never>?
    @ObservationIgnored private var recordingDurationLimitTask: Task<Void, Never>?
    @ObservationIgnored private var recordingReleaseWatchdogTask: Task<Void, Never>?
    @ObservationIgnored private var diskReserveMaintenanceTask: Task<Void, Never>?
    @ObservationIgnored private var liveDiagnosticsPersistTask: Task<Void, Never>?
    @ObservationIgnored private var activeTranscriptionAttemptID: UUID?
    @ObservationIgnored private var currentAttemptID: UUID?
    @ObservationIgnored private let diagnosticsSessionID = UUID()
    @ObservationIgnored private let minimumTranscriptionDuration: TimeInterval = 1.0
    @ObservationIgnored private let maxTransientTranscriptionAttempts = 2
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "local.headcanon.app",
        category: "app-model"
    )
    @ObservationIgnored private let hotkeyStateProvider: (HotkeyShortcut) -> Bool
    @ObservationIgnored private let transcriptionTimeout: Duration
    @ObservationIgnored private let maximumRecordingDuration: Duration
    @ObservationIgnored private let browserCompanionMonitor: any BrowserCompanionMonitoring

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
        clipboardWriter: (any ClipboardWriting)? = nil,
        diskSpaceChecker: (any DiskSpaceChecking)? = nil,
        diskSpaceReserver: (any DiskSpaceReserving)? = nil,
        browserCompanionMonitor: (any BrowserCompanionMonitoring)? = nil,
        diskSpacePolicy: DiskSpacePolicy = .default,
        hotkeyStateProvider: @escaping (HotkeyShortcut) -> Bool = { $0.isPressedInCurrentSession() },
        transcriptionTimeout: Duration = .seconds(30),
        maximumRecordingDuration: Duration = .seconds(90)
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
        self.clipboardWriter = clipboardWriter ?? SystemClipboardWriter()
        self.browserCompanionMonitor = browserCompanionMonitor ?? BrowserCompanionMonitor()
        self.diskSpaceReadinessService = DiskSpaceReadinessService(
            checker: diskSpaceChecker ?? VolumeDiskSpaceChecker(),
            reserver: diskSpaceReserver ?? DiskSpaceReserveManager(),
            policy: diskSpacePolicy,
            monitoredURL: AudioCaptureService.recordingsDirectoryURL
        )
        self.hotkeyStateProvider = hotkeyStateProvider
        self.transcriptionTimeout = transcriptionTimeout
        self.maximumRecordingDuration = maximumRecordingDuration
        self.lastValidationDate = preferences.lastValidationDate
        self.audioCaptureService.unexpectedRecordingCompletionHandler = { [weak self] completion in
            self?.handleUnexpectedAudioCaptureCompletion(completion)
        }
    }

    var isReady: Bool {
        permissionSnapshot.isReady && apiKeyAllowsDictation && !isDiskSpaceBlocked
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

        if let diskSpaceReadiness, let blockingMessage = diskSpaceReadiness.blockingMessage {
            blockers.append(.diskSpaceLow(blockingMessage))
        }

        return blockers
    }

    var menuBarSymbolName: String {
        switch workflowStatus {
        case .recording:
            "waveform.circle.fill"
        case .finalizingRecording, .startingTranscription, .transcribing:
            "ellipsis.circle.fill"
        case .ready, .inserted:
            "mic.circle.fill"
        case .setupRequired, .failed:
            "exclamationmark.circle.fill"
        }
    }

    var canCancelCurrentDictation: Bool {
        workflowStatus.blocksNewDictation
    }

    var canFinalizeCurrentRecording: Bool {
        workflowStatus == .recording
    }

    var statusSummary: String {
        if workflowStatus == .inserted, let lastAttemptTruthState {
            return lastAttemptTruthState.detail
        }

        if workflowStatus == .failed, let lastErrorMessage, !lastErrorMessage.isEmpty {
            return lastErrorMessage
        }

        if let setupBlocker = setupBlockers.first {
            return setupBlocker.detail
        }

        if let diskSpaceWarningMessage {
            return diskSpaceWarningMessage
        }

        return "Head Canon is ready."
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

        if let blockingMessage = diskSpaceReadiness?.blockingMessage {
            return blockingMessage
        }

        if workflowStatus == .inserted, let lastAttemptTruthState {
            return lastAttemptTruthState.detail
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

        if let diskSpaceWarningMessage {
            return diskSpaceWarningMessage
        }

        if isReady && !workflowStatus.blocksNewDictation && workflowStatus != .failed && workflowStatus != .inserted {
            return "Ready for the TextEdit dictation smoke test."
        }

        switch workflowStatus {
        case .setupRequired:
            return "Setup is still incomplete."
        case .ready:
            return "Ready for the TextEdit dictation smoke test."
        case .recording:
            return "Recording is in progress."
        case .finalizingRecording:
            return "Recording is being finalized."
        case .startingTranscription:
            return "Transcription request is starting."
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
            "Disk readiness: \(diskSpaceReadiness?.status.title ?? "Unknown")",
            "Disk free space: \(diskSpaceReadiness?.freeSpaceLabel ?? "Unknown")",
            "Disk reserve: \(diskSpaceReadiness?.reservation.status.title ?? "Unknown")",
            "Disk reserved space: \(diskSpaceReadiness?.reservation.reservedSpaceLabel ?? "Unknown")",
            "Browser companion status: \(browserCompanionStatus.statusTitle)",
            "Browser companion detail: \(browserCompanionStatus.statusDetail)",
            "Last failure stage: \(lastFailureStage?.title ?? "None")",
            "Last truth state: \(lastAttemptTruthState?.title ?? "None")",
            "Last event: \(lastDiagnosticEvent?.summary ?? "None")",
        ]

        let selfTests = permissionSelfTestResults.map { result in
            "- \(result.kind.title): \(result.status.title) — \(result.summary) (\(result.detail))"
        }
        let browserInstallations = browserCompanionStatus.installations.map { installation in
            "- \(installation.title): \(installation.isInstalled ? "Installed" : "Missing") · Host reachable: \(installation.hostScriptReachable ? "Yes" : "No") · Extensions: \(installation.allowedExtensionIDs.isEmpty ? "None" : installation.allowedExtensionIDs.joined(separator: ", "))"
        }

        return (
            lines
            + ["Self-tests:"]
            + (selfTests.isEmpty ? ["- None run yet"] : selfTests)
            + [""]
            + ["Browser Companion Installations:"]
            + (browserInstallations.isEmpty ? ["- None checked yet"] : browserInstallations)
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
            "- Finalizing state shown at: \(formattedTimestamp(report.finalizingStateShownAt))",
            "- Release to finalizing state: \(formattedDuration(report.releaseToFinalizingStateDuration))",
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
            "- Request start to response headers: \(formattedMilliseconds(report.transcriptionResponseHeadersReceivedMS))",
            "- Transport failure stage: \(report.transcriptionTransportFailureStage ?? "Unknown")",
            "- Network error domain: \(report.transcriptionNetworkErrorDomain ?? "Unknown")",
            "- Network error code: \(formattedCount(report.transcriptionNetworkErrorCode))",
            "- Network error code name: \(report.transcriptionNetworkErrorCodeName ?? "Unknown")",
            "- Response body bytes: \(formattedCount(report.transcriptionResponseBodyByteCount))",
            "- Response body UTF-8 decodable: \(formattedBool(report.transcriptionResponseBodyUTF8Decodable))",
            "- Response body trimmed characters: \(formattedCount(report.transcriptionResponseBodyTrimmedCharacterCount))",
            "- Response content length: \(formattedCount(report.transcriptionResponseContentLengthBytes))",
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
        ] + browserDiagnosticLines(for: report.capabilities.browserMetadata) + [
            "- Rejected strategies:",
        ] + rejected
    }

    private func browserDiagnosticLines(for metadata: BrowserTargetMetadata?) -> [String] {
        guard let metadata else {
            return []
        }

        return [
            "- Browser host: \(metadata.browser.title)",
            "- Browser target class: \(metadata.targetClass.title)",
            "- Browser editor family: \(metadata.editorFamily.title)",
            "- Browser verification mode: \(metadata.verificationMode.title)",
            "- Browser origin: \(metadata.pageOrigin ?? "Unknown")",
            "- Browser page title: \(metadata.pageTitle ?? "Unknown")",
            "- Browser frame path: \(metadata.framePath ?? "Unknown")",
            "- Browser frame identifier: \(metadata.frameIdentifier ?? "Unknown")",
            "- Browser fingerprint: \(metadata.targetFingerprint ?? "Unknown")",
            "- Browser operation ID: \(metadata.operationID?.uuidString ?? "Unknown")",
            "- Browser focus captured at: \(formattedTimestamp(metadata.focusCapturedAt))",
            "- Browser focus validated at: \(formattedTimestamp(metadata.focusValidatedAt))",
            "- Browser protocol version: \(metadata.protocolVersion.map(String.init) ?? "Unknown")",
            "- Browser extension version: \(metadata.extensionVersion ?? "Unknown")",
        ]
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

    var diskSpaceWarningMessage: String? {
        diskSpaceReadiness?.warningMessage
    }

    var diskSpaceReserveSummary: String? {
        guard let diskSpaceReadiness else {
            return nil
        }

        return diskSpaceReadiness.reservation.detail
    }

    private var isDiskSpaceBlocked: Bool {
        diskSpaceReadiness?.status == .blocked
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
        scheduleDiskReserveMaintenanceIfNeeded()
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
        refreshDiskSpaceReadiness()
        refreshBrowserCompanionStatus()
        await refreshAPIKeyState(
            validateRemotely: validateAPIKeyRemotely,
            presentSetupWindow: presentSetupWindow
        )
        recalculateWorkflowStatus()
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
        _ = clipboardWriter.write(diagnosticsReport)
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

    func refreshBrowserCompanionStatus() {
        let previousStatus = browserCompanionStatus
        browserCompanionStatus = browserCompanionMonitor.currentStatus()

        guard previousStatus != browserCompanionStatus else {
            return
        }

        recordDiagnosticEvent(
            "Browser companion status updated: \(browserCompanionStatus.statusDetail)",
            stage: .insertion,
            isFailure: false
        )
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
            case .unexpectedResponse(let statusCode, _):
                apiKeyState = .invalid("OpenAI returned an unexpected status code: \(statusCode).")
                lastValidationDate = nil
                preferences.clearValidatedAPIKeyState()
            case .invalidResponse, .emptyTranscript:
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

        beginAttempt(at: nil)

        Task {
            @MainActor in
            do {
                lastInsertionAttemptReport = try await textInsertionService.insert(
                    lastTranscript,
                    target: nil,
                    allowPasteFallback: preferences.pasteFallbackEnabled,
                    observationLabel: "Current Context"
                )
                let truthState = truthState(for: lastInsertionAttemptReport)
                lastAttemptTruthState = truthState
                recordDiagnosticEvent(
                    insertionSuccessMessage(for: truthState, recoveryAttempt: true),
                    stage: .insertion,
                    isFailure: false
                )
                setWorkflowStatus(.inserted)
                persistCurrentAttempt(
                    terminalState: .inserted,
                    truthState: truthState
                )
            } catch {
                lastAttemptTruthState = truthState(forInsertionError: error)
                recordFailure(.insertion, message: error.localizedDescription)
                setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
                persistCurrentAttempt(
                    terminalState: .failed,
                    truthState: lastAttemptTruthState ?? .insertionFailed,
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
        _ = clipboardWriter.write(currentAppPath)
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

    func copyLastTranscript() {
        applyPrivacyPreferences()

        guard let lastTranscript, !lastTranscript.isEmpty else {
            recordDiagnosticEvent(
                "Copy Last Transcript was requested, but no retained transcript is available.",
                isFailure: false
            )
            return
        }

        if clipboardWriter.write(lastTranscript) {
            lastClipboardRecovery = ClipboardRecoveryState(
                transcriptCopied: true,
                reason: .insertionFailure
            )
            recordDiagnosticEvent(
                "Copied the last transcript to the clipboard for manual recovery.",
                stage: .insertion,
                isFailure: false
            )
        } else {
            lastClipboardRecovery = ClipboardRecoveryState(
                transcriptCopied: false,
                reason: .insertionFailure
            )
            recordDiagnosticEvent(
                "Head Canon could not copy the last transcript to the clipboard.",
                stage: .insertion,
                isFailure: true
            )
        }
    }

    func finalizeCurrentRecordingNow() {
        guard workflowStatus == .recording else {
            recordDiagnosticEvent(
                "Finalize Recording Now was requested, but no recording was active.",
                stage: .recordingStop,
                isFailure: false
            )
            return
        }

        guard audioCaptureService.isRecording else {
            failStaleRecordingState(
                message: "Finalize Recording Now found no active audio capture, so Head Canon cleared the stale recording state."
            )
            return
        }

        recordDiagnosticEvent(
            "Finalize Recording Now requested from the app UI.",
            stage: .recordingStop,
            isFailure: false
        )
        handleHotkeyReleased(
            HotkeyReleaseContext(
                source: .unknown,
                observedAt: Date()
            )
        )
    }

    func cancelCurrentDictation() {
        guard workflowStatus.blocksNewDictation else {
            recordDiagnosticEvent(
                "Cancel Current Dictation was requested, but no dictation was in progress.",
                isFailure: false
            )
            return
        }

        cancelRecordingReleaseWatchdog()
        cancelRecordingDurationLimit()
        audioCaptureService.cancelRecording()
        activeTranscriptionAttemptID = nil
        lastAttemptTruthState = .transcriptionCanceled
        let message = "Head Canon canceled the current dictation from the app UI."
        recordFailure(.recordingStop, message: message)
        persistCurrentAttempt(
            terminalState: .canceled,
            truthState: .transcriptionCanceled,
            failureStage: .recordingStop,
            failureMessage: message
        )
        setWorkflowStatus(.failed, errorMessage: message)
    }

    func clearDiagnosticHistory() {
        diagnosticEvents.removeAll()
        lastDiagnosticEvent = nil
        lastFailureStage = nil
        lastAttemptTruthState = nil
        lastRecordingAttemptDiagnostics = nil
        lastCapturedInsertionReport = nil
        lastInsertionAttemptReport = nil
        lastClipboardRecovery = nil

        let diagnosticsStore = self.diagnosticsStore
        let logger = self.logger
        Task {
            do {
                try await diagnosticsStore.clear()
                persistLiveState()
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
        cancelDiskReserveMaintenance()

        releaseDiskReserveForRecordingIfNeeded()

        refreshDiskSpaceReadiness()

        if let blockingMessage = diskSpaceReadiness?.blockingMessage {
            beginAttempt(at: now)
            lastAttemptTruthState = .systemReadinessBlocked
            recordFailure(.permissionReadiness, message: blockingMessage)
            persistCurrentAttempt(
                terminalState: .failed,
                truthState: .systemReadinessBlocked,
                failureStage: .permissionReadiness,
                failureMessage: blockingMessage
            )
            setWorkflowStatus(.setupRequired, errorMessage: blockingMessage)
            presentSetupWindowIfNeeded(force: true)
            return
        }

        guard isReady else {
            beginAttempt(at: now)
            lastAttemptTruthState = .systemReadinessBlocked
            let message = setupBlockers.first?.detail ?? "Head Canon is not ready for dictation yet."
            recordFailure(
                .permissionReadiness,
                message: message
            )
            persistCurrentAttempt(
                terminalState: .failed,
                truthState: .systemReadinessBlocked,
                failureStage: .permissionReadiness,
                failureMessage: message
            )
            setWorkflowStatus(.setupRequired, errorMessage: message)
            presentSetupWindowIfNeeded(force: true)
            return
        }

        guard !workflowStatus.blocksNewDictation else {
            recordDiagnosticEvent(
                "Ignored hotkey press because dictation processing is still in progress.",
                stage: .hotkey,
                isFailure: false
            )
            return
        }

        guard !audioCaptureService.isRecording else {
            recordDiagnosticEvent("Ignored hotkey press because recording is already active.", stage: .hotkey, isFailure: false)
            return
        }

        beginAttempt(at: now)

        do {
            try audioCaptureService.startRecording(preferredDeviceID: preferences.selectedMicrophoneID)
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withRecordingStarted(at: Date())
            recordDiagnosticEvent("Recording started from the global hotkey.", stage: .recordingStart, isFailure: false)
            setWorkflowStatus(.recording)
            startRecordingReleaseWatchdog()
            startRecordingDurationLimit()
        } catch {
            let message = actionableRecordingFailureMessage(for: error)
            lastAttemptTruthState = .recordingFailed
            recordFailure(.recordingStart, message: message)
            persistCurrentAttempt(
                terminalState: .failed,
                truthState: .recordingFailed,
                failureStage: .recordingStart,
                failureMessage: message
            )
            setWorkflowStatus(.failed, errorMessage: userFacingRecordingFailureMessage(for: error))
        }
    }

    private func handleHotkeyReleased(_ context: HotkeyReleaseContext) {
        Task { @MainActor in
            cancelRecordingReleaseWatchdog()
            cancelRecordingDurationLimit()
            guard workflowStatus == .recording else {
                return
            }

            guard audioCaptureService.isRecording else {
                failStaleRecordingState(
                    message: "Head Canon saw a hotkey release after audio capture had already stopped, so it cleared the stale recording state."
                )
                return
            }

            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withHotkeyRelease(context)
            let processingStateTimestamp = Date()
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withFinalizingStateShown(at: processingStateTimestamp)
            recordDiagnosticEvent(
                "Hotkey released via \(context.source.title). Moving into recording finalization.",
                stage: .hotkey,
                isFailure: false
            )
            setWorkflowStatus(.finalizingRecording)

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
                let message = actionableRecordingFailureMessage(for: error)
                lastAttemptTruthState = .recordingFailed
                recordFailure(.recordingStop, message: message)
                persistCurrentAttempt(
                    terminalState: .failed,
                    truthState: .recordingFailed,
                    failureStage: .recordingStop,
                    failureMessage: message
                )
                setWorkflowStatus(.failed, errorMessage: userFacingRecordingFailureMessage(for: error))
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
            guard recordingIsLongEnoughForTranscription(input) else {
                let message = "Recording was too short to transcribe reliably. Hold the hotkey a little longer and try again."
                lastAttemptTruthState = .noSpeechDetected
                recordFailure(.transcription, message: message)
                persistCurrentAttempt(
                    terminalState: .failed,
                    truthState: .noSpeechDetected,
                    failureStage: .transcription,
                    failureMessage: message
                )
                setWorkflowStatus(.failed, errorMessage: message)
                return
            }
            let attemptID = UUID()
            activeTranscriptionAttemptID = attemptID
            await transcribeAndInsert(
                input,
                insertionTarget: insertionTarget,
                insertionTargetError: insertionTargetError,
                attemptID: attemptID
            )
        }
    }

    private func handleUnexpectedAudioCaptureCompletion(_ completion: AudioCaptureUnexpectedCompletion) {
        guard workflowStatus == .recording else {
            recordDiagnosticEvent(
                "Audio capture completed unexpectedly while workflow status was \(workflowStatus.title).",
                stage: .recordingStop,
                isFailure: workflowStatus.blocksNewDictation
            )
            return
        }

        switch completion {
        case .finished(let input):
            continueAfterUnexpectedAudioCompletion(input)
        case .failed(let message):
            failStaleRecordingState(message: message)
        }
    }

    private func continueAfterUnexpectedAudioCompletion(_ input: BoundedAudioInput) {
        cancelRecordingReleaseWatchdog()
        cancelRecordingDurationLimit()

        let recoveryContext = HotkeyReleaseContext(source: .unknown, observedAt: Date())
        let finalizingAt = Date()
        lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty)
            .withHotkeyRelease(recoveryContext)
            .withFinalizingStateShown(at: finalizingAt)
            .withFinalized(
                at: finalizingAt,
                clipDuration: input.duration,
                fileSizeBytes: fileSizeInBytes(at: input.fileURL)
            )
        recordDiagnosticEvent(
            "Audio capture finished before a normal hotkey release path completed. Recovering with the finalized recording.",
            stage: .recordingStop,
            isFailure: false
        )
        setWorkflowStatus(.finalizingRecording)

        let insertionTarget: (any TextInsertionTargetHandle)?
        let insertionTargetError: String?

        do {
            insertionTarget = try textInsertionService.captureFocusedTarget()
            insertionTargetError = nil
            lastCapturedInsertionReport = try? textInsertionService.planInsertion(
                target: insertionTarget,
                allowPasteFallback: preferences.pasteFallbackEnabled,
                observationLabel: "Unexpected Audio Completion Context"
            )
        } catch {
            insertionTarget = nil
            insertionTargetError = error.localizedDescription
            lastCapturedInsertionReport = nil
        }

        let attemptID = UUID()
        activeTranscriptionAttemptID = attemptID
        Task { @MainActor [weak self] in
            await self?.transcribeAndInsert(
                input,
                insertionTarget: insertionTarget,
                insertionTargetError: insertionTargetError,
                attemptID: attemptID
            )
        }
    }

    private func failStaleRecordingState(message: String) {
        guard workflowStatus == .recording else {
            return
        }

        cancelRecordingReleaseWatchdog()
        cancelRecordingDurationLimit()
        audioCaptureService.cancelRecording()
        lastAttemptTruthState = .recordingFailed
        recordFailure(.recordingStop, message: message)
        persistCurrentAttempt(
            terminalState: .failed,
            truthState: .recordingFailed,
            failureStage: .recordingStop,
            failureMessage: message
        )
        setWorkflowStatus(.failed, errorMessage: message)
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
                persistLiveState()
            }
        }

        var transcribedTextForRecovery: String?

        if cachedAPIKey == nil {
            cachedAPIKey = loadAPIKeyFromStore()
        }

        guard let apiKey = cachedAPIKey, !apiKey.isEmpty else {
            apiKeyState = .missing
            lastAttemptTruthState = .setupBlocked
            recordFailure(.permissionReadiness, message: APIKeyState.missing.detail)
            persistCurrentAttempt(
                terminalState: .failed,
                truthState: .setupBlocked,
                failureStage: .permissionReadiness,
                failureMessage: APIKeyState.missing.detail
            )
            setWorkflowStatus(.setupRequired, errorMessage: APIKeyState.missing.detail)
            presentSetupWindowIfNeeded(force: true)
            return
        }

        do {
            setWorkflowStatus(.startingTranscription)
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionRequestStarted(at: Date())
            recordDiagnosticEvent(
                "Transcription request started with a \(Int(transcriptionTimeout(for: input).timeInterval.rounded())) second timeout.",
                stage: .transcription,
                isFailure: false
            )
            setWorkflowStatus(.transcribing)
            let result = try await transcribeWithRetry(input, apiKey: apiKey)
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
            transcribedTextForRecovery = result.text
            retainTranscriptIfAllowed(result.text)

            guard let insertionTarget else {
                lastInsertionAttemptReport = nil
                lastAttemptTruthState = .insertionFailed
                let failureMessage = handleInsertionFailure(
                    afterSuccessfulTranscription: result.text,
                    baseMessage: insertionTargetError ?? TextInsertionError.focusUnavailable.localizedDescription,
                    reason: .missingInsertionTarget
                )
                persistCurrentAttempt(
                    terminalState: .failed,
                    truthState: .insertionFailed,
                    failureStage: .insertion,
                    failureMessage: failureMessage
                )
                return
            }

            lastInsertionAttemptReport = try textInsertionService.planExecutionInsertion(
                relativeTo: insertionTarget,
                allowPasteFallback: preferences.pasteFallbackEnabled,
                observationLabel: "Insert-Time Context"
            )

            lastInsertionAttemptReport = try await textInsertionService.insert(
                result.text,
                target: insertionTarget,
                allowPasteFallback: preferences.pasteFallbackEnabled,
                observationLabel: "Insert-Time Context"
            )

            let truthState = truthState(for: lastInsertionAttemptReport)
            lastAttemptTruthState = truthState
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withInsertionCompleted(at: Date())
            recordDiagnosticEvent(insertionSuccessMessage(for: truthState), stage: .insertion, isFailure: false)
            setWorkflowStatus(.inserted)
            persistCurrentAttempt(
                terminalState: .inserted,
                truthState: truthState
            )
        } catch let error as TranscriptionBackendError {
            guard activeTranscriptionAttemptID == attemptID else {
                return
            }
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResponseCompleted(at: Date())
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionFailureContext(
                transcriptionFailureContext(from: error)
            )
            let truthState = truthState(for: error)
            lastAttemptTruthState = truthState
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
                truthState: truthState,
                failureStage: .transcription,
                failureMessage: error.localizedDescription
            )
            setWorkflowStatus(.failed, errorMessage: error.localizedDescription)
        } catch is CancellationError {
            guard activeTranscriptionAttemptID == attemptID else {
                return
            }
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResponseCompleted(at: Date())
            lastAttemptTruthState = .transcriptionCanceled
            recordFailure(.transcription, message: "Head Canon canceled the transcription request.")
            persistCurrentAttempt(
                terminalState: .canceled,
                truthState: .transcriptionCanceled,
                failureStage: .transcription,
                failureMessage: "Head Canon canceled the transcription request."
            )
            setWorkflowStatus(.failed, errorMessage: "Head Canon canceled the transcription request.")
        } catch {
            guard activeTranscriptionAttemptID == attemptID else {
                return
            }
            lastRecordingAttemptDiagnostics = (lastRecordingAttemptDiagnostics ?? .empty).withTranscriptionResponseCompleted(at: Date())
            let truthState = truthState(forInsertionError: error)
            lastAttemptTruthState = truthState
            let failureMessage = handleInsertionFailure(
                afterSuccessfulTranscription: transcribedTextForRecovery ?? "",
                baseMessage: error.localizedDescription,
                reason: clipboardRecoveryReason(for: error)
            )
            persistCurrentAttempt(
                terminalState: .failed,
                truthState: truthState,
                failureStage: .insertion,
                failureMessage: failureMessage
            )
        }
    }

    private func retainTranscriptIfAllowed(_ text: String) {
        lastTranscript = shouldRetainTranscript ? text : nil
    }

    @discardableResult
    private func handleInsertionFailure(
        afterSuccessfulTranscription text: String,
        baseMessage: String,
        reason: ClipboardRecoveryReason
    ) -> String {
        guard !text.isEmpty else {
            lastClipboardRecovery = ClipboardRecoveryState(transcriptCopied: false, reason: reason)
            recordFailure(.insertion, message: baseMessage)
            setWorkflowStatus(.failed, errorMessage: baseMessage)
            return baseMessage
        }

        let copied = clipboardWriter.write(text)
        lastClipboardRecovery = ClipboardRecoveryState(transcriptCopied: copied, reason: reason)

        let failureMessage: String
        if copied {
            failureMessage = "\(baseMessage) Transcript copied to clipboard for manual paste."
            recordDiagnosticEvent(
                "Head Canon copied the transcript to the clipboard for manual paste recovery.",
                stage: .insertion,
                isFailure: false
            )
        } else {
            failureMessage = baseMessage
            recordDiagnosticEvent(
                "Head Canon preserved the transcript, but could not copy it to the clipboard for manual paste.",
                stage: .insertion,
                isFailure: true
            )
        }

        recordFailure(.insertion, message: failureMessage)
        setWorkflowStatus(.failed, errorMessage: failureMessage)
        return failureMessage
    }

    private func clipboardRecoveryReason(for error: Error) -> ClipboardRecoveryReason {
        guard let insertionError = error as? TextInsertionError else {
            return .insertionFailure
        }

        switch insertionError {
        case .focusChanged, .placeholderCleanupRequired, .secureTarget, .unsupportedTarget:
            return .insertionSafetyBlock
        case .focusUnavailable, .accessibilityPermissionRequired, .accessibilityAPIError, .pasteFailed, .pasteDeliveryUnconfirmed, .pasteFallbackDisabled:
            return .insertionFailure
        }
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
        guard
            !workflowStatus.blocksNewDictation,
            workflowStatus != .failed,
            workflowStatus != .inserted
        else {
            return
        }

        if !permissionSnapshot.isReady || !apiKeyAllowsDictation || isDiskSpaceBlocked {
            setWorkflowStatus(.setupRequired)
        } else {
            setWorkflowStatus(.ready)
        }
    }

    private func beginAttempt(at hotkeyPressedAt: Date?) {
        lastRecordingAttemptDiagnostics = hotkeyPressedAt.map { recordingAttemptDiagnostics(hotkeyPressedAt: $0) } ?? .empty
        currentAttemptID = UUID()
        lastCapturedInsertionReport = nil
        lastInsertionAttemptReport = nil
        lastClipboardRecovery = nil
        lastAttemptTruthState = nil
    }

    private func recordingAttemptDiagnostics(hotkeyPressedAt: Date) -> RecordingAttemptDiagnostics {
        RecordingAttemptDiagnostics(
            hotkeyPressedAt: hotkeyPressedAt,
            recordingStartedAt: nil,
            hotkeyReleasedAt: nil,
            finalizingStateShownAt: nil,
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
            transcriptionResponseContentType: nil,
            transcriptionResponseHeadersReceivedMS: nil,
            transcriptionTransportFailureStage: nil,
            transcriptionNetworkErrorDomain: nil,
            transcriptionNetworkErrorCode: nil,
            transcriptionNetworkErrorCodeName: nil,
            transcriptionResponseBodyByteCount: nil,
            transcriptionResponseBodyUTF8Decodable: nil,
            transcriptionResponseBodyTrimmedCharacterCount: nil,
            transcriptionResponseContentLengthBytes: nil
        )
    }

    private func refreshDiskSpaceReadiness() {
        do {
            diskSpaceReadiness = try diskSpaceReadinessService.currentReadiness()
        } catch {
            logger.error("Failed to refresh disk readiness: \(error.localizedDescription, privacy: .public)")
            diskSpaceReadiness = nil
        }
    }

    private func releaseDiskReserveForRecordingIfNeeded() {
        guard let diskSpaceReadiness else {
            return
        }

        guard
            diskSpaceReadiness.reclaimableReserveBytes > 0,
            diskSpaceReadiness.freeBytes < diskSpaceReadinessService.policy.minimumRecordingBytes
        else {
            return
        }

        let releasedReserveLabel = diskSpaceReadiness.reservation.reservedSpaceLabel
        do {
            let updatedReadiness = try diskSpaceReadinessService.releaseReserve()
            self.diskSpaceReadiness = updatedReadiness
            recordDiagnosticEvent(
                "Released \(releasedReserveLabel) of reserved Head Canon cache space before recording because free disk space had fallen too low.",
                stage: .recordingStart,
                isFailure: false
            )
        } catch {
            logger.error("Failed to release disk reserve before recording: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func scheduleDiskReserveMaintenanceIfNeeded() {
        guard !workflowStatus.blocksNewDictation else {
            return
        }

        cancelDiskReserveMaintenance()

        let service = diskSpaceReadinessService
        let logger = logger
        diskReserveMaintenanceTask = Task { [weak self] in
            do {
                let updatedReadiness = try await Task.detached(priority: .utility) {
                    try service.ensureReserve()
                }.value
                guard let self else {
                    return
                }
                self.diskSpaceReadiness = updatedReadiness
                self.persistLiveState()
            } catch {
                logger.error("Failed to maintain disk reserve: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func cancelDiskReserveMaintenance() {
        diskReserveMaintenanceTask?.cancel()
        diskReserveMaintenanceTask = nil
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
        if status != .recording {
            cancelRecordingReleaseWatchdog()
            cancelRecordingDurationLimit()
        }
        workflowStatus = status
        lastErrorMessage = errorMessage
        statusOverlay.update(status: status, detail: overlayDetail(for: status, errorMessage: errorMessage))
        persistLiveState()
        if !status.blocksNewDictation {
            scheduleDiskReserveMaintenanceIfNeeded()
        }
    }

    private func startRecordingReleaseWatchdog() {
        cancelRecordingReleaseWatchdog()
        recordingReleaseWatchdogTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))

            while !Task.isCancelled {
                guard let self, self.workflowStatus == .recording else {
                    return
                }

                guard self.audioCaptureService.isRecording else {
                    self.failStaleRecordingState(
                        message: "Head Canon's audio capture stopped while the app still thought it was recording. The stuck recording state was cleared."
                    )
                    return
                }

                guard self.hotkeyStateProvider(self.preferences.hotkey) else {
                    self.recordDiagnosticEvent(
                        "Recording release watchdog observed the hotkey is no longer physically pressed. Finalizing automatically.",
                        stage: .recordingStop,
                        isFailure: false
                    )
                    self.handleHotkeyReleased(
                        HotkeyReleaseContext(
                            source: .recordingReleaseWatchdog,
                            observedAt: Date()
                        )
                    )
                    return
                }

                try? await Task.sleep(for: .milliseconds(75))
            }
        }
    }

    private func cancelRecordingReleaseWatchdog() {
        recordingReleaseWatchdogTask?.cancel()
        recordingReleaseWatchdogTask = nil
    }

    private func startRecordingDurationLimit() {
        cancelRecordingDurationLimit()
        let maximumRecordingDuration = maximumRecordingDuration
        recordingDurationLimitTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: maximumRecordingDuration)
            } catch {
                return
            }

            guard
                let self,
                self.workflowStatus == .recording,
                self.audioCaptureService.isRecording
            else {
                return
            }

            self.recordDiagnosticEvent(
                "Recording reached the \(Int(maximumRecordingDuration.timeInterval.rounded())) second safety limit. Finalizing automatically so the recording cannot get stuck.",
                stage: .recordingStop,
                isFailure: false
            )
            self.handleHotkeyReleased(
                HotkeyReleaseContext(
                    source: .recordingDurationLimit,
                    observedAt: Date()
                )
            )
        }
    }

    private func cancelRecordingDurationLimit() {
        recordingDurationLimitTask?.cancel()
        recordingDurationLimitTask = nil
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
        persistLiveState()
    }

    private func persistLiveState() {
        let record = makeLiveDiagnosticsRecord()
        let diagnosticsStore = self.diagnosticsStore
        let logger = self.logger
        let previousTask = liveDiagnosticsPersistTask

        liveDiagnosticsPersistTask = Task {
            await previousTask?.value
            do {
                try await diagnosticsStore.persistLiveState(record)
            } catch {
                logger.error("Failed to persist live diagnostics record: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func makeLiveDiagnosticsRecord() -> LiveDiagnosticsRecord {
        let events = diagnosticEvents.map { event in
            LiveDiagnosticEventRecord(
                timestamp: event.timestamp,
                summary: event.summary,
                stage: event.stage?.rawValue,
                isFailure: event.isFailure
            )
        }
        let timing = lastRecordingAttemptDiagnostics.map { report in
            LiveRecordingTimingRecord(
                hotkeyPressedAt: report.hotkeyPressedAt,
                recordingStartedAt: report.recordingStartedAt,
                hotkeyReleasedAt: report.hotkeyReleasedAt,
                finalizingStateShownAt: report.finalizingStateShownAt,
                recordingFinalizedAt: report.recordingFinalizedAt,
                transcriptionRequestStartedAt: report.transcriptionRequestStartedAt,
                transcriptionResponseCompletedAt: report.transcriptionResponseCompletedAt,
                insertionCompletedAt: report.insertionCompletedAt,
                stopTrigger: report.stopTrigger?.rawValue
            )
        }

        return LiveDiagnosticsRecord(
            schemaVersion: LiveDiagnosticsRecord.schemaVersion,
            updatedAt: Date(),
            sessionID: diagnosticsSessionID,
            currentAttemptID: currentAttemptID,
            workflowStatus: workflowStatus.rawValue,
            workflowStatusTitle: workflowStatus.title,
            isReady: isReady,
            diskReadinessStatus: diskSpaceReadiness?.status.title,
            diskFreeSpace: diskSpaceReadiness?.freeSpaceLabel,
            diskReserveStatus: diskSpaceReadiness?.reservation.status.title,
            diskReservedSpace: diskSpaceReadiness?.reservation.reservedSpaceLabel,
            browserCompanionStatus: browserCompanionStatus.statusTitle,
            browserCompanionDetail: browserCompanionStatus.statusDetail,
            browserCompanionInstallations: browserCompanionStatus.installations.map { installation in
                LiveBrowserCompanionInstallationRecord(
                    browser: installation.browser.rawValue,
                    installed: installation.isInstalled,
                    hostScriptReachable: installation.hostScriptReachable,
                    allowedExtensionIDs: installation.allowedExtensionIDs,
                    nativeHostManifestPath: installation.nativeHostManifestPath
                )
            },
            audioCaptureIsRecording: audioCaptureService.isRecording,
            hotkeyDisplayString: preferences.hotkey.displayString,
            hotkeyPhysicallyPressed: hotkeyStateProvider(preferences.hotkey),
            activeTranscriptionAttemptID: activeTranscriptionAttemptID,
            lastFailureStage: lastFailureStage?.rawValue,
            lastTruthState: lastAttemptTruthState?.rawValue,
            lastErrorMessage: lastErrorMessage,
            lastEvent: events.first,
            recentEvents: events,
            recordingTiming: timing
        )
    }

    private func persistCurrentAttempt(
        terminalState: DictationAttemptTerminalState,
        truthState: DictationAttemptTruthState,
        failureStage: DiagnosticFailureStage? = nil,
        failureMessage: String? = nil
    ) {
        lastAttemptTruthState = truthState
        guard let record = makePersistentAttemptRecord(
            terminalState: terminalState,
            truthState: truthState,
            failureStage: failureStage,
            failureMessage: failureMessage
        ) else {
            return
        }

        persistLiveState()

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

    private enum BrowserReportPhase {
        case captured
        case validated
    }

    private func makePersistentAttemptRecord(
        terminalState: DictationAttemptTerminalState,
        truthState: DictationAttemptTruthState,
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
        let clipboardRecovery = lastClipboardRecovery

        return DictationAttemptRecord(
            schemaVersion: DictationAttemptRecord.schemaVersion,
            attemptID: attemptID,
            sessionID: diagnosticsSessionID,
            completedAt: Date(),
            terminalState: terminalState,
            truthState: truthState,
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
                finalizingStateShownAt: metrics.finalizingStateShownAt,
                recordingFinalizedAt: metrics.recordingFinalizedAt,
                transcriptionRequestStartedAt: metrics.transcriptionRequestStartedAt,
                transcriptionResponseCompletedAt: metrics.transcriptionResponseCompletedAt,
                insertionCompletedAt: metrics.insertionCompletedAt,
                stopTrigger: metrics.stopTrigger?.rawValue,
                pressToRecordingStartDurationMS: durationMilliseconds(metrics.pressToRecordingStartDuration),
                releaseToFinalizingStateDurationMS: durationMilliseconds(metrics.releaseToFinalizingStateDuration),
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
                responseContentType: metrics.transcriptionResponseContentType,
                responseHeadersReceivedMS: metrics.transcriptionResponseHeadersReceivedMS,
                transportFailureStage: metrics.transcriptionTransportFailureStage,
                networkErrorDomain: metrics.transcriptionNetworkErrorDomain,
                networkErrorCode: metrics.transcriptionNetworkErrorCode,
                networkErrorCodeName: metrics.transcriptionNetworkErrorCodeName,
                responseBodyByteCount: metrics.transcriptionResponseBodyByteCount,
                responseBodyUTF8Decodable: metrics.transcriptionResponseBodyUTF8Decodable,
                responseBodyTrimmedCharacterCount: metrics.transcriptionResponseBodyTrimmedCharacterCount,
                responseContentLengthBytes: metrics.transcriptionResponseContentLengthBytes
            ),
            releaseTimeInsertion: releaseTimeInsertionReport.map { report in
                DictationAttemptInsertionRecord(
                    observationLabel: report.observationLabel,
                    applicationName: report.capabilities.applicationName,
                    bundleIdentifier: report.capabilities.bundleIdentifier,
                    browserContext: enrichedBrowserContext(
                        for: report,
                        attemptID: attemptID,
                        phase: .captured
                    ),
                    target: report.capabilities.targetLabel,
                    contextKind: report.capabilities.contextKind.rawValue,
                    capabilityProfile: report.capabilities.capabilityProfile.rawValue,
                    chosenStrategy: report.chosenStrategy.rawValue,
                    appliedStrategy: report.appliedStrategy?.rawValue,
                    strategyReason: report.strategyReason,
                    predictedFailureClass: report.predictedFailureClass?.rawValue,
                    verificationOutcome: report.verificationOutcome?.rawValue,
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
                    browserContext: enrichedBrowserContext(
                        for: report,
                        attemptID: attemptID,
                        phase: .validated
                    ),
                    target: report.capabilities.targetLabel,
                    contextKind: report.capabilities.contextKind.rawValue,
                    capabilityProfile: report.capabilities.capabilityProfile.rawValue,
                    chosenStrategy: report.chosenStrategy.rawValue,
                    appliedStrategy: report.appliedStrategy?.rawValue,
                    strategyReason: report.strategyReason,
                    predictedFailureClass: report.predictedFailureClass?.rawValue,
                    verificationOutcome: report.verificationOutcome?.rawValue,
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
            },
            clipboardRecovery: clipboardRecovery.map { recovery in
                DictationAttemptClipboardRecoveryRecord(
                    transcriptCopied: recovery.transcriptCopied,
                    reason: recovery.reason.rawValue
                )
            }
        )
    }

    private func enrichedBrowserContext(
        for report: InsertionAttemptReport,
        attemptID: UUID,
        phase: BrowserReportPhase
    ) -> BrowserTargetMetadata? {
        guard let browserMetadata = report.capabilities.browserMetadata else {
            return nil
        }

        let installation = browserCompanionStatus.installations.first { installation in
            installation.browser == browserMetadata.browser
        }

        return BrowserTargetMetadata(
            browser: browserMetadata.browser,
            targetClass: browserMetadata.targetClass,
            editorFamily: browserMetadata.editorFamily,
            verificationMode: browserMetadata.verificationMode,
            pageOrigin: browserMetadata.pageOrigin,
            pageTitle: browserMetadata.pageTitle,
            framePath: browserMetadata.framePath,
            frameIdentifier: browserMetadata.frameIdentifier,
            targetFingerprint: browserMetadata.targetFingerprint,
            operationID: attemptID,
            focusCapturedAt: phase == .captured ? report.observedAt : browserMetadata.focusCapturedAt,
            focusValidatedAt: phase == .validated ? report.observedAt : browserMetadata.focusValidatedAt,
            protocolVersion: installation?.isInstalled == true ? browserCompanionStatus.protocolVersion : nil,
            extensionVersion: nil
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

    private func transcriptionFailureContext(from error: TranscriptionBackendError) -> TranscriptionFailureContext? {
        switch error {
        case .networkUnavailable(let context):
            context
        case .unexpectedResponse(_, let context):
            context
        case .invalidResponse(let context):
            context
        case .emptyTranscript(let context):
            context
        case .invalidAPIKey, .serializationFailure, .timeout, .notImplemented:
            nil
        }
    }

    private func truthState(for report: InsertionAttemptReport?) -> DictationAttemptTruthState {
        guard let report else {
            return .unverifiedInsert
        }

        guard report.appliedStrategy != nil, let verificationOutcome = report.verificationOutcome else {
            return .unverifiedInsert
        }

        switch verificationOutcome {
        case .verified:
            return .verifiedInsert
        case .unverified:
            return .unverifiedInsert
        }
    }

    private func truthState(for error: TranscriptionBackendError) -> DictationAttemptTruthState {
        switch error {
        case .invalidAPIKey:
            .setupBlocked
        case .networkUnavailable:
            .transcriptionTransportFailure
        case .emptyTranscript:
            .noSpeechDetected
        case .unexpectedResponse, .invalidResponse, .serializationFailure, .notImplemented:
            .transcriptionFailed
        case .timeout:
            .transcriptionTimedOut
        }
    }

    private func truthState(forInsertionError error: Error) -> DictationAttemptTruthState {
        guard let insertionError = error as? TextInsertionError else {
            return .insertionFailed
        }

        switch insertionError {
        case .focusChanged:
            return DictationAttemptTruthState.focusChanged
        case .accessibilityPermissionRequired:
            return DictationAttemptTruthState.setupBlocked
        case .secureTarget, .placeholderCleanupRequired:
            return DictationAttemptTruthState.safetyBlock
        case .unsupportedTarget, .pasteFallbackDisabled:
            return DictationAttemptTruthState.unsupportedTarget
        case .focusUnavailable, .accessibilityAPIError, .pasteFailed, .pasteDeliveryUnconfirmed:
            return DictationAttemptTruthState.insertionFailed
        }
    }

    private func userFacingRecordingFailureMessage(for error: Error) -> String {
        if isDiskSpaceError(error) {
            return diskSpaceReadiness?.blockingMessage
                ?? "Head Canon needs at least \(diskSpaceReadinessService.policy.minimumRecordingLabel) free to record safely. Free up disk space and try again."
        }

        return error.localizedDescription
    }

    private func actionableRecordingFailureMessage(for error: Error) -> String {
        let userFacingMessage = userFacingRecordingFailureMessage(for: error)
        let underlyingMessage = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !underlyingMessage.isEmpty,
            underlyingMessage.caseInsensitiveCompare(userFacingMessage) != .orderedSame
        else {
            return userFacingMessage
        }

        return "\(userFacingMessage) Underlying recording error: \(underlyingMessage)"
    }

    private func isDiskSpaceError(_ error: Error) -> Bool {
        if let audioCaptureError = error as? AudioCaptureError,
           case .finalizationFailed(let message) = audioCaptureError
        {
            return isDiskSpaceErrorMessage(message)
        }

        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError {
            return true
        }

        return isDiskSpaceErrorMessage(error.localizedDescription)
    }

    private func isDiskSpaceErrorMessage(_ message: String) -> Bool {
        let normalizedMessage = message.lowercased()
        return normalizedMessage.contains("disk full")
            || normalizedMessage.contains("out of space")
            || normalizedMessage.contains("no space left")
    }

    private func insertionSuccessMessage(
        for truthState: DictationAttemptTruthState,
        recoveryAttempt: Bool = false
    ) -> String {
        switch truthState {
        case .unverifiedInsert:
            return recoveryAttempt
                ? "Recovered the last transcript into the current target context, but Head Canon could not verify the resulting field contents."
                : "Head Canon pasted into the intended target context, but could not verify the resulting field contents."
        default:
            return recoveryAttempt
                ? "Recovered the last transcript into the current target context and verified the result."
                : "Transcript inserted and verified in the intended target context."
        }
    }

    private func shouldRetryTranscription(after error: TranscriptionBackendError, attempt: Int) -> Bool {
        guard attempt < maxTransientTranscriptionAttempts else {
            return false
        }

        switch error {
        case .networkUnavailable(let context):
            return shouldRetryNetworkTranscriptionFailure(context)
        case .invalidResponse(let context):
            return shouldRetryEmptyTranscriptionResponse(context)
        default:
            return false
        }
    }

    private func shouldRetryNetworkTranscriptionFailure(_ context: TranscriptionFailureContext?) -> Bool {
        if let httpStatusCode = context?.httpStatusCode {
            switch httpStatusCode {
            case 408, 409, 425, 429:
                return true
            case 500 ... 599:
                return true
            default:
                break
            }
        }

        guard context?.networkErrorDomain == NSURLErrorDomain else {
            return false
        }

        return switch context?.networkErrorCode {
        case URLError.timedOut.rawValue,
            URLError.networkConnectionLost.rawValue,
            URLError.cannotConnectToHost.rawValue:
            true
        default:
            false
        }
    }

    private func shouldRetryEmptyTranscriptionResponse(_ context: TranscriptionFailureContext?) -> Bool {
        guard
            context?.httpStatusCode == 200,
            context?.transportFailureStage == .readingResponseBody
        else {
            return false
        }

        let contentType = context?.contentType?.lowercased() ?? ""
        return contentType.isEmpty || contentType.contains("text/plain")
    }

    private func recordingIsLongEnoughForTranscription(_ input: BoundedAudioInput) -> Bool {
        guard let duration = input.duration else {
            return true
        }

        return duration >= minimumTranscriptionDuration
    }

    private func retryDiagnosticSummary(after error: TranscriptionBackendError, attempt: Int) -> String {
        switch error {
        case .invalidResponse:
            "Retrying transcription after an empty transcription response. Attempt \(attempt) of \(maxTransientTranscriptionAttempts)."
        default:
            "Retrying transcription after a transient transport failure. Attempt \(attempt) of \(maxTransientTranscriptionAttempts)."
        }
    }

    private func transcribeWithRetry(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        var attempt = 1

        while true {
            do {
                return try await transcribeWithTimeout(input, apiKey: apiKey)
            } catch let error as TranscriptionBackendError {
                guard shouldRetryTranscription(after: error, attempt: attempt) else {
                    throw error
                }

                attempt += 1
                recordDiagnosticEvent(
                    retryDiagnosticSummary(after: error, attempt: attempt),
                    stage: .transcription,
                    isFailure: false
                )
            }
        }
    }

    private func transcriptionTimeout(for input: BoundedAudioInput) -> Duration {
        let baseSeconds = transcriptionTimeout.timeInterval
        guard baseSeconds >= 1, let duration = input.duration else {
            return transcriptionTimeout
        }

        let dynamicSeconds = min(75, max(baseSeconds, duration * 2 + 15))
        return .milliseconds(Int((dynamicSeconds * 1000).rounded()))
    }

    private func transcribeWithTimeout(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        let backend = transcriptionBackend
        let timeout = transcriptionTimeout(for: input)

        let transcriptionTask = Task { @MainActor [backend] in
            try await backend.transcribe(input, apiKey: apiKey)
        }

        return try await withThrowingTaskGroup(of: TranscriptionResult.self) { group in
            group.addTask {
                try await transcriptionTask.value
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw TranscriptionBackendError.timeout(timeout.timeInterval)
            }

            defer {
                group.cancelAll()
                transcriptionTask.cancel()
            }

            guard let result = try await group.next() else {
                throw CancellationError()
            }

            return result
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
        case .finalizingRecording:
            return "Finalizing your recording."
        case .startingTranscription:
            return "Starting the transcription request."
        case .transcribing:
            return "Transcribing your recording."
        case .inserted:
            if lastAttemptTruthState == .unverifiedInsert {
                return DictationAttemptTruthState.unverifiedInsert.detail
            }
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
