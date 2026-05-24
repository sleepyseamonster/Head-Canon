import Foundation

struct OpenAIBoundedTranscriptionBackend: TranscriptionBackend {
    private static let boundedDictationLanguageCode = "en"
    private let modelProvider: () -> OpenAITranscriptionModel
    private let session: URLSession
    private let sessionConfiguration: URLSessionConfiguration

    init(
        modelProvider: @escaping () -> OpenAITranscriptionModel = { .gpt4oMiniTranscribe },
        session: URLSession? = nil
    ) {
        self.modelProvider = modelProvider
        if let session {
            self.session = session
            let configuration = (session.configuration.copy() as? URLSessionConfiguration)
                ?? session.configuration
            Self.configureTranscriptionSession(configuration)
            self.sessionConfiguration = configuration
        } else {
            let configuration = URLSessionConfiguration.default
            Self.configureTranscriptionSession(configuration)
            self.sessionConfiguration = configuration
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
            throw TranscriptionBackendError.networkUnavailable()
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionBackendError.invalidResponse()
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 401, 403:
            throw TranscriptionBackendError.invalidAPIKey
        case 408, 409, 425, 429:
            throw TranscriptionBackendError.networkUnavailable()
        case 500 ... 599:
            throw TranscriptionBackendError.networkUnavailable()
        default:
            throw TranscriptionBackendError.unexpectedResponse(httpResponse.statusCode)
        }
    }

    func transcribe(_ input: BoundedAudioInput, apiKey: String) async throws -> TranscriptionResult {
        let model = modelProvider().rawValue
        let response = try await standardTranscriptionResponse(
            input: input,
            apiKey: apiKey,
            model: model
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
        let requestMode: TranscriptionRequestMode = .streamedCompletedRecording
        let request = try await Self.makeTranscriptionRequest(
            input: input,
            apiKey: apiKey,
            model: model,
            responseFormat: "text",
            language: Self.boundedDictationLanguageCode,
            stream: true
        )

        let clock = ContinuousClock()
        let requestStartedAt = clock.now
        let data: Data
        let response: URLResponse

        do {
            (data, response, _) = try await performCancelableDataRequest(
                for: request,
                requestStartedAt: requestStartedAt
            )
        } catch {
            throw Self.networkFailure(
                from: error,
                requestMode: requestMode,
                fellBackFromStreaming: false,
                responseHeadersReceivedMS: nil,
                transportFailureStage: .awaitingResponseHeaders
            )
        }

        let responseHeadersReceivedMS = Self.elapsedMilliseconds(since: requestStartedAt, clock: clock)
        let metadata = try Self.responseMetadata(
            from: response,
            requestMode: requestMode,
            fellBackFromStreaming: false,
            responseHeadersReceivedMS: responseHeadersReceivedMS
        )

        let bodyDiagnostics = Self.responseBodyDiagnostics(from: data, response: response)
        let text: String
        do {
            text = try Self.parseStreamingTranscriptionResponse(from: data)
        } catch {
            throw Self.networkFailure(
                from: error,
                requestMode: requestMode,
                fellBackFromStreaming: false,
                responseMetadata: metadata,
                responseHeadersReceivedMS: responseHeadersReceivedMS,
                transportFailureStage: .readingResponseBody
            )
        }

        guard !text.isEmpty else {
            throw TranscriptionBackendError.invalidResponse(
                Self.failureContext(
                    requestMode: requestMode,
                    fellBackFromStreaming: false,
                    responseMetadata: metadata,
                    responseHeadersReceivedMS: responseHeadersReceivedMS,
                    transportFailureStage: .readingResponseBody,
                    networkError: nil,
                    responseBodyDiagnostics: bodyDiagnostics
                )
            )
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
        let requestMode: TranscriptionRequestMode = .standardCompletedRecording
        let request = try await Self.makeTranscriptionRequest(
            input: input,
            apiKey: apiKey,
            model: model,
            responseFormat: "text",
            language: Self.boundedDictationLanguageCode,
            stream: false
        )

        let clock = ContinuousClock()
        let requestStartedAt = clock.now
        let data: Data
        let response: URLResponse

        do {
            let requestSession = URLSession(configuration: sessionConfiguration)
            defer {
                requestSession.invalidateAndCancel()
            }
            (data, response) = try await requestSession.data(for: request)
        } catch {
            if Self.isCancellation(error) {
                throw CancellationError()
            }

            throw Self.networkFailure(
                from: error,
                requestMode: requestMode,
                fellBackFromStreaming: fellBackFromStreaming,
                responseHeadersReceivedMS: nil,
                transportFailureStage: .awaitingResponseHeaders
            )
        }

        let resolvedResponseHeadersReceivedMS = Self.elapsedMilliseconds(since: requestStartedAt, clock: clock)
        let metadata = try Self.responseMetadata(
            from: response,
            requestMode: requestMode,
            fellBackFromStreaming: fellBackFromStreaming,
            responseHeadersReceivedMS: resolvedResponseHeadersReceivedMS
        )

        let inspectedBody = Self.inspectPlainTextResponse(data, response: response)
        let text = inspectedBody.text
        guard !text.isEmpty else {
            throw TranscriptionBackendError.emptyTranscript(
                Self.failureContext(
                    requestMode: requestMode,
                    fellBackFromStreaming: fellBackFromStreaming,
                    responseMetadata: metadata,
                    responseHeadersReceivedMS: resolvedResponseHeadersReceivedMS,
                    transportFailureStage: .readingResponseBody,
                    networkError: nil,
                    responseBodyDiagnostics: inspectedBody.diagnostics
                )
            )
        }
        return ParsedTranscriptionResponse(text: text, metadata: metadata)
    }

    private func performCancelableDataRequest(
        for request: URLRequest,
        requestStartedAt: ContinuousClock.Instant
    ) async throws -> (Data, URLResponse, Int?) {
        let delegate = CancelableDataTaskDelegate(requestStartedAt: requestStartedAt)
        let requestSession = URLSession(
            configuration: sessionConfiguration,
            delegate: delegate,
            delegateQueue: nil
        )
        defer {
            requestSession.invalidateAndCancel()
        }
        return try await delegate.run(in: requestSession, request: request)
    }

    private static func configureTranscriptionSession(_ configuration: URLSessionConfiguration) {
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 120
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpMaximumConnectionsPerHost = 1
    }

    nonisolated private static func makeTranscriptionRequest(
        input: BoundedAudioInput,
        apiKey: String,
        model: String,
        responseFormat: String,
        language: String,
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
                language: language,
                stream: stream
            )
            return request
        }.value
    }

