import Foundation
import Testing
@testable import HeadCanon

struct BrowserCompanionArtifactTests {
    @Test("Chromium companion manifest declares native messaging and content scripts")
    func chromiumCompanionManifestDeclaresExpectedCapabilities() throws {
        let rootURL = repoRootURL()
        let manifestURL = rootURL
            .appendingPathComponent("BrowserCompanion", isDirectory: true)
            .appendingPathComponent("Chromium", isDirectory: true)
            .appendingPathComponent("manifest.json", isDirectory: false)
        let data = try Data(contentsOf: manifestURL)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        let permissions = try #require(json["permissions"] as? [String])
        let contentScripts = try #require(json["content_scripts"] as? [[String: Any]])
        let background = try #require(json["background"] as? [String: Any])

        #expect(permissions.contains("nativeMessaging"))
        #expect(permissions.contains("scripting"))
        #expect(background["service_worker"] as? String == "background.js")
        #expect(contentScripts.first?["js"] as? [String] == ["content.js"])
    }

    @Test("Browser fixture page includes the planned editor classes")
    func browserFixturePageIncludesPlannedEditorClasses() throws {
        let rootURL = repoRootURL()
        let indexURL = rootURL
            .appendingPathComponent("Support", isDirectory: true)
            .appendingPathComponent("BrowserFixtures", isDirectory: true)
            .appendingPathComponent("index.html", isDirectory: false)
        let html = try String(contentsOf: indexURL, encoding: .utf8)

        #expect(html.contains("fixture-search"))
        #expect(html.contains("fixture-textarea"))
        #expect(html.contains("fixture-composer"))
        #expect(html.contains("headcanon-shadow-editor"))
        #expect(html.contains("fixture-password"))
        #expect(html.contains("iframe-editor.html"))
    }

    @Test("Stub native messaging host answers a health check")
    func stubNativeMessagingHostAnswersAHealthCheck() throws {
        let rootURL = repoRootURL()
        let hostScriptURL = rootURL
            .appendingPathComponent("Scripts", isDirectory: true)
            .appendingPathComponent("browser_companion_host.sh", isDirectory: false)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [hostScriptURL.path]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let command = BrowserCompanionCommandEnvelope(
            protocolVersion: BrowserCompanionProtocolVersion.current,
            command: .healthCheck,
            operationID: UUID(),
            issuedAt: Date(timeIntervalSince1970: 1_000),
            expiresAt: nil,
            target: nil,
            transcript: nil
        )
        let payload = try encoder.encode(command)
        var payloadLength = UInt32(payload.count).littleEndian
        let lengthData = Data(bytes: &payloadLength, count: MemoryLayout<UInt32>.size)

        try stdinPipe.fileHandleForWriting.write(contentsOf: lengthData)
        try stdinPipe.fileHandleForWriting.write(contentsOf: payload)
        try stdinPipe.fileHandleForWriting.close()

        let lengthResponse = try #require(try stdoutPipe.fileHandleForReading.read(upToCount: 4))
        #expect(lengthResponse.count == 4)
        let messageLength = lengthResponse.withUnsafeBytes { rawBuffer in
            rawBuffer.load(as: UInt32.self)
        }
        let payloadResponse = try #require(
            try stdoutPipe.fileHandleForReading.read(upToCount: Int(UInt32(littleEndian: messageLength)))
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(BrowserCompanionResultEnvelope.self, from: payloadResponse)

        #expect(response.result == .healthy)
        #expect(response.operationID == command.operationID)
        #expect(response.protocolVersion == BrowserCompanionProtocolVersion.current)

        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }

    private func repoRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
