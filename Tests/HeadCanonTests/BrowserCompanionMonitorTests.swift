import Foundation
import Testing
@testable import HeadCanon

struct BrowserCompanionMonitorTests {
    @Test("Browser companion monitor detects an installed Chrome manifest and extension ID")
    func browserCompanionMonitorDetectsInstalledChromeManifest() throws {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: tempDirectory)
        }

        let manifestDirectory = tempDirectory
            .appendingPathComponent("Library/Application Support/Google/Chrome/NativeMessagingHosts", isDirectory: true)
        try fileManager.createDirectory(at: manifestDirectory, withIntermediateDirectories: true)

        let hostScriptURL = tempDirectory.appendingPathComponent("browser_companion_host.sh", isDirectory: false)
        try "#!/bin/zsh\nexit 0\n".write(to: hostScriptURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hostScriptURL.path)

        let manifestURL = manifestDirectory
            .appendingPathComponent("\(BrowserCompanionMonitor.nativeHostName).json", isDirectory: false)
        let manifest = """
        {
          "name": "\(BrowserCompanionMonitor.nativeHostName)",
          "description": "Head Canon local Chromium companion host scaffold",
          "path": "\(hostScriptURL.path)",
          "type": "stdio",
          "allowed_origins": [
            "chrome-extension://abcdefghijklmnopabcdefghijklmnop/"
          ]
        }
        """
        try manifest.write(to: manifestURL, atomically: true, encoding: .utf8)

        let monitor = BrowserCompanionMonitor(
            fileManager: fileManager,
            homeDirectoryURL: tempDirectory
        )
        let status = monitor.currentStatus()
        let chromeInstallation = try #require(status.installations.first(where: { $0.browser == .chrome }))

        #expect(status.anyInstalled)
        #expect(status.statusTitle == "Installed")
        #expect(chromeInstallation.isInstalled)
        #expect(chromeInstallation.hostScriptReachable)
        #expect(chromeInstallation.allowedExtensionIDs == ["abcdefghijklmnopabcdefghijklmnop"])
    }

    @Test("Browser companion monitor reports not installed when manifests are absent")
    func browserCompanionMonitorReportsNotInstalledWhenMissing() throws {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: tempDirectory)
        }

        let monitor = BrowserCompanionMonitor(
            fileManager: fileManager,
            homeDirectoryURL: tempDirectory
        )
        let status = monitor.currentStatus()

        #expect(!status.anyInstalled)
        #expect(status.statusTitle == "Not Installed")
        #expect(status.installations.contains(where: { $0.browser == .chrome }))
    }
}
