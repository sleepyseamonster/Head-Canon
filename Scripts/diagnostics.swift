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
}

struct TranscriptRecord: Decodable {
    let characterCount: Int?
    let wordCount: Int?
}

struct InsertionRecord: Decodable {
    let applicationName: String
    let bundleIdentifier: String?
    let capabilityProfile: String?
    let target: String?
    let chosenStrategy: String
    let appliedStrategy: String?
    let placeholderPresent: Bool?
    let placeholderLikelyActive: Bool?
    let placeholderAmbiguousValueDetected: Bool?
    let placeholderHandlingOutcome: String?
}

struct FailureRecord: Decodable {
    let stage: String
    let message: String
}

struct ClipboardRecoveryRecord: Decodable {
    let transcriptCopied: Bool
    let reason: String
}

struct AttemptRecord: Decodable {
    let attemptID: UUID
    let completedAt: Date
    let terminalState: TerminalState
    let hotkeyDisplayString: String
    let timing: TimingRecord
    let transcript: TranscriptRecord?
    let backend: BackendRecord
    let releaseTimeInsertion: InsertionRecord?
    let insertion: InsertionRecord?
    let failure: FailureRecord?
    let clipboardRecovery: ClipboardRecoveryRecord?
}

enum AppClass: String, CaseIterable {
    case codex = "Codex"
    case browser = "Browser"
    case native = "Native"
    case unknown = "Unknown"
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

func diagnosticsDirectoryURL() throws -> URL {
    guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        throw NSError(domain: "HeadCanonDiagnostics", code: 1, userInfo: [NSLocalizedDescriptionKey: "Application Support is unavailable."])
    }

    return appSupportURL
        .appendingPathComponent("HeadCanon", isDirectory: true)
        .appendingPathComponent("diagnostics", isDirectory: true)
}

