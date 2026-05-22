import Foundation

struct LiveDiagnosticEventRecord: Codable, Equatable, Sendable {
    let timestamp: Date
    let summary: String
    let stage: String?
    let isFailure: Bool
}

struct LiveRecordingTimingRecord: Codable, Equatable, Sendable {
    let hotkeyPressedAt: Date?
    let recordingStartedAt: Date?
    let hotkeyReleasedAt: Date?
    let finalizingStateShownAt: Date?
    let recordingFinalizedAt: Date?
    let transcriptionRequestStartedAt: Date?
    let transcriptionResponseCompletedAt: Date?
    let insertionCompletedAt: Date?
    let stopTrigger: String?
}

struct LiveDiagnosticsRecord: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    let schemaVersion: Int
    let updatedAt: Date
    let sessionID: UUID
    let currentAttemptID: UUID?
    let workflowStatus: String
    let workflowStatusTitle: String
    let isReady: Bool
    let audioCaptureIsRecording: Bool
    let hotkeyDisplayString: String
    let hotkeyPhysicallyPressed: Bool
    let activeTranscriptionAttemptID: UUID?
    let lastFailureStage: String?
    let lastTruthState: String?
    let lastErrorMessage: String?
    let lastEvent: LiveDiagnosticEventRecord?
    let recentEvents: [LiveDiagnosticEventRecord]
    let recordingTiming: LiveRecordingTimingRecord?
}
