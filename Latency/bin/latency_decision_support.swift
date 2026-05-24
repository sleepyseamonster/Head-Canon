#!/usr/bin/env swift

import Foundation

enum TerminalState: String, Decodable {
    case inserted
    case failed
    case timedOut
    case canceled
}

struct TimingRecord: Decodable {
    let requestToResponseDurationMS: Int?
    let releaseToInsertionDurationMS: Int?
    let responseHeadersReceivedMS: Int?
}

struct BackendRecord: Decodable {
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
}

struct TranscriptRecord: Decodable {
    let characterCount: Int?
    let wordCount: Int?
}

struct FailureRecord: Decodable {
    let stage: String
    let message: String
}

struct AttemptRecord: Decodable {
    let completedAt: Date
    let terminalState: TerminalState
    let truthState: String?
    let timing: TimingRecord
    let transcript: TranscriptRecord?
    let backend: BackendRecord
    let failure: FailureRecord?
}

struct NetworkQualitySample {
    let uplinkMbps: Double?
    let downlinkMbps: Double?
    let responsivenessLabel: String?
    let responsivenessSeconds: Double?
    let responsivenessRPM: Int?
    let idleLatencyMS: Double?
    let idleRPM: Int?
}

struct ParsedArguments {
    let window: Int
    let networkQualityFile: String?
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

func parseArguments() -> ParsedArguments {
    var window = 20
    var networkQualityFile: String?

    var index = 1
    while index < CommandLine.arguments.count {
        let argument = CommandLine.arguments[index]
        switch argument {
        case "--window":
            if index + 1 < CommandLine.arguments.count, let value = Int(CommandLine.arguments[index + 1]) {
                window = max(value, 1)
                index += 1
            }
        case "--network-quality-file":
            if index + 1 < CommandLine.arguments.count {
                networkQualityFile = CommandLine.arguments[index + 1]
                index += 1
            }
        default:
            break
        }
        index += 1
    }

    return ParsedArguments(window: window, networkQualityFile: networkQualityFile)
}

func diagnosticsDirectoryURL() throws -> URL {
    guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        throw NSError(domain: "LatencyDecisionSupport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Application Support is unavailable."])
    }

    return appSupportURL
        .appendingPathComponent("HeadCanon", isDirectory: true)
        .appendingPathComponent("diagnostics", isDirectory: true)
}

func loadRecentRecords(from directoryURL: URL, limit: Int) throws -> [AttemptRecord] {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: directoryURL.path) else {
        return []
    }

    let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    let logFiles = contents
        .filter { $0.lastPathComponent.hasPrefix("attempts") && $0.pathExtension == "jsonl" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    var records: [AttemptRecord] = []

    for fileURL in logFiles {
        let data = try Data(contentsOf: fileURL)
        guard let text = String(data: data, encoding: .utf8) else {
            continue
        }

        for line in text.split(separator: "\n") {
            guard let lineData = line.data(using: .utf8) else {
                continue
            }

            if let record = try? decoder.decode(AttemptRecord.self, from: lineData) {
                records.append(record)
            }
        }
    }

    return Array(records.suffix(max(limit, 0)))
}

func percentile(_ values: [Double], fraction: Double) -> Double? {
    guard !values.isEmpty else {
        return nil
    }

    let sorted = values.sorted()
    let index = Int((Double(sorted.count - 1) * fraction).rounded())
    return sorted[index]
}

func median(_ values: [Double]) -> Double? {
    percentile(values, fraction: 0.5)
}

