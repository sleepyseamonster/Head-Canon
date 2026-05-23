import Foundation

enum DictationAttemptTerminalState: String, Codable, Equatable {
    case inserted
    case failed
    case timedOut
    case canceled
}

enum DictationAttemptTruthState: String, Codable, Equatable, Identifiable {
    case verifiedInsert
    case unverifiedInsert
    case setupBlocked
    case systemReadinessBlocked
    case recordingFailed
    case safetyBlock
    case focusChanged
    case unsupportedTarget
    case transcriptionTransportFailure
    case transcriptionTimedOut
    case transcriptionCanceled
    case transcriptionFailed
    case insertionFailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .verifiedInsert:
            "Verified Insert"
        case .unverifiedInsert:
            "Unverified Insert"
        case .setupBlocked:
            "Setup Blocked"
        case .systemReadinessBlocked:
            "System Readiness Blocked"
        case .recordingFailed:
            "Recording Failed"
        case .safetyBlock:
            "Safety Block"
        case .focusChanged:
            "Focus Changed"
        case .unsupportedTarget:
            "Unsupported Target"
        case .transcriptionTransportFailure:
            "Transcription Transport Failure"
        case .transcriptionTimedOut:
            "Transcription Timed Out"
        case .transcriptionCanceled:
            "Transcription Canceled"
        case .transcriptionFailed:
            "Transcription Failed"
        case .insertionFailed:
            "Insertion Failed"
        }
    }

    var detail: String {
        switch self {
        case .verifiedInsert:
            "Head Canon inserted the transcript and verified the target field changed."
        case .unverifiedInsert:
            "Head Canon pasted into the active app but could not verify the field contents. If the text is missing, use Paste or Copy Last Transcript."
        case .setupBlocked:
            "Head Canon could not complete dictation because setup or permissions were still blocking the attempt."
        case .systemReadinessBlocked:
            "Head Canon blocked the attempt before recording because a required system readiness check was not satisfied."
        case .recordingFailed:
            "Head Canon could not complete the audio recording step."
        case .safetyBlock:
            "Head Canon preserved the transcript instead of risking unsafe insertion."
        case .focusChanged:
            "The focused target changed before insertion could complete safely."
        case .unsupportedTarget:
            "The active target does not support the current insertion path."
        case .transcriptionTransportFailure:
            "Head Canon could not reach the transcription service reliably enough to finish the request."
        case .transcriptionTimedOut:
            "Head Canon stopped waiting for the transcription request before it completed."
        case .transcriptionCanceled:
            "Head Canon canceled the in-flight transcription request."
        case .transcriptionFailed:
            "Head Canon received a transcription failure that was not a clean transport timeout."
        case .insertionFailed:
            "Head Canon transcribed the audio but could not complete insertion."
        }
    }
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
    let responseBodyByteCount: Int?
    let responseBodyUTF8Decodable: Bool?
    let responseBodyTrimmedCharacterCount: Int?
    let responseContentLengthBytes: Int?

    init(
        identifier: String?,
        requestMode: String?,
        fellBackFromStreaming: Bool?,
        httpStatusCode: Int?,
        requestID: String?,
        openAIProcessingMS: Int?,
        responseContentType: String?,
        responseHeadersReceivedMS: Int?,
        transportFailureStage: String?,
        networkErrorDomain: String?,
        networkErrorCode: Int?,
        networkErrorCodeName: String?,
        responseBodyByteCount: Int? = nil,
        responseBodyUTF8Decodable: Bool? = nil,
        responseBodyTrimmedCharacterCount: Int? = nil,
        responseContentLengthBytes: Int? = nil
    ) {
        self.identifier = identifier
        self.requestMode = requestMode
        self.fellBackFromStreaming = fellBackFromStreaming
        self.httpStatusCode = httpStatusCode
        self.requestID = requestID
        self.openAIProcessingMS = openAIProcessingMS
        self.responseContentType = responseContentType
        self.responseHeadersReceivedMS = responseHeadersReceivedMS
        self.transportFailureStage = transportFailureStage
        self.networkErrorDomain = networkErrorDomain
        self.networkErrorCode = networkErrorCode
        self.networkErrorCodeName = networkErrorCodeName
        self.responseBodyByteCount = responseBodyByteCount
        self.responseBodyUTF8Decodable = responseBodyUTF8Decodable
        self.responseBodyTrimmedCharacterCount = responseBodyTrimmedCharacterCount
        self.responseContentLengthBytes = responseContentLengthBytes
    }
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
    let verificationOutcome: String?
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
    static let schemaVersion = 3

    let schemaVersion: Int
    let attemptID: UUID
    let sessionID: UUID
    let completedAt: Date
    let terminalState: DictationAttemptTerminalState
    let truthState: DictationAttemptTruthState
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

    init(
        schemaVersion: Int,
        attemptID: UUID,
        sessionID: UUID,
        completedAt: Date,
        terminalState: DictationAttemptTerminalState,
        truthState: DictationAttemptTruthState,
        hotkeyDisplayString: String,
        bundle: DictationAttemptBundleRecord,
        timing: DictationAttemptTimingRecord,
        audio: DictationAttemptAudioRecord,
        transcript: DictationAttemptTranscriptRecord,
        backend: DictationAttemptBackendRecord,
        releaseTimeInsertion: DictationAttemptInsertionRecord?,
        insertion: DictationAttemptInsertionRecord?,
        failure: DictationAttemptFailureRecord?,
        clipboardRecovery: DictationAttemptClipboardRecoveryRecord?
    ) {
        self.schemaVersion = schemaVersion
        self.attemptID = attemptID
        self.sessionID = sessionID
        self.completedAt = completedAt
        self.terminalState = terminalState
        self.truthState = truthState
        self.hotkeyDisplayString = hotkeyDisplayString
        self.bundle = bundle
        self.timing = timing
        self.audio = audio
        self.transcript = transcript
        self.backend = backend
        self.releaseTimeInsertion = releaseTimeInsertion
        self.insertion = insertion
        self.failure = failure
        self.clipboardRecovery = clipboardRecovery
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        let attemptID = try container.decode(UUID.self, forKey: .attemptID)
        let sessionID = try container.decode(UUID.self, forKey: .sessionID)
        let completedAt = try container.decode(Date.self, forKey: .completedAt)
        let terminalState = try container.decode(DictationAttemptTerminalState.self, forKey: .terminalState)
        let hotkeyDisplayString = try container.decode(String.self, forKey: .hotkeyDisplayString)
        let bundle = try container.decode(DictationAttemptBundleRecord.self, forKey: .bundle)
        let timing = try container.decode(DictationAttemptTimingRecord.self, forKey: .timing)
        let audio = try container.decode(DictationAttemptAudioRecord.self, forKey: .audio)
        let transcript = try container.decode(DictationAttemptTranscriptRecord.self, forKey: .transcript)
        let backend = try container.decode(DictationAttemptBackendRecord.self, forKey: .backend)
        let releaseTimeInsertion = try container.decodeIfPresent(
            DictationAttemptInsertionRecord.self,
            forKey: .releaseTimeInsertion
        )
        let insertion = try container.decodeIfPresent(DictationAttemptInsertionRecord.self, forKey: .insertion)
        let failure = try container.decodeIfPresent(DictationAttemptFailureRecord.self, forKey: .failure)
        let clipboardRecovery = try container.decodeIfPresent(
            DictationAttemptClipboardRecoveryRecord.self,
            forKey: .clipboardRecovery
        )
        let truthState = try container.decodeIfPresent(DictationAttemptTruthState.self, forKey: .truthState)
            ?? Self.inferLegacyTruthState(
                terminalState: terminalState,
                insertion: insertion ?? releaseTimeInsertion,
                failure: failure,
                backend: backend
            )

        self.init(
            schemaVersion: schemaVersion,
            attemptID: attemptID,
            sessionID: sessionID,
            completedAt: completedAt,
            terminalState: terminalState,
            truthState: truthState,
            hotkeyDisplayString: hotkeyDisplayString,
            bundle: bundle,
            timing: timing,
            audio: audio,
            transcript: transcript,
            backend: backend,
            releaseTimeInsertion: releaseTimeInsertion,
            insertion: insertion,
            failure: failure,
            clipboardRecovery: clipboardRecovery
        )
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case attemptID
        case sessionID
        case completedAt
        case terminalState
        case truthState
        case hotkeyDisplayString
        case bundle
        case timing
        case audio
        case transcript
        case backend
        case releaseTimeInsertion
        case insertion
        case failure
        case clipboardRecovery
    }

    private static func inferLegacyTruthState(
        terminalState: DictationAttemptTerminalState,
        insertion: DictationAttemptInsertionRecord?,
        failure: DictationAttemptFailureRecord?,
        backend: DictationAttemptBackendRecord
    ) -> DictationAttemptTruthState {
        switch terminalState {
        case .inserted:
            if insertion?.verificationOutcome == InsertionVerificationOutcome.unverified.rawValue {
                return .unverifiedInsert
            }
            return .verifiedInsert
        case .timedOut:
            return .transcriptionTimedOut
        case .canceled:
            return .transcriptionCanceled
        case .failed:
            break
        }

        guard let failure else {
            return .insertionFailed
        }

        switch failure.stage {
        case "permissionReadiness":
            return .setupBlocked
        case "recordingStart", "recordingStop":
            return .recordingFailed
        case "transcription":
            if backend.transportFailureStage != nil || backend.networkErrorDomain != nil || backend.networkErrorCode != nil {
                return .transcriptionTransportFailure
            }
            return .transcriptionFailed
        case "insertion":
            return inferLegacyInsertionFailureTruthState(message: failure.message)
        default:
            return .insertionFailed
        }
    }

    private static func inferLegacyInsertionFailureTruthState(message: String) -> DictationAttemptTruthState {
        let normalizedMessage = message.lowercased()

        if normalizedMessage.contains("focus") && normalizedMessage.contains("changed") {
            return .focusChanged
        }

        if normalizedMessage.contains("secure")
            || normalizedMessage.contains("unsafe")
            || normalizedMessage.contains("placeholder")
        {
            return .safetyBlock
        }

        if normalizedMessage.contains("unsupported")
            || normalizedMessage.contains("paste fallback")
        {
            return .unsupportedTarget
        }

        if normalizedMessage.contains("accessibility") && normalizedMessage.contains("permission") {
            return .setupBlocked
        }

        return .insertionFailed
    }
}