    nonisolated private static func responseMetadata(
        from response: URLResponse,
        requestMode: TranscriptionRequestMode,
        fellBackFromStreaming: Bool,
        responseHeadersReceivedMS: Int?
    ) throws -> TranscriptionResponseMetadata {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionBackendError.invalidResponse(
                failureContext(
                    requestMode: requestMode,
                    fellBackFromStreaming: fellBackFromStreaming,
                    responseMetadata: nil,
                    responseHeadersReceivedMS: responseHeadersReceivedMS,
                    transportFailureStage: .awaitingResponseHeaders,
                    networkError: nil
                )
            )
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw TranscriptionBackendError.invalidAPIKey
        case 408, 409, 425, 429:
            throw TranscriptionBackendError.networkUnavailable(
                failureContext(
                    requestMode: requestMode,
                    fellBackFromStreaming: fellBackFromStreaming,
                    httpResponse: httpResponse,
                    responseHeadersReceivedMS: responseHeadersReceivedMS,
                    transportFailureStage: .awaitingResponseHeaders,
                    networkError: nil
                )
            )
        case 500 ... 599:
            throw TranscriptionBackendError.networkUnavailable(
                failureContext(
                    requestMode: requestMode,
                    fellBackFromStreaming: fellBackFromStreaming,
                    httpResponse: httpResponse,
                    responseHeadersReceivedMS: responseHeadersReceivedMS,
                    transportFailureStage: .awaitingResponseHeaders,
                    networkError: nil
                )
            )
        default:
            throw TranscriptionBackendError.unexpectedResponse(
                httpResponse.statusCode,
                failureContext(
                    requestMode: requestMode,
                    fellBackFromStreaming: fellBackFromStreaming,
                    httpResponse: httpResponse,
                    responseHeadersReceivedMS: responseHeadersReceivedMS,
                    transportFailureStage: .awaitingResponseHeaders,
                    networkError: nil
                )
            )
        }