func parseNetworkQualitySample(from filePath: String?) -> NetworkQualitySample? {
    guard let filePath else {
        return nil
    }

    guard let text = try? String(contentsOfFile: filePath, encoding: .utf8) else {
        return nil
    }

    func firstMatch(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else {
            return nil
        }

        return (1..<match.numberOfRanges).compactMap { index in
            let captureRange = match.range(at: index)
            guard let swiftRange = Range(captureRange, in: text) else {
                return nil
            }
            return String(text[swiftRange])
        }
    }

    let uplinkMbps = firstMatch(#"Uplink capacity:\s+([0-9.]+)\s+Mbps"#, in: text).flatMap { Double($0[0]) }
    let downlinkMbps = firstMatch(#"Downlink capacity:\s+([0-9.]+)\s+Mbps"#, in: text).flatMap { Double($0[0]) }

    var responsivenessLabel: String?
    var responsivenessSeconds: Double?
    var responsivenessRPM: Int?
    if let match = firstMatch(#"Responsiveness:\s+([A-Za-z]+)\s+\(([0-9.]+)\s+seconds\s+\|\s+([0-9]+)\s+RPM\)"#, in: text), match.count == 3 {
        responsivenessLabel = match[0]
        responsivenessSeconds = Double(match[1])
        responsivenessRPM = Int(match[2])
    }

    var idleLatencyMS: Double?
    var idleRPM: Int?
    if let match = firstMatch(#"Idle Latency:\s+([0-9.]+)\s+milliseconds\s+\|\s+([0-9]+)\s+RPM"#, in: text), match.count == 2 {
        idleLatencyMS = Double(match[0])
        idleRPM = Int(match[1])
    }

    return NetworkQualitySample(
        uplinkMbps: uplinkMbps,
        downlinkMbps: downlinkMbps,
        responsivenessLabel: responsivenessLabel,
        responsivenessSeconds: responsivenessSeconds,
        responsivenessRPM: responsivenessRPM,
        idleLatencyMS: idleLatencyMS,
        idleRPM: idleRPM
    )
}

func formatMS(_ value: Double?) -> String {
    guard let value else {
        return "Unknown"
    }
    return "\(Int(value.rounded())) ms"
}

func formatCount(_ value: Int?) -> String {
    guard let value else {
        return "Unknown"
    }
    return String(value)
}

func formatRatio(_ value: Double?) -> String {
    guard let value else {
        return "Unknown"
    }
    return "\(Int((value * 100).rounded()))%"
}

func formatSeconds(_ value: Double?) -> String {
    guard let value else {
        return "Unknown"
    }
    return String(format: "%.3f s", value)
}

func formatMbps(_ value: Double?) -> String {
    guard let value else {
        return "Unknown"
    }
    return String(format: "%.3f Mbps", value)
}

func truthLabel(for record: AttemptRecord) -> String {
    if let truthState = record.truthState {
        return truthState
    }

    if let failureStage = record.failure?.stage, failureStage == "transcription" {
        return "transcriptionFailed"
    }

    switch record.terminalState {
    case .inserted:
        return "inserted"
    case .failed:
        return "failed"
    case .timedOut:
        return "timedOut"
    case .canceled:
        return "canceled"
    }
}

let arguments = parseArguments()

do {
    let directoryURL = try diagnosticsDirectoryURL()
    let recentRecords = try loadRecentRecords(from: directoryURL, limit: max(arguments.window, 50))
    let windowRecords = Array(recentRecords.suffix(arguments.window))

    guard !windowRecords.isEmpty else {
        print("Assessment: no data")
        print("Reason: no recent diagnostics records were found.")
        exit(0)
    }

    let successfulRecords = windowRecords.filter { $0.terminalState == .inserted }
    let requestDurations = successfulRecords.compactMap { $0.timing.requestToResponseDurationMS.map(Double.init) }
    let headerDurations = successfulRecords.compactMap {
        ($0.timing.responseHeadersReceivedMS ?? $0.backend.responseHeadersReceivedMS).map(Double.init)
    }
    let releaseDurations = successfulRecords.compactMap { $0.timing.releaseToInsertionDurationMS.map(Double.init) }
    let responseToInsertionDurations = successfulRecords.compactMap { record -> Double? in
        guard
            let requestMS = record.timing.requestToResponseDurationMS,
            let releaseMS = record.timing.releaseToInsertionDurationMS
        else {
            return nil
        }
        return Double(max(releaseMS - requestMS, 0))
    }
    let headerShareValues = successfulRecords.compactMap { record -> Double? in
        guard
            let requestMS = record.timing.requestToResponseDurationMS,
            requestMS > 0,
            let headerMS = record.timing.responseHeadersReceivedMS ?? record.backend.responseHeadersReceivedMS
        else {
            return nil
        }
        return Double(headerMS) / Double(requestMS)
    }

    let nonInsertedRecords = windowRecords.filter { $0.terminalState != .inserted }
    let noSpeechRecords = nonInsertedRecords.filter { truthLabel(for: $0) == "noSpeechDetected" }
    let failures = nonInsertedRecords.filter { truthLabel(for: $0) != "noSpeechDetected" }
    let transcriptionFailures = failures.filter { truthLabel(for: $0) == "transcriptionFailed" || $0.failure?.stage == "transcription" }
    let bodyReadFailures = transcriptionFailures.filter { $0.backend.transportFailureStage == "readingResponseBody" }

    let emptyBodyFailures = bodyReadFailures.filter { $0.backend.responseBodyByteCount == 0 }
    let utf8DecodeFailures = bodyReadFailures.filter { $0.backend.responseBodyUTF8Decodable == false }
    let contentLengthMismatchFailures = bodyReadFailures.filter { record in
        guard
            let expected = record.backend.responseContentLengthBytes,
            let actual = record.backend.responseBodyByteCount
        else {
            return false
        }
        return expected != actual
    }
    let missingBodyEvidenceFailures = bodyReadFailures.filter { $0.backend.responseBodyByteCount == nil }

    let slowSuccesses = successfulRecords.filter { ($0.timing.requestToResponseDurationMS ?? 0) >= 5_000 }
    let verySlowSuccesses = successfulRecords.filter { ($0.timing.requestToResponseDurationMS ?? 0) >= 10_000 }

    let requestP50 = median(requestDurations)
    let requestP95 = percentile(requestDurations, fraction: 0.95)
    let headerP50 = median(headerDurations)
    let headerShareP50 = median(headerShareValues)
    let releaseP50 = median(releaseDurations)
    let responseToInsertionP50 = median(responseToInsertionDurations)

    let networkQuality = parseNetworkQualitySample(from: arguments.networkQualityFile)
    let networkResponsivenessPoor = (networkQuality?.responsivenessSeconds ?? 0) >= 1.0
        || (networkQuality?.idleLatencyMS ?? 0) >= 200

    let primaryBottleneck: String
    if bodyReadFailures.isEmpty == false {
        primaryBottleneck = "transcription response-body instability"
    } else if (headerShareP50 ?? 0) >= 0.8 && (requestP50 ?? 0) >= 3_000 {
        primaryBottleneck = "pre-response transcription wait"
    } else if (responseToInsertionP50 ?? 0) >= 1_500 {
        primaryBottleneck = "post-response insertion overhead"
    } else {
        primaryBottleneck = "mixed but mostly healthy"
    }

    let assessment: String
    if bodyReadFailures.isEmpty == false || (requestP50 ?? 0) >= 4_000 {
        assessment = "degraded"
    } else if (requestP50 ?? 0) >= 2_500 || failures.isEmpty == false {
        assessment = "watch"
    } else {
        assessment = "healthy"
    }

    var interpretation: [String] = []

    if bodyReadFailures.isEmpty == false {
        interpretation.append("Recent failures are concentrated in transcription body reads after HTTP 200 responses.")
        if missingBodyEvidenceFailures.isEmpty == false {
            interpretation.append("Some failures predate the new body instrumentation, so response-body evidence is still incomplete in the rolling window.")
        }
        if emptyBodyFailures.isEmpty == false {
            interpretation.append("At least one recent body-read failure matches an empty-body pattern.")
        }
        if utf8DecodeFailures.isEmpty == false {
            interpretation.append("At least one recent body-read failure was not UTF-8 decodable.")
        }
        if contentLengthMismatchFailures.isEmpty == false {
            interpretation.append("At least one recent body-read failure had a content-length mismatch.")
        }
    }

    if noSpeechRecords.isEmpty == false {
        interpretation.append("Some non-inserted turns were classified as no speech or too short; those are excluded from transport/body-read degradation.")
    }

    if (headerShareP50 ?? 0) >= 0.8 && (requestP50 ?? 0) >= 3_000 {
        interpretation.append("Most successful-turn latency is being spent before or while waiting for response headers, not after the transcript arrives.")
    }

    if networkResponsivenessPoor {
        interpretation.append("Current network responsiveness is poor enough to plausibly contribute to higher transcription latency.")
    }

    if (responseToInsertionP50 ?? 0) < 1_000 {
        interpretation.append("Insertion overhead after the transcription response remains relatively small.")
    }

    if interpretation.isEmpty {
        interpretation.append("This window does not show a strong single bottleneck.")
    }

    print("Assessment: \(assessment)")
    print("Primary Bottleneck: \(primaryBottleneck)")
    print("Window: \(arguments.window) attempts")
    print("Successful Turns: \(successfulRecords.count)")
    print("Failures: \(failures.count)")
    print("No Speech / Too Short Turns: \(noSpeechRecords.count)")
    print("Request -> Response p50: \(formatMS(requestP50))")
    print("Request -> Response p95: \(formatMS(requestP95))")
    print("Request -> Headers p50: \(formatMS(headerP50))")
    print("Headers Share p50: \(formatRatio(headerShareP50))")
    print("Release -> Inserted p50: \(formatMS(releaseP50))")
    print("Response -> Inserted p50: \(formatMS(responseToInsertionP50))")
    print("Slow Successes >= 5s: \(slowSuccesses.count)/\(successfulRecords.count)")
    print("Very Slow Successes >= 10s: \(verySlowSuccesses.count)/\(successfulRecords.count)")
    print("Body-Read Failures: \(bodyReadFailures.count)")
    print("Body-Read Failures With Empty Body Evidence: \(emptyBodyFailures.count)")
    print("Body-Read Failures With UTF-8 Decode Failure: \(utf8DecodeFailures.count)")
    print("Body-Read Failures With Content-Length Mismatch: \(contentLengthMismatchFailures.count)")
    print("Body-Read Failures Missing Body Evidence: \(missingBodyEvidenceFailures.count)")

    if let networkQuality {
        print("Network Uplink: \(formatMbps(networkQuality.uplinkMbps))")
        print("Network Downlink: \(formatMbps(networkQuality.downlinkMbps))")
        print("Network Responsiveness: \(networkQuality.responsivenessLabel ?? "Unknown") (\(formatSeconds(networkQuality.responsivenessSeconds)))")
        print("Network Idle Latency: \(networkQuality.idleLatencyMS.map { String(format: "%.3f ms", $0) } ?? "Unknown")")
    } else {
        print("Network Quality: Not captured")
    }

    print("Interpretation:")
    for line in interpretation {
        print("- \(line)")
    }

    print("Next Check:")
    if bodyReadFailures.isEmpty == false {
        print("- Inspect the next transcription failure with the latest diagnostics output to confirm whether body bytes are empty, mismatched, or non-UTF-8.")
    } else if networkResponsivenessPoor {
        print("- Compare another latency capture against a second networkQuality sample during the same slowdown window.")
    } else {
        print("- Capture another short window after 5-10 more turns to see whether the slowdown persists or normalizes.")
    }
} catch {
    fputs("latency_decision_support.swift failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
