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
    let verificationOutcome: String?
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

struct LiveEventRecord: Decodable {
    let timestamp: Date
    let summary: String
    let stage: String?
    let isFailure: Bool
}

struct LiveTimingRecord: Decodable {
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

struct LiveStateRecord: Decodable {
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
    let lastEvent: LiveEventRecord?
    let recentEvents: [LiveEventRecord]
    let recordingTiming: LiveTimingRecord?
}

struct AttemptRecord: Decodable {
    let attemptID: UUID
    let completedAt: Date
    let terminalState: TerminalState
    let truthState: String?
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

func loadLiveState(from directoryURL: URL) throws -> LiveStateRecord {
    let liveURL = directoryURL.appendingPathComponent("live-state.json", isDirectory: false)
    guard FileManager.default.fileExists(atPath: liveURL.path) else {
        throw NSError(domain: "HeadCanonDiagnostics", code: 3, userInfo: [NSLocalizedDescriptionKey: "No live diagnostics state found yet."])
    }
    let data = try Data(contentsOf: liveURL)
    return try decoder.decode(LiveStateRecord.self, from: data)
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
    inferredTruthState(for: record)
}

func inferredTruthState(for record: AttemptRecord) -> String {
    if let truthState = record.truthState {
        return truthState
    }

    switch record.terminalState {
    case .inserted:
        if insertionRecord(for: record)?.verificationOutcome == "unverified" {
            return "unverifiedInsert"
        }
        return "verifiedInsert"
    case .timedOut:
        return "transcriptionTimedOut"
    case .canceled:
        return "transcriptionCanceled"
    case .failed:
        break
    }

    guard let failure = record.failure else {
        return record.terminalState.rawValue
    }

    switch failure.stage {
    case "permissionReadiness":
        return "setupBlocked"
    case "recordingStart", "recordingStop":
        return "recordingFailed"
    case "transcription":
        if record.backend.transportFailureStage != nil
            || record.backend.networkErrorDomain != nil
            || record.backend.networkErrorCode != nil
        {
            return "transcriptionTransportFailure"
        }
        return "transcriptionFailed"
    case "insertion":
        let message = failure.message.lowercased()
        if message.contains("focus") && message.contains("changed") {
            return "focusChanged"
        }
        if message.contains("secure")
            || message.contains("unsafe")
            || message.contains("placeholder")
        {
            return "safetyBlock"
        }
        if message.contains("unsupported")
            || message.contains("paste fallback")
        {
            return "unsupportedTarget"
        }
        if message.contains("accessibility") && message.contains("permission") {
            return "setupBlocked"
        }
        return "insertionFailed"
    default:
        return record.terminalState.rawValue
    }
}

func isVerifiedSuccess(for record: AttemptRecord) -> Bool {
    inferredTruthState(for: record) == "verifiedInsert"
}

func isUnverifiedInsert(for record: AttemptRecord) -> Bool {
    inferredTruthState(for: record) == "unverifiedInsert"
}

func isFailure(for record: AttemptRecord) -> Bool {
    !isVerifiedSuccess(for: record) && !isUnverifiedInsert(for: record)
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
    let verifiedCount = records.filter(isVerifiedSuccess).count
    let unverifiedCount = records.filter(isUnverifiedInsert).count
    let failureCount = records.filter(isFailure).count

    return [
        "Attempts: \(records.count)",
        "Verified Inserts: \(verifiedCount)",
        "Unverified Inserts: \(unverifiedCount)",
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
    print("Truth State: \(inferredTruthState(for: record))")
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
        print("Verification: \(insertion.verificationOutcome ?? "Unknown")")
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

func printLive(_ record: LiveStateRecord) {
    print("Updated: \(record.updatedAt.formatted(date: .abbreviated, time: .standard))")
    print("Session: \(record.sessionID.uuidString)")
    print("Current Attempt: \(record.currentAttemptID?.uuidString ?? "None")")
    print("Workflow: \(record.workflowStatusTitle) (\(record.workflowStatus))")
    print("Ready: \(record.isReady ? "Yes" : "No")")
    print("Audio Capture Recording: \(record.audioCaptureIsRecording ? "Yes" : "No")")
    print("Hotkey: \(record.hotkeyDisplayString)")
    print("Hotkey Physically Pressed: \(record.hotkeyPhysicallyPressed ? "Yes" : "No")")
    print("Active Transcription: \(record.activeTranscriptionAttemptID?.uuidString ?? "None")")
    print("Last Failure Stage: \(record.lastFailureStage ?? "None")")
    print("Last Truth State: \(record.lastTruthState ?? "None")")
    print("Last Error: \(record.lastErrorMessage ?? "None")")

    if let timing = record.recordingTiming {
        print("Recording Started: \(timing.recordingStartedAt?.formatted(date: .omitted, time: .standard) ?? "Unknown")")
        print("Hotkey Released: \(timing.hotkeyReleasedAt?.formatted(date: .omitted, time: .standard) ?? "Unknown")")
        print("Finalizing Shown: \(timing.finalizingStateShownAt?.formatted(date: .omitted, time: .standard) ?? "Unknown")")
        print("Recording Finalized: \(timing.recordingFinalizedAt?.formatted(date: .omitted, time: .standard) ?? "Unknown")")
        print("Transcription Started: \(timing.transcriptionRequestStartedAt?.formatted(date: .omitted, time: .standard) ?? "Unknown")")
        print("Insertion Completed: \(timing.insertionCompletedAt?.formatted(date: .omitted, time: .standard) ?? "Unknown")")
        print("Stop Trigger: \(timing.stopTrigger ?? "Unknown")")
    } else {
        print("Recording Timing: None")
    }

    if let event = record.lastEvent {
        print("Last Event: \(event.summary)")
        print("Last Event Stage: \(event.stage ?? "None")")
        print("Last Event Failed: \(event.isFailure ? "Yes" : "No")")
        print("Last Event At: \(event.timestamp.formatted(date: .omitted, time: .standard))")
    } else {
        print("Last Event: None")
    }

    if !record.recentEvents.isEmpty {
        print("Recent Events:")
        for event in record.recentEvents.prefix(8) {
            let stage = event.stage ?? "none"
            print("- \(event.timestamp.formatted(date: .omitted, time: .standard)) | \(stage) | \(event.isFailure ? "failure" : "info") | \(event.summary)")
        }
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
        print("\(record.completedAt.formatted(date: .omitted, time: .standard)) | \(failureLabel(for: record)) | req \(requestMS) ms | hdr \(headerMS) ms | total \(insertionMS) ms | chars \(characterCount) | \(appClass(for: record).rawValue) | \(appName) | \(appliedStrategy) | net \(netCode)")
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
    let failures = records.filter(isFailure)

    if failures.isEmpty {
        print(records.isEmpty ? "No diagnostics records found." : "No failure records found.")
        return
    }

    let grouped = Dictionary(grouping: failures, by: failureLabel)

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
    print("  Scripts/diagnostics.swift live")
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
    case "live":
        printLive(try loadLiveState(from: directoryURL))
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
