import Foundation

@MainActor
struct OpenAIBoundedTranscriptionBackend: TranscriptionBackend {
    let id = "openai.gpt-4o-transcribe"

    private let model = "gpt-4o-transcribe"
    private let session: URLSession = .shared

    func validateConfiguration(apiKey: String) async throws {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models/\(model)")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let response: URLResponse

        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw TranscriptionBackendError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionBackendError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 401, 403:
            throw TranscriptionBackendError.invalidAPIKey
        default:
            throw TranscriptionBackendError.unexpectedResponse(httpResponse.statusCode)
        }
    }

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        let audioData: Data

        do {
            audioData = try Data(contentsOf: input.fileURL)
        } catch {
            throw TranscriptionBackendError.invalidResponse
        }

        let boundary = "VoiceFlowBoundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(audioData: audioData, input: input, boundary: boundary)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TranscriptionBackendError.networkUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionBackendError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw TranscriptionBackendError.invalidAPIKey
        default:
            throw TranscriptionBackendError.unexpectedResponse(httpResponse.statusCode)
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let text = json["text"] as? String
        else {
            throw TranscriptionBackendError.invalidResponse
        }

        return TranscriptionResult(
            text: text,
            backendID: id,
            duration: input.duration
        )
    }

    private func multipartBody(audioData: Data, input: BoundedAudioInput, boundary: String) -> Data {
        var body = Data()

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.appendUTF8("\(model)\r\n")

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.appendUTF8("json\r\n")

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"file\"; filename=\"\(input.fileURL.lastPathComponent)\"\r\n")
        body.appendUTF8("Content-Type: \(input.mimeType)\r\n\r\n")
        body.append(audioData)
        body.appendUTF8("\r\n")

        body.appendUTF8("--\(boundary)--\r\n")

        return body
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        append(Data(string.utf8))
    }
}