func loadLatestRecord(from directoryURL: URL) throws -> AttemptRecord {
    let latestURL = directoryURL.appendingPathComponent("latest.json", isDirectory: false)
    guard FileManager.default.fileExists(atPath: latestURL.path) else {
        throw NSError(domain: "HeadCanonDiagnostics", code: 2, userInfo: [NSLocalizedDescriptionKey: "No diagnostics records found yet."])
    }
    let data = try Data(contentsOf: latestURL)
    return try decoder.decode(AttemptRecord.self, from: data)
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

func percentile(_ values: [Int], fraction: Double) -> Int? {
    guard !values.isEmpty else {
        return nil
    }

    let sorted = values.sorted()
    let index = Int((Double(sorted.count - 1) * fraction).rounded())
    return sorted[index]
}

func responseHeadersDurationMS(for record: AttemptRecord) -> Int? {
    record.timing.responseHeadersReceivedMS ?? record.backend.responseHeadersReceivedMS
}

func insertionRecord(for record: AttemptRecord) -> InsertionRecord? {
    record.insertion ?? record.releaseTimeInsertion
}

func appClass(for record: AttemptRecord) -> AppClass {
    guard let insertion = insertionRecord(for: record) else {
        return .unknown
    }

    if let bundleIdentifier = insertion.bundleIdentifier?.lowercased(),
       bundleIdentifier == "com.openai.codex" {
        return .codex
    }

    if insertion.applicationName.caseInsensitiveCompare("Codex") == .orderedSame {
        return .codex
    }

    let bundleIdentifier = insertion.bundleIdentifier?.lowercased() ?? ""
    let applicationName = insertion.applicationName.lowercased()
    let browserTokens = [
        "chrome",
        "safari",
        "firefox",
        "arc",
        "brave",
        "edge",
        "opera",
    ]
    if browserTokens.contains(where: { token in
        bundleIdentifier.contains(token) || applicationName.contains(token)
    }) {
        return .browser
    }

    if insertion.capabilityProfile == "opaquePasteCapable" || insertion.capabilityProfile == "nativeAXStrong" {
        return .native
    }

    return .native
}

func failureLabel(for record: AttemptRecord) -> String {
    if let failure = record.failure {
        return failure.stage
    }
    if record.terminalState == .inserted {
        return "none"
    }
    return record.terminalState.rawValue
}

func formatPercentile(_ value: Int?) -> String {
    value.map { "\($0) ms" } ?? "Unknown"
}

func formatSummaryBlock(for records: [AttemptRecord]) -> [String] {
    let requestDurations = records.compactMap(\.timing.requestToResponseDurationMS)
    let releaseToInsertionDurations = records.compactMap(\.timing.releaseToInsertionDurationMS)
    let headerDurations = records.compactMap(responseHeadersDurationMS)
    let transcriptCharacterCounts = records.compactMap { $0.transcript?.characterCount }
    let transcriptWordCounts = records.compactMap { $0.transcript?.wordCount }
    let fallbackCount = records.filter { $0.backend.fellBackFromStreaming == true }.count
    let failureCount = records.filter { $0.terminalState != .inserted }.count

    return [
        "Attempts: \(records.count)",
        "Failures: \(failureCount)",
        "Streaming Fallbacks: \(fallbackCount)",
        "Request -> Response p50: \(formatPercentile(percentile(requestDurations, fraction: 0.5)))",
        "Request -> Response p95: \(formatPercentile(percentile(requestDurations, fraction: 0.95)))",
        "Request -> Headers p50: \(formatPercentile(percentile(headerDurations, fraction: 0.5)))",
        "Request -> Headers p95: \(formatPercentile(percentile(headerDurations, fraction: 0.95)))",
        "Release -> Inserted p50: \(formatPercentile(percentile(releaseToInsertionDurations, fraction: 0.5)))",
        "Release -> Inserted p95: \(formatPercentile(percentile(releaseToInsertionDurations, fraction: 0.95)))",
        "Transcript Characters p50: \(transcriptCharacterCounts.isEmpty ? "Unknown" : String(percentile(transcriptCharacterCounts, fraction: 0.5)!))",
        "Transcript Characters p95: \(transcriptCharacterCounts.isEmpty ? "Unknown" : String(percentile(transcriptCharacterCounts, fraction: 0.95)!))",
        "Transcript Words p50: \(transcriptWordCounts.isEmpty ? "Unknown" : String(percentile(transcriptWordCounts, fraction: 0.5)!))",
        "Transcript Words p95: \(transcriptWordCounts.isEmpty ? "Unknown" : String(percentile(transcriptWordCounts, fraction: 0.95)!))",
    ]
}

func printLatest(_ record: AttemptRecord) {
    print("Attempt: \(record.attemptID.uuidString)")
    print("Completed: \(record.completedAt.formatted(date: .abbreviated, time: .standard))")
    print("State: \(record.terminalState.rawValue)")
    print("Hotkey: \(record.hotkeyDisplayString)")
    print("App Class: \(appClass(for: record).rawValue)")
    print("Request -> Response: \(record.timing.requestToResponseDurationMS.map { "\($0) ms" } ?? "Unknown")")
    print("Release -> Inserted: \(record.timing.releaseToInsertionDurationMS.map { "\($0) ms" } ?? "Unknown")")
    print("Transcript Characters: \(record.transcript?.characterCount.map(String.init) ?? "Unknown")")
    print("Transcript Words: \(record.transcript?.wordCount.map(String.init) ?? "Unknown")")
    print("Backend: \(record.backend.identifier ?? "Unknown")")
    print("Mode: \(record.backend.requestMode ?? "Unknown")")
    print("Fallback: \(record.backend.fellBackFromStreaming == true ? "Yes" : "No")")
    print("HTTP Status: \(record.backend.httpStatusCode.map(String.init) ?? "Unknown")")
    print("Request ID: \(record.backend.requestID ?? "Unknown")")
    print("OpenAI Processing: \(record.backend.openAIProcessingMS.map { "\($0) ms" } ?? "Unknown")")
    print("Content Type: \(record.backend.responseContentType ?? "Unknown")")
    print("Response Headers Received: \(responseHeadersDurationMS(for: record).map { "\($0) ms" } ?? "Unknown")")
    print("Transport Failure Stage: \(record.backend.transportFailureStage ?? "Unknown")")
    print("Network Error Domain: \(record.backend.networkErrorDomain ?? "Unknown")")
    print("Network Error Code: \(record.backend.networkErrorCode.map(String.init) ?? "Unknown")")
    print("Network Error Code Name: \(record.backend.networkErrorCodeName ?? "Unknown")")
    if let releaseTimeInsertion = record.releaseTimeInsertion {
        print("Release-Time Target App: \(releaseTimeInsertion.applicationName)")
        if let target = releaseTimeInsertion.target {
            print("Release-Time Target: \(target)")
        }
        print("Release-Time Planned Strategy: \(releaseTimeInsertion.chosenStrategy)")
    }
    if let insertion = record.insertion {
        print("Target App: \(insertion.applicationName)")
        if let target = insertion.target {
            print("Target: \(target)")
        }
        print("Planned Strategy: \(insertion.chosenStrategy)")
        print("Applied Strategy: \(insertion.appliedStrategy ?? "Unknown")")
        print("Placeholder Present: \(insertion.placeholderPresent == true ? "Yes" : "No")")
        print("Placeholder Likely Active: \(insertion.placeholderLikelyActive == true ? "Yes" : "No")")
        print("Placeholder Ambiguous Value: \(insertion.placeholderAmbiguousValueDetected == true ? "Yes" : "No")")
        print("Placeholder Handling: \(insertion.placeholderHandlingOutcome ?? "Unknown")")
    }
    if let failure = record.failure {
        print("Failure Stage: \(failure.stage)")
        print("Failure Message: \(failure.message)")
    }
    if let clipboardRecovery = record.clipboardRecovery {
        print("Clipboard Recovery: \(clipboardRecovery.transcriptCopied ? "Copied" : "Not Copied")")
        print("Clipboard Recovery Reason: \(clipboardRecovery.reason)")
    }
}

func printRecent(_ records: [AttemptRecord]) {
    if records.isEmpty {
        print("No diagnostics records found.")
        return
    }

    for record in records {
        let requestMS = record.timing.requestToResponseDurationMS.map(String.init) ?? "?"
        let insertionMS = record.timing.releaseToInsertionDurationMS.map(String.init) ?? "?"
        let characterCount = record.transcript?.characterCount.map(String.init) ?? "?"
        let appName = insertionRecord(for: record)?.applicationName ?? "Unknown App"
        let appliedStrategy = insertionRecord(for: record)?.appliedStrategy ?? insertionRecord(for: record)?.chosenStrategy ?? "unknown"
        let netCode = record.backend.networkErrorCodeName ?? record.backend.networkErrorCode.map(String.init) ?? "-"
        let headerMS = responseHeadersDurationMS(for: record).map(String.init) ?? "?"
        print("\(record.completedAt.formatted(date: .omitted, time: .standard)) | \(record.terminalState.rawValue) | req \(requestMS) ms | hdr \(headerMS) ms | total \(insertionMS) ms | chars \(characterCount) | \(appClass(for: record).rawValue) | \(appName) | \(appliedStrategy) | net \(netCode)")
    }
}

func printSummary(_ records: [AttemptRecord]) {
    for line in formatSummaryBlock(for: records) {
        print(line)
    }
}

func printSummaryByModel(_ records: [AttemptRecord]) {
    if records.isEmpty {
        print("No diagnostics records found.")
        return
    }

    let grouped = Dictionary(grouping: records) { record in
        record.backend.identifier ?? "Unknown"
    }

    for backendID in grouped.keys.sorted() {
        guard let groupedRecords = grouped[backendID] else {
            continue
        }

        print(backendID)
        for line in formatSummaryBlock(for: groupedRecords) {
            print("  \(line)")
        }
    }
}

func printSummaryByAppClass(_ records: [AttemptRecord]) {
    if records.isEmpty {
        print("No diagnostics records found.")
        return
    }

    let grouped = Dictionary(grouping: records, by: appClass)

    for appClassKey in AppClass.allCases {
        guard let groupedRecords = grouped[appClassKey], !groupedRecords.isEmpty else {
            continue
        }

        let appNames = Set(groupedRecords.compactMap { insertionRecord(for: $0)?.applicationName }).sorted()
        print(appClassKey.rawValue)
        if !appNames.isEmpty {
            print("  Apps: \(appNames.joined(separator: ", "))")
        }
        for line in formatSummaryBlock(for: groupedRecords) {
            print("  \(line)")
        }
    }
}

func printSummaryByFailure(_ records: [AttemptRecord]) {
    if records.isEmpty {
        print("No diagnostics records found.")
        return
    }

    let grouped = Dictionary(grouping: records, by: failureLabel)

    for label in grouped.keys.sorted() {
        guard let groupedRecords = grouped[label] else {
            continue
        }

        print(label)
        for line in formatSummaryBlock(for: groupedRecords) {
            print("  \(line)")
        }
    }
}

func usage() {
    print("Usage:")
    print("  Scripts/diagnostics.swift latest")
    print("  Scripts/diagnostics.swift recent [count]")
    print("  Scripts/diagnostics.swift summary [count]")
    print("  Scripts/diagnostics.swift summary-by-model [count]")
    print("  Scripts/diagnostics.swift summary-by-app-class [count]")
    print("  Scripts/diagnostics.swift summary-by-failure [count]")
}

let command = CommandLine.arguments.dropFirst().first ?? "latest"

do {
    let directoryURL = try diagnosticsDirectoryURL()

    switch command {
    case "latest":
        printLatest(try loadLatestRecord(from: directoryURL))
    case "recent":
        let count = Int(CommandLine.arguments.dropFirst(2).first ?? "") ?? 10
        printRecent(try loadRecentRecords(from: directoryURL, limit: count))
    case "summary":
        let count = Int(CommandLine.arguments.dropFirst(2).first ?? "") ?? 25
        printSummary(try loadRecentRecords(from: directoryURL, limit: count))
    case "summary-by-model":
        let count = Int(CommandLine.arguments.dropFirst(2).first ?? "") ?? 50
        printSummaryByModel(try loadRecentRecords(from: directoryURL, limit: count))
    case "summary-by-app-class", "summary-by-app":
        let count = Int(CommandLine.arguments.dropFirst(2).first ?? "") ?? 50
        printSummaryByAppClass(try loadRecentRecords(from: directoryURL, limit: count))
    case "summary-by-failure":
        let count = Int(CommandLine.arguments.dropFirst(2).first ?? "") ?? 50
        printSummaryByFailure(try loadRecentRecords(from: directoryURL, limit: count))
    default:
        usage()
        exit(1)
    }
} catch {
    fputs("Head Canon diagnostics error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
