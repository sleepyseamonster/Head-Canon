import Foundation

enum DictationAttemptTerminalState: String, Codable, Equatable {
    case inserted
    case failed
    case timedOut
    case canceled
}

struct DictationAttemptBundleRecord: Codable, Equatable {
    let path: String
    let identifier: String
    let isInstalledBundle: Bool
}

struct DictationAttemptTimingRecord: Codable, Equatable {
    let hotkeyPressedAt: Date?
    let recordingStartedAt: Date?
    let hotkeyReleasedAt: Date?
    let finalizingStateShownAt: Date?
    let recordingFinalizedAt: Date?
    let transcriptionRequestStartedAt: Date?
    let transcriptionResponseCompletedAt: Date?
    let insertionCompletedAt: Date?
    let stopTrigger: String?
    let pressToRecordingStartDurationMS: Int?
    let releaseToFinalizingStateDurationMS: Int?
    let releaseToFinalizedDurationMS: Int?
    let finalizedToRequestStartDurationMS: Int?
    let requestToResponseDurationMS: Int?
    let responseToInsertionDurationMS: Int?
    let releaseToInsertionDurationMS: Int?
}

struct DictationAttemptAudioRecord: Codable, Equatable {
    let clipDurationMS: Int?
    let recordedFileSizeBytes: Int64?
}

struct DictationAttemptTranscriptRecord: Codable, Equatable {
    let characterCount: Int?
    let wordCount: Int?
}

struct DictationAttemptBackendRecord: Codable, Equatable {
    let identifier: String?
    let requestMode: String?
    let fellBackFromStreaming: Bool?
    let httpStatusCode: Int?
    let requestID: String?
    let openAIProcessingMS: Int?
    let responseContentType: String?
    let responseHeadersReceivedMS: Int?
    let transportFailureStage: String?
    let networkErrorDomain: String?
    let networkErrorCode: Int?
    let networkErrorCodeName: String?
}

struct DictationAttemptInsertionRecord: Codable, Equatable {
    let observationLabel: String
    let applicationName: String
    let bundleIdentifier: String?
    let target: String
    let contextKind: String
    let capabilityProfile: String
    let chosenStrategy: String
    let appliedStrategy: String?
    let strategyReason: String
    let predictedFailureClass: String?
    let placeholderPresent: Bool
    let placeholderLikelyActive: Bool
    let placeholderAmbiguousValueDetected: Bool
    let placeholderHandlingOutcome: String?
    let valueReadable: Bool
    let valueSettable: Bool
    let selectedTextRangeReadable: Bool
    let selectedTextReadable: Bool
    let editable: Bool
    let secure: Bool
    let pasteCompatible: Bool
    let directInsertCompatible: Bool
}

struct DictationAttemptFailureRecord: Codable, Equatable {
    let stage: String
    let message: String
}

struct DictationAttemptClipboardRecoveryRecord: Codable, Equatable {
    let transcriptCopied: Bool
    let reason: String
}

struct DictationAttemptRecord: Codable, Equatable {
    static let schemaVersion = 2

    let schemaVersion: Int
    let attemptID: UUID
    let sessionID: UUID
    let completedAt: Date
    let terminalState: DictationAttemptTerminalState
    let hotkeyDisplayString: String
    let bundle: DictationAttemptBundleRecord
    let timing: DictationAttemptTimingRecord
    let audio: DictationAttemptAudioRecord
    let transcript: DictationAttemptTranscriptRecord
    let backend: DictationAttemptBackendRecord
    let releaseTimeInsertion: DictationAttemptInsertionRecord?
    let insertion: DictationAttemptInsertionRecord?
    let failure: DictationAttemptFailureRecord?
    let clipboardRecovery: DictationAttemptClipboardRecoveryRecord?
}
