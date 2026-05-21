import Foundation

struct OpenAIBoundedTranscriptionBackend: TranscriptionBackend {
    private let modelProvider: () -> OpenAITranscriptionModel
    private let session: URLSession

    init(
        modelProvider: @escaping () -> OpenAITranscriptionModel = { .gpt4oMiniTranscribe },
        session: URLSession? = nil
    ) {
        self.modelProvider = modelProvider
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 45
            self.session = URLSession(configuration: configuration)
        }
    }

    var id: String {
        "openai.\(modelProvider().rawValue)"
    }

    func validateConfiguration(apiKey: String) async throws {
        let model = modelProvider().rawValue
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
        case 408, 409, 425, 429:
            throw TranscriptionBackendError.networkUnavailable
        case 500 ... 599:
            throw TranscriptionBackendError.networkUnavailable
        default:
            throw TranscriptionBackendError.unexpectedResponse(httpResponse.statusCode)
        }
    }

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        let model = modelProvider().rawValue
        let response = try await standardTranscriptionResponse(
            input: input,
            apiKey: apiKey,
            model: model,
            fellBackFromStreaming: false
        )
        return TranscriptionResult(
            text: response.text,
            backendID: id,
            duration: input.duration,
            responseMetadata: response.metadata
        )
    }

    private func streamedTranscriptionResponse(
        input: BoundedAudioInput,
        apiKey: String,
        model: String
    ) async throws -> ParsedTranscriptionResponse {
        let request = try await Self.makeTranscriptionRequest(
            input: input,
            apiKey: apiKey,
            model: model,
            responseFormat: "json",
            stream: true
        )

        let bytes: URLSession.AsyncBytes
        let response: URLResponse

        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch {
            throw TranscriptionBackendError.networkUnavailable
        }

        let metadata = try Self.responseMetadata(
            from: response,
            requestMode: .streamedCompletedRecording,
            fellBackFromStreaming: false
        )
        let text = try await Self.parseStreamingTranscriptionResponse(from: bytes)
        guard !text.isEmpty else {
            throw TranscriptionBackendError.invalidResponse
        }
        return ParsedTranscriptionResponse(text: text, metadata: metadata)
    }

    private func standardTranscriptionResponse(
        input: BoundedAudioInput,
        apiKey: String,
        model: String
    ) async throws -> ParsedTranscriptionResponse {
        try await standardTranscriptionResponse(
            input: input,
            apiKey: apiKey,
            model: model,
            fellBackFromStreaming: false
        )
    }

    private func standardTranscriptionResponse(
        input: BoundedAudioInput,
        apiKey: String,
        model: String,
        fellBackFromStreaming: Bool
    ) async throws -> ParsedTranscriptionResponse {
        let request = try await Self.makeTranscriptionRequest(
            input: input,
            apiKey: apiKey,
            model: model,
            responseFormat: "text",
            stream: false
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TranscriptionBackendError.networkUnavailable
        }

        let metadata = try Self.responseMetadata(
            from: response,
            requestMode: .standardCompletedRecording,
            fellBackFromStreaming: fellBackFromStreaming
        )

        let text = Self.parsePlainTextResponse(data)
        guard !text.isEmpty else {
            throw TranscriptionBackendError.invalidResponse
        }
        return ParsedTranscriptionResponse(text: text, metadata: metadata)
    }

    nonisolated private static func makeTranscriptionRequest(
        input: BoundedAudioInput,
        apiKey: String,
        model: String,
        responseFormat: String,
        stream: Bool
    ) async throws -> URLRequest {
        try await Task.detached(priority: .userInitiated) {
            let audioData: Data

            do {
                audioData = try Data(contentsOf: input.fileURL, options: [.mappedIfSafe])
            } catch {
                throw TranscriptionBackendError.serializationFailure
            }

            let boundary = "HeadCanonBoundary-\(UUID().uuidString)"
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue(stream ? "text/event-stream" : "text/plain", forHTTPHeaderField: "Accept")
            request.httpBody = multipartBody(
                audioData: audioData,
                input: input,
                boundary: boundary,
                model: model,
                responseFormat: responseFormat,
                stream: stream
            )
            return request
        }.value
    }

    nonisolated private static func responseMetadata(
        from response: URLResponse,
        requestMode: TranscriptionRequestMode,
        fellBackFromStreaming: Bool
    ) throws -> TranscriptionResponseMetadata {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionBackendError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw TranscriptionBackendError.invalidAPIKey
        case 408, 409, 425, 429:
            throw TranscriptionBackendError.networkUnavailable
        case 500 ... 599:
            throw TranscriptionBackendError.networkUnavailable
        default:
            throw TranscriptionBackendError.unexpectedResponse(httpResponse.statusCode)
        }

        return TranscriptionResponseMetadata(
            requestMode: requestMode,
            fellBackFromStreaming: fellBackFromStreaming,
            httpStatusCode: httpResponse.statusCode,
            requestID: headerValue("x-request-id", from: httpResponse),
            openAIProcessingMS: headerValue("openai-processing-ms", from: httpResponse).flatMap(Int.init),
            contentType: headerValue("content-type", from: httpResponse)
        )
    }

    nonisolated private static func parsePlainTextResponse(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func parseStreamingTranscriptionResponse(
        from bytes: URLSession.AsyncBytes
    ) async throws -> String {
        var eventLines: [String] = []
        var accumulatedDeltaText = ""
        var plainTextFallbackLines: [String] = []

        for try await rawLine in bytes.lines {
            let line = rawLine.trimmingCharacters(in: .newlines)

            if line.isEmpty {
                if let completedText = parseStreamEvent(
                    lines: eventLines,
                    accumulatedDeltaText: &accumulatedDeltaText
                ) {
                    return completedText
                }
                eventLines.removeAll(keepingCapacity: true)
                continue
            }

            if line.hasPrefix("event:") || line.hasPrefix("data:") {
                eventLines.append(line)
            } else {
                plainTextFallbackLines.append(line)
            }
        }

        if let completedText = parseStreamEvent(
            lines: eventLines,
            accumulatedDeltaText: &accumulatedDeltaText
        ) {
            return completedText
        }

        let plainTextFallback = plainTextFallbackLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !plainTextFallback.isEmpty {
            return plainTextFallback
        }

        return accumulatedDeltaText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func parseStreamEvent(
        lines: [String],
        accumulatedDeltaText: inout String
    ) -> String? {
        guard !lines.isEmpty else {
            return nil
        }

        let payload = lines
            .compactMap { line -> String? in
                guard line.hasPrefix("data:") else {
                    return nil
                }
                return String(line.dropFirst("data:".count)).trimmingCharacters(in: .whitespaces)
            }
            .joined(separator: "\n")

        guard !payload.isEmpty else {
            return nil
        }

        if payload == "[DONE]" {
            let trimmed = accumulatedDeltaText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        guard
            let data = payload.data(using: .utf8),
            let event = try? JSONDecoder().decode(StreamingTranscriptionEvent.self, from: data)
        else {
            return nil
        }

        switch event.type {
        case "transcript.text.delta":
            accumulatedDeltaText += event.delta ?? ""
            return nil
        case "transcript.text.done":
            return (event.text ?? accumulatedDeltaText)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            return nil
        }
    }

    nonisolated static func multipartBody(
        audioData: Data,
        input: BoundedAudioInput,
        boundary: String,
        model: String,
        responseFormat: String,
        stream: Bool
    ) -> Data {
        var body = Data()

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.appendUTF8("\(model)\r\n")

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.appendUTF8("\(responseFormat)\r\n")

        if stream {
            body.appendUTF8("--\(boundary)\r\n")
            body.appendUTF8("Content-Disposition: form-data; name=\"stream\"\r\n\r\n")
            body.appendUTF8("true\r\n")
        }

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"file\"; filename=\"\(input.fileURL.lastPathComponent)\"\r\n")
        body.appendUTF8("Content-Type: \(input.mimeType)\r\n\r\n")
        body.append(audioData)
        body.appendUTF8("\r\n")

        body.appendUTF8("--\(boundary)--\r\n")

        return body
    }
}

private struct ParsedTranscriptionResponse {
    let text: String
    let metadata: TranscriptionResponseMetadata
}

private struct StreamingTranscriptionEvent: Decodable {
    let type: String
    let delta: String?
    let text: String?
}

private func headerValue(_ key: String, from response: HTTPURLResponse) -> String? {
    response.value(forHTTPHeaderField: key)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        append(Data(string.utf8))
    }
}
