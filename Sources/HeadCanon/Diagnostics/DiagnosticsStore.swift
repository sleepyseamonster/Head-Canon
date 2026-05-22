import Foundation

protocol DiagnosticsStoring: Sendable {
    func persist(_ record: DictationAttemptRecord) async throws
    func persistLiveState(_ record: LiveDiagnosticsRecord) async throws
    func clear() async throws
    func diagnosticsDirectoryURL() async throws -> URL
}

enum DiagnosticsStoreError: LocalizedError, Equatable {
    case applicationSupportUnavailable

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            "Application Support is unavailable."
        }
    }
}

actor DiagnosticsStore: DiagnosticsStoring {
    private let fileManager: FileManager
    private let appSupportDirectoryURL: URL?
    private let maxLogFileBytes: Int
    private let maxRotatedFiles: Int
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default,
        appSupportDirectoryURL: URL? = nil,
        maxLogFileBytes: Int = 512_000,
        maxRotatedFiles: Int = 4
    ) {
        self.fileManager = fileManager
        self.appSupportDirectoryURL = appSupportDirectoryURL
        self.maxLogFileBytes = maxLogFileBytes
        self.maxRotatedFiles = maxRotatedFiles

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func persist(_ record: DictationAttemptRecord) async throws {
        let directoryURL = try resolvedDiagnosticsDirectoryURL(createIfNeeded: true)
        let attemptsURL = directoryURL.appendingPathComponent("attempts.jsonl", isDirectory: false)
        let latestURL = directoryURL.appendingPathComponent("latest.json", isDirectory: false)
        let payload = try encoder.encode(record)
        let newline = Data([0x0A])
        let line = payload + newline

        try rotateIfNeeded(appendingBytes: line.count, attemptsURL: attemptsURL, directoryURL: directoryURL)
        try append(line, to: attemptsURL)
        try payload.write(to: latestURL, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: latestURL.path)
    }

    func persistLiveState(_ record: LiveDiagnosticsRecord) async throws {
        let directoryURL = try resolvedDiagnosticsDirectoryURL(createIfNeeded: true)
        let liveURL = directoryURL.appendingPathComponent("live-state.json", isDirectory: false)
        let payload = try encoder.encode(record)
        try payload.write(to: liveURL, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: liveURL.path)
    }

    func clear() async throws {
        let directoryURL = try resolvedDiagnosticsDirectoryURL(createIfNeeded: false)

        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    func diagnosticsDirectoryURL() async throws -> URL {
        try resolvedDiagnosticsDirectoryURL(createIfNeeded: true)
    }

    func latestRecord() async throws -> DictationAttemptRecord? {
        let latestURL = try resolvedDiagnosticsDirectoryURL(createIfNeeded: false)
            .appendingPathComponent("latest.json", isDirectory: false)

        guard fileManager.fileExists(atPath: latestURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: latestURL)
        return try decoder.decode(DictationAttemptRecord.self, from: data)
    }

    private func resolvedDiagnosticsDirectoryURL(createIfNeeded: Bool) throws -> URL {
        let baseURL: URL
        if let appSupportDirectoryURL {
            baseURL = appSupportDirectoryURL
        } else if let discoveredURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            baseURL = discoveredURL
        } else {
            throw DiagnosticsStoreError.applicationSupportUnavailable
        }

        let directoryURL = baseURL
            .appendingPathComponent("HeadCanon", isDirectory: true)
            .appendingPathComponent("diagnostics", isDirectory: true)

        if createIfNeeded {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }

        return directoryURL
    }

    private func append(_ data: Data, to fileURL: URL) throws {
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: data)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
            return
        }

        let handle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? handle.close()
        }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }

    private func rotateIfNeeded(appendingBytes: Int, attemptsURL: URL, directoryURL: URL) throws {
        guard fileManager.fileExists(atPath: attemptsURL.path) else {
            return
        }

        let attributes = try fileManager.attributesOfItem(atPath: attemptsURL.path)
        let currentSize = (attributes[.size] as? NSNumber)?.intValue ?? 0

        guard currentSize + appendingBytes > maxLogFileBytes else {
            return
        }

        let oldestURL = directoryURL.appendingPathComponent("attempts-\(maxRotatedFiles).jsonl", isDirectory: false)
        if fileManager.fileExists(atPath: oldestURL.path) {
            try fileManager.removeItem(at: oldestURL)
        }

        if maxRotatedFiles > 1 {
            for index in stride(from: maxRotatedFiles - 1, through: 1, by: -1) {
                let sourceURL = directoryURL.appendingPathComponent("attempts-\(index).jsonl", isDirectory: false)
                let destinationURL = directoryURL.appendingPathComponent("attempts-\(index + 1).jsonl", isDirectory: false)
                guard fileManager.fileExists(atPath: sourceURL.path) else {
                    continue
                }
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: sourceURL, to: destinationURL)
            }
        }

        let rotatedURL = directoryURL.appendingPathComponent("attempts-1.jsonl", isDirectory: false)
        if fileManager.fileExists(atPath: rotatedURL.path) {
            try fileManager.removeItem(at: rotatedURL)
        }
        try fileManager.moveItem(at: attemptsURL, to: rotatedURL)
    }
}
