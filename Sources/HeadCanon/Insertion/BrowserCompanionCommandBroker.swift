import Foundation

@MainActor
protocol BrowserCompanionCommandBrokering {
    func captureFocusedTarget(timeout: Duration) async -> BrowserCompanionResultEnvelope?
    func insertTranscript(
        _ transcript: String,
        target: BrowserCompanionTargetSnapshot,
        timeout: Duration
    ) async -> BrowserCompanionResultEnvelope?
}

@MainActor
struct BrowserCompanionCommandBroker: BrowserCompanionCommandBrokering {
    private let fileManager: FileManager
    private let homeDirectoryURL: URL

    init(
        fileManager: FileManager = .default,
        homeDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.homeDirectoryURL = homeDirectoryURL ?? fileManager.homeDirectoryForCurrentUser
    }

    func captureFocusedTarget(timeout: Duration = .seconds(2)) async -> BrowserCompanionResultEnvelope? {
        let command = BrowserCompanionCommandEnvelope(
            protocolVersion: BrowserCompanionProtocolVersion.current,
            command: .captureFocusedTarget,
            operationID: UUID(),
            issuedAt: Date(),
            expiresAt: Date().addingTimeInterval(5),
            target: nil,
            transcript: nil
        )
        return await send(command, timeout: timeout)
    }

    func insertTranscript(
        _ transcript: String,
        target: BrowserCompanionTargetSnapshot,
        timeout: Duration = .seconds(3)
    ) async -> BrowserCompanionResultEnvelope? {
        let command = BrowserCompanionCommandEnvelope(
            protocolVersion: BrowserCompanionProtocolVersion.current,
            command: .insertTranscript,
            operationID: UUID(),
            issuedAt: Date(),
            expiresAt: Date().addingTimeInterval(8),
            target: target,
            transcript: transcript
        )
        return await send(command, timeout: timeout)
    }

    private func send(
        _ command: BrowserCompanionCommandEnvelope,
        timeout: Duration
    ) async -> BrowserCompanionResultEnvelope? {
        let paths = paths()

        do {
            try ensureDirectories(paths)
            let commandURL = paths.commandsDirectory
                .appendingPathComponent("\(command.operationID.uuidString).json", isDirectory: false)
            let inflightURL = paths.inflightDirectory
                .appendingPathComponent("\(command.operationID.uuidString).json", isDirectory: false)
            let resultURL = paths.resultsDirectory
                .appendingPathComponent("\(command.operationID.uuidString).json", isDirectory: false)

            try? fileManager.removeItem(at: resultURL)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = try encoder.encode(command)
            try payload.write(to: commandURL, options: [.atomic])
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: commandURL.path)

            let start = ContinuousClock.now
            while start.duration(to: .now) < timeout {
                if
                    fileManager.fileExists(atPath: resultURL.path),
                    let data = try? Data(contentsOf: resultURL)
                {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try? decoder.decode(BrowserCompanionResultEnvelope.self, from: data)
                    try? fileManager.removeItem(at: resultURL)
                    return result
                }

                try? await Task.sleep(for: .milliseconds(60))
            }

            try? fileManager.removeItem(at: commandURL)
            try? fileManager.removeItem(at: inflightURL)
            return nil
        } catch {
            return nil
        }
    }

    private func ensureDirectories(_ paths: BrowserCompanionCommandPaths) throws {
        try [
            paths.baseDirectory,
            paths.commandsDirectory,
            paths.inflightDirectory,
            paths.resultsDirectory,
        ].forEach { directory in
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }
    }

    private func paths() -> BrowserCompanionCommandPaths {
        let baseDirectory = homeDirectoryURL
            .appendingPathComponent("Library/Application Support/HeadCanon/browser-companion", isDirectory: true)
        return BrowserCompanionCommandPaths(
            baseDirectory: baseDirectory,
            commandsDirectory: baseDirectory.appendingPathComponent("commands", isDirectory: true),
            inflightDirectory: baseDirectory.appendingPathComponent("inflight", isDirectory: true),
            resultsDirectory: baseDirectory.appendingPathComponent("results", isDirectory: true)
        )
    }
}

private struct BrowserCompanionCommandPaths {
    let baseDirectory: URL
    let commandsDirectory: URL
    let inflightDirectory: URL
    let resultsDirectory: URL
}