        return TranscriptionResponseMetadata(
            requestMode: requestMode,
            fellBackFromStreaming: fellBackFromStreaming,
            httpStatusCode: httpResponse.statusCode,
            requestID: headerValue("x-request-id", from: httpResponse),
            openAIProcessingMS: headerValue("openai-processing-ms", from: httpResponse).flatMap(Int.init),
            contentType: headerValue("content-type", from: httpResponse),
            responseHeadersReceivedMS: responseHeadersReceivedMS
        )
    }

    nonisolated private static func elapsedMilliseconds(
        since start: ContinuousClock.Instant,
        clock: ContinuousClock
    ) -> Int {
        let duration = start.duration(to: clock.now)
        let components = duration.components
        let secondsMS = components.seconds * 1000
        let attosecondsMS = components.attoseconds / 1_000_000_000_000_000
        return Int(secondsMS + attosecondsMS)
    }

    nonisolated private static func networkFailure(
        from error: Error,
        requestMode: TranscriptionRequestMode,
        fellBackFromStreaming: Bool,
        responseMetadata: TranscriptionResponseMetadata? = nil,
        responseHeadersReceivedMS: Int?,
        transportFailureStage: TranscriptionTransportFailureStage
    ) -> TranscriptionBackendError {
        .networkUnavailable(
            failureContext(
                requestMode: requestMode,
                fellBackFromStreaming: fellBackFromStreaming,
                responseMetadata: responseMetadata,
                responseHeadersReceivedMS: responseHeadersReceivedMS,
                transportFailureStage: transportFailureStage,
                networkError: error
            )
        )
    }

    nonisolated private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        return (error as? URLError)?.code == .cancelled
    }

    nonisolated private static func failureContext(
        requestMode: TranscriptionRequestMode,
        fellBackFromStreaming: Bool,
        httpResponse: HTTPURLResponse? = nil,
        responseMetadata: TranscriptionResponseMetadata? = nil,
        responseHeadersReceivedMS: Int?,
        transportFailureStage: TranscriptionTransportFailureStage?,
        networkError: Error?,
        responseBodyDiagnostics: ResponseBodyDiagnostics? = nil
    ) -> TranscriptionFailureContext {
        let resolvedHTTPResponse = httpResponse
        let resolvedMetadata = responseMetadata
        let nsError = networkError as NSError?
        let urlError = networkError as? URLError

        return TranscriptionFailureContext(
            requestMode: requestMode,
            fellBackFromStreaming: fellBackFromStreaming,
            httpStatusCode: resolvedMetadata?.httpStatusCode ?? resolvedHTTPResponse?.statusCode,
            requestID: resolvedMetadata?.requestID ?? resolvedHTTPResponse.flatMap { headerValue("x-request-id", from: $0) },
            openAIProcessingMS: resolvedMetadata?.openAIProcessingMS ?? resolvedHTTPResponse.flatMap { headerValue("openai-processing-ms", from: $0) }.flatMap(Int.init),
            contentType: resolvedMetadata?.contentType ?? resolvedHTTPResponse.flatMap { headerValue("content-type", from: $0) },
            responseHeadersReceivedMS: resolvedMetadata?.responseHeadersReceivedMS ?? responseHeadersReceivedMS,
            transportFailureStage: transportFailureStage,
            networkErrorDomain: nsError?.domain,
            networkErrorCode: nsError?.code,
            networkErrorCodeName: urlError.map { String(describing: $0.code) },
            responseBodyByteCount: responseBodyDiagnostics?.byteCount,
            responseBodyUTF8Decodable: responseBodyDiagnostics?.utf8Decodable,
            responseBodyTrimmedCharacterCount: responseBodyDiagnostics?.trimmedCharacterCount,
            responseContentLengthBytes: responseBodyDiagnostics?.contentLengthBytes
        )
    }

    nonisolated private static func inspectPlainTextResponse(
        _ data: Data,
        response: URLResponse
    ) -> InspectedPlainTextResponse {
        let diagnostics = responseBodyDiagnostics(from: data, response: response)
        let text = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return InspectedPlainTextResponse(text: text, diagnostics: diagnostics)
    }

    nonisolated private static func responseBodyDiagnostics(
        from data: Data,
        response: URLResponse
    ) -> ResponseBodyDiagnostics {
        let utf8String = String(data: data, encoding: .utf8)
        let trimmedCharacterCount = utf8String?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .count

        return ResponseBodyDiagnostics(
            byteCount: data.count,
            utf8Decodable: utf8String != nil,
            trimmedCharacterCount: trimmedCharacterCount,
            contentLengthBytes: responseContentLengthBytes(from: response)
        )
    }

    nonisolated private static func responseContentLengthBytes(from response: URLResponse) -> Int? {
        if response.expectedContentLength >= 0 {
            return Int(response.expectedContentLength)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }

        return headerValue("content-length", from: httpResponse).flatMap(Int.init)
    }

    nonisolated private static func parseStreamingTranscriptionResponse(from data: Data) throws -> String {
        var eventLines: [String] = []
        var accumulatedDeltaText = ""
        var sawStructuredStreamingLine = false

        guard let payload = String(data: data, encoding: .utf8) else {
            return ""
        }

        for rawLine in payload.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let rawLineString = String(rawLine)
            let line = rawLineString.trimmingCharacters(in: .newlines)

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
                sawStructuredStreamingLine = true
                eventLines.append(line)
            }
        }

        if let completedText = parseStreamEvent(
            lines: eventLines,
            accumulatedDeltaText: &accumulatedDeltaText
        ) {
            return completedText
        }

        let accumulatedText = accumulatedDeltaText.trimmingCharacters(in: .whitespacesAndNewlines)
        if sawStructuredStreamingLine, !accumulatedText.isEmpty {
            return accumulatedText
        }

        return ""
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
        language: String,
        stream: Bool
    ) -> Data {
        var body = Data()

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.appendUTF8("\(model)\r\n")

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.appendUTF8("\(responseFormat)\r\n")

        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
        body.appendUTF8("\(language)\r\n")

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

private final class CancelableDataTaskDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private let clock = ContinuousClock()
    private let requestStartedAt: ContinuousClock.Instant
    private var task: URLSessionDataTask?
    private var continuation: CheckedContinuation<(Data, URLResponse, Int?), Error>?
    private var response: URLResponse?
    private var responseHeadersReceivedMS: Int?
    private var data = Data()
    private var completed = false

    init(requestStartedAt: ContinuousClock.Instant) {
        self.requestStartedAt = requestStartedAt
    }

    func run(in session: URLSession, request: URLRequest) async throws -> (Data, URLResponse, Int?) {
        let task = session.dataTask(with: request)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.withLock {
                    self.task = task
                    self.continuation = continuation
                }
                task.resume()
            }
        } onCancel: {
            cancel()
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        lock.withLock {
            self.response = response
            if responseHeadersReceivedMS == nil {
                responseHeadersReceivedMS = elapsedMillisecondsSinceStart()
            }
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.withLock {
            self.data.append(data)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let resolution: Resolution? = lock.withLock {
            guard !completed else {
                return nil
            }

            completed = true
            self.task = nil

            let continuation = self.continuation
            self.continuation = nil

            if let error {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain, nsError.code == URLError.cancelled.rawValue {
                    return continuation.map { Resolution(continuation: $0, result: .failure(CancellationError())) }
                }
                return continuation.map { Resolution(continuation: $0, result: .failure(error)) }
            }

            guard let response else {
                return continuation.map {
                    Resolution(continuation: $0, result: .failure(TranscriptionBackendError.invalidResponse()))
                }
            }

            return continuation.map {
                Resolution(
                    continuation: $0,
                    result: .success((data, response, responseHeadersReceivedMS))
                )
            }
        }

        resolution?.resume()
    }

    private func cancel() {
        let cancellation: (URLSessionDataTask?, Resolution?) = lock.withLock {
            guard !completed else {
                return (nil, nil)
            }

            completed = true
            let task = self.task
            self.task = nil

            let continuation = self.continuation
            self.continuation = nil

            return (
                task,
                continuation.map {
                    Resolution(continuation: $0, result: .failure(CancellationError()))
                }
            )
        }

        let (task, resolution) = cancellation
        task?.cancel()
        resolution?.resume()
    }

    private func elapsedMillisecondsSinceStart() -> Int {
        let duration = requestStartedAt.duration(to: clock.now)
        let components = duration.components
        let secondsMS = components.seconds * 1000
        let attosecondsMS = components.attoseconds / 1_000_000_000_000_000
        return Int(secondsMS + attosecondsMS)
    }
}

private struct Resolution {
    let continuation: CheckedContinuation<(Data, URLResponse, Int?), Error>
    let result: Result<(Data, URLResponse, Int?), Error>

    func resume() {
        continuation.resume(with: result)
    }
}

private struct ParsedTranscriptionResponse {
    let text: String
    let metadata: TranscriptionResponseMetadata
}

private struct InspectedPlainTextResponse {
    let text: String
    let diagnostics: ResponseBodyDiagnostics
}

private struct ResponseBodyDiagnostics {
    let byteCount: Int
    let utf8Decodable: Bool
    let trimmedCharacterCount: Int?
    let contentLengthBytes: Int?
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
