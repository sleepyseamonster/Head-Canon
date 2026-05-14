import Foundation

struct BoundedAudioInput {
    let fileURL: URL
    let mimeType: String
    let duration: TimeInterval?
}

struct TranscriptionResult: Equatable {
    let text: String
    let backendID: String
    let duration: TimeInterval?
}

enum TranscriptionBackendError: LocalizedError {
    case invalidAPIKey
    case networkUnavailable
    case unexpectedResponse(Int)
    case invalidResponse
    case serializationFailure
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            "The configured API key is invalid."
        case .networkUnavailable:
            "Voice Flow could not reach the transcription service."
        case .unexpectedResponse(let statusCode):
            "The transcription service returned status code \(statusCode)."
        case .invalidResponse:
            "The transcription response could not be decoded."
        case .serializationFailure:
            "Voice Flow could not build the transcription request."
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
