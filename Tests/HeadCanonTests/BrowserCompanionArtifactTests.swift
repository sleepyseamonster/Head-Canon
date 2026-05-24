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

    @Test("Safari companion scaffold declares the shared fixture coverage and truth-state model")
    func safariCompanionScaffoldDeclaresExpectedCapabilities() throws {
        let rootURL = repoRootURL()
        let manifestURL = rootURL
            .appendingPathComponent("BrowserCompanion", isDirectory: true)
            .appendingPathComponent("Safari", isDirectory: true)
            .appendingPathComponent("manifest.json", isDirectory: false)
        let contentURL = rootURL
            .appendingPathComponent("BrowserCompanion", isDirectory: true)
            .appendingPathComponent("Safari", isDirectory: true)
            .appendingPathComponent("content.js", isDirectory: false)
        let backgroundURL = rootURL
            .appendingPathComponent("BrowserCompanion", isDirectory: true)
            .appendingPathComponent("Safari", isDirectory: true)
            .appendingPathComponent("background.js", isDirectory: false)

        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try #require(JSONSerialization.jsonObject(with: manifestData) as? [String: Any])
        let permissions = try #require(manifest["permissions"] as? [String])
        let contentScripts = try #require(manifest["content_scripts"] as? [[String: Any]])
        let background = try #require(manifest["background"] as? [String: Any])
        let content = try String(contentsOf: contentURL, encoding: .utf8)
        let backgroundSource = try String(contentsOf: backgroundURL, encoding: .utf8)

        #expect(!permissions.contains("nativeMessaging"))
        #expect(permissions.contains("storage"))
        #expect(background["service_worker"] as? String == "background.js")
        #expect(contentScripts.first?["js"] as? [String] == ["content.js"])
        #expect(content.contains("result: \"inserted\""))
        #expect(content.contains("result: \"unverifiedInsert\""))
        #expect(content.contains("result: \"expired\""))
        #expect(content.contains("result: \"unsupported\""))
        #expect(backgroundSource.contains("headCanonLatestTargetSnapshot"))
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

    @Test("Chromium fixture matrix runner is present")
    func chromiumFixtureMatrixRunnerIsPresent() {
        let rootURL = repoRootURL()
        let scriptURL = rootURL
            .appendingPathComponent("Scripts", isDirectory: true)
            .appendingPathComponent("run_chromium_fixture_matrix.sh", isDirectory: false)

        #expect(FileManager.default.fileExists(atPath: scriptURL.path))
    }

    @Test("Stub native messaging host answers a health check")
    func stubNativeMessagingHostAnswersAHealthCheck() throws {
        let rootURL = repoRootURL()
        let hostScriptURL = rootURL
            .appendingPathComponent("Scripts", isDirectory: true)
            .appendingPathComponent("browser_companion_host.sh", isDirectory: false)

        let tempHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeadCanonBrowserHostHealthHome-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempHome, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempHome)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [hostScriptURL.path]
        process.environment = [
            "HOME": tempHome.path
        ]

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

    @Test("Stub native messaging host persists a browser target snapshot update")
    func stubNativeMessagingHostPersistsBrowserTargetSnapshotUpdate() throws {
        let rootURL = repoRootURL()
        let hostScriptURL = rootURL
            .appendingPathComponent("Scripts", isDirectory: true)
            .appendingPathComponent("browser_companion_host.sh", isDirectory: false)

        let tempHome = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeadCanonBrowserHostHome-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempHome, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempHome)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [hostScriptURL.path]
        process.environment = [
            "HOME": tempHome.path
        ]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        try process.run()

        let payloadObject: [String: Any] = [
            "protocolVersion": BrowserCompanionProtocolVersion.current,
            "command": BrowserCompanionCommandKind.targetSnapshotUpdate.rawValue,
            "operationID": UUID().uuidString,
            "issuedAt": "2026-05-23T18:00:00Z",
            "expiresAt": NSNull(),
            "target": [
                "browser": "chrome",
                "pageOrigin": "http://127.0.0.1:47831",
                "pageTitle": "Head Canon Browser Fixtures",
                "framePath": "0",
                "frameIdentifier": "root",
                "targetClass": "richEditable",
                "editorFamily": "contentEditable",
                "targetFingerprint": "div | textbox | Fixture Composer",
                "editable": true,
                "secure": false
            ],
            "transcript": NSNull()
        ]
        let payload = try JSONSerialization.data(withJSONObject: payloadObject, options: [.sortedKeys])
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

        #expect(response.result == .targetSnapshot)

        let snapshotURL = tempHome
            .appendingPathComponent("Library/Application Support/HeadCanon/browser-companion", isDirectory: true)
            .appendingPathComponent("latest-target.json", isDirectory: false)
        let snapshotData = try Data(contentsOf: snapshotURL)
        let snapshot = try decoder.decode(BrowserCompanionObservedSnapshot.self, from: snapshotData)

        #expect(snapshot.browser == .chrome)
        #expect(snapshot.pageOrigin == "http://127.0.0.1:47831")
        #expect(snapshot.targetClass == .richEditable)
        #expect(snapshot.editorFamily == .contentEditable)

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
