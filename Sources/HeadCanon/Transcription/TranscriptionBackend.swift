import Foundation

struct BoundedAudioInput {
    let fileURL: URL
    let mimeType: String
    let duration: TimeInterval?
}

enum TranscriptionRequestMode: String, Equatable {
    case streamedCompletedRecording
    case standardCompletedRecording

    var title: String {
        switch self {
        case .streamedCompletedRecording:
            "Streamed Completed Recording"
        case .standardCompletedRecording:
            "Standard Completed Recording"
        }
    }
}

enum TranscriptionTransportFailureStage: String, Equatable {
    case awaitingResponseHeaders
    case readingResponseBody
}

struct TranscriptionResponseMetadata: Equatable {
    let requestMode: TranscriptionRequestMode
    let fellBackFromStreaming: Bool
    let httpStatusCode: Int
    let requestID: String?
    let openAIProcessingMS: Int?
    let contentType: String?
    let responseHeadersReceivedMS: Int?
}

struct TranscriptionFailureContext: Equatable {
    let requestMode: TranscriptionRequestMode
    let fellBackFromStreaming: Bool
    let httpStatusCode: Int?
    let requestID: String?
    let openAIProcessingMS: Int?
    let contentType: String?
    let responseHeadersReceivedMS: Int?
    let transportFailureStage: TranscriptionTransportFailureStage?
    let networkErrorDomain: String?
    let networkErrorCode: Int?
    let networkErrorCodeName: String?
}

struct TranscriptionResult: Equatable {
    let text: String
    let backendID: String
    let duration: TimeInterval?
    let responseMetadata: TranscriptionResponseMetadata?
}

enum TranscriptionBackendError: LocalizedError {
    case invalidAPIKey
    case networkUnavailable(TranscriptionFailureContext? = nil)
    case unexpectedResponse(Int, TranscriptionFailureContext? = nil)
    case invalidResponse(TranscriptionFailureContext? = nil)
    case serializationFailure
    case timeout(TimeInterval)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            "The configured API key is invalid."
        case .networkUnavailable:
            "Head Canon could not reach the transcription service."
        case .unexpectedResponse(let statusCode, _):
            "The transcription service returned status code \(statusCode)."
        case .invalidResponse:
            "The transcription response could not be decoded."
        case .serializationFailure:
            "Head Canon could not build the transcription request."
        case .timeout(let seconds):
            if seconds < 1 {
                "Head Canon stopped waiting for transcription after \(String(format: "%.2f", seconds)) seconds."
            } else {
                "Head Canon stopped waiting for transcription after \(Int(seconds.rounded())) seconds."
            }
        case .notImplemented:
            "The transcription backend is not implemented yet."
        }
    }
}

@MainActor
protocol TranscriptionBackend {
    var id: String { get }
    func validateConfiguration(apiKey: String) async throws
    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult
}
