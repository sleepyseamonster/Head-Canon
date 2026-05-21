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
}

struct BackendRecord: Decodable {
    let identifier: String?
    let requestMode: String?
    let fellBackFromStreaming: Bool?
    let httpStatusCode: Int?
    let requestID: String?
    let openAIProcessingMS: Int?
    let responseContentType: String?
}

struct InsertionRecord: Decodable {
    let applicationName: String
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

struct AttemptRecord: Decodable {
    let attemptID: UUID
    let completedAt: Date
    let terminalState: TerminalState
    let hotkeyDisplayString: String
    let timing: TimingRecord
    let backend: BackendRecord
    let releaseTimeInsertion: InsertionRecord?
    let insertion: InsertionRecord?
    let failure: FailureRecord?
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

func printLatest(_ record: AttemptRecord) {
    print("Attempt: \(record.attemptID.uuidString)")
    print("Completed: \(record.completedAt.formatted(date: .abbreviated, time: .standard))")
    print("State: \(record.terminalState.rawValue)")
    print("Hotkey: \(record.hotkeyDisplayString)")
    print("Request -> Response: \(record.timing.requestToResponseDurationMS.map { "\($0) ms" } ?? "Unknown")")
    print("Release -> Inserted: \(record.timing.releaseToInsertionDurationMS.map { "\($0) ms" } ?? "Unknown")")
    print("Backend: \(record.backend.identifier ?? "Unknown")")
    print("Mode: \(record.backend.requestMode ?? "Unknown")")
    print("Fallback: \(record.backend.fellBackFromStreaming == true ? "Yes" : "No")")
    print("HTTP Status: \(record.backend.httpStatusCode.map(String.init) ?? "Unknown")")
    print("Request ID: \(record.backend.requestID ?? "Unknown")")
    print("OpenAI Processing: \(record.backend.openAIProcessingMS.map { "\($0) ms" } ?? "Unknown")")
    print("Content Type: \(record.backend.responseContentType ?? "Unknown")")
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
}

func printRecent(_ records: [AttemptRecord]) {
    if records.isEmpty {
        print("No diagnostics records found.")
        return
    }

    for record in records {
        let requestMS = record.timing.requestToResponseDurationMS.map(String.init) ?? "?"
        let insertionMS = record.timing.releaseToInsertionDurationMS.map(String.init) ?? "?"
        let appName = record.insertion?.applicationName ?? "Unknown App"
        let appliedStrategy = record.insertion?.appliedStrategy ?? record.insertion?.chosenStrategy ?? "unknown"
        print("\(record.completedAt.formatted(date: .omitted, time: .standard)) | \(record.terminalState.rawValue) | req \(requestMS) ms | total \(insertionMS) ms | \(appName) | \(appliedStrategy)")
    }
}

func printSummary(_ records: [AttemptRecord]) {
    let requestDurations = records.compactMap(\.timing.requestToResponseDurationMS)
    let releaseToInsertionDurations = records.compactMap(\.timing.releaseToInsertionDurationMS)
    let fallbackCount = records.filter { $0.backend.fellBackFromStreaming == true }.count
    let failureCount = records.filter { $0.terminalState != .inserted }.count

    print("Attempts: \(records.count)")
    print("Failures: \(failureCount)")
    print("Streaming Fallbacks: \(fallbackCount)")
    print("Request -> Response p50: \(percentile(requestDurations, fraction: 0.5).map { "\($0) ms" } ?? "Unknown")")
    print("Request -> Response p95: \(percentile(requestDurations, fraction: 0.95).map { "\($0) ms" } ?? "Unknown")")
    print("Release -> Inserted p50: \(percentile(releaseToInsertionDurations, fraction: 0.5).map { "\($0) ms" } ?? "Unknown")")
    print("Release -> Inserted p95: \(percentile(releaseToInsertionDurations, fraction: 0.95).map { "\($0) ms" } ?? "Unknown")")
}

func usage() {
    print("Usage:")
    print("  Scripts/diagnostics.swift latest")
    print("  Scripts/diagnostics.swift recent [count]")
    print("  Scripts/diagnostics.swift summary [count]")
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
    default:
        usage()
        exit(1)
    }
} catch {
    fputs("Head Canon diagnostics error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
