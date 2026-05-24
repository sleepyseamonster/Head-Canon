import Foundation

struct BrowserCompanionInstallation: Codable, Equatable, Sendable, Identifiable {
    let browser: BrowserHostApplication
    let nativeHostManifestPath: String?
    let hostScriptPath: String?
    let hostScriptReachable: Bool
    let allowedExtensionIDs: [String]

    var id: String { browser.rawValue }

    var isInstalled: Bool {
        nativeHostManifestPath != nil
    }

    var title: String {
        browser.title
    }

    var detail: String {
        if let nativeHostManifestPath {
            let extensions = allowedExtensionIDs.isEmpty ? "no extension IDs" : allowedExtensionIDs.joined(separator: ", ")
            return "Manifest: \(nativeHostManifestPath) · Extensions: \(extensions)"
        }
        return "No native host manifest installed."
    }
}

struct BrowserCompanionObservedSnapshot: Codable, Equatable, Sendable {
    let browser: BrowserHostApplication
    let observedAt: Date
    let pageOrigin: String?
    let pageTitle: String?
    let framePath: String?
    let frameIdentifier: String?
    let targetClass: BrowserTargetClass
    let editorFamily: BrowserEditorFamily
    let targetFingerprint: String?
    let editable: Bool
    let secure: Bool
}

struct BrowserCompanionStatus: Codable, Equatable, Sendable {
    let checkedAt: Date
    let protocolVersion: Int
    let installations: [BrowserCompanionInstallation]
    let latestSnapshot: BrowserCompanionObservedSnapshot?

    static var empty: BrowserCompanionStatus {
        BrowserCompanionStatus(
            checkedAt: .distantPast,
            protocolVersion: BrowserCompanionProtocolVersion.current,
            installations: [],
            latestSnapshot: nil
        )
    }

    var anyInstalled: Bool {
        installations.contains(where: \.isInstalled)
    }

    var installedBrowsers: [BrowserHostApplication] {
        installations.filter(\.isInstalled).map(\.browser)
    }

    var statusTitle: String {
        anyInstalled ? "Installed" : "Not Installed"
    }

    var statusDetail: String {
        let installed = installations.filter(\.isInstalled)
        guard !installed.isEmpty else {
            return "No Chromium browser companion native host manifests were found."
        }

        let browserLabels = installed.map(\.title).joined(separator: ", ")
        return "Native host manifests detected for \(browserLabels)."
    }
}

protocol BrowserCompanionMonitoring {
    func currentStatus() -> BrowserCompanionStatus
}

struct BrowserCompanionMonitor: BrowserCompanionMonitoring {
    static let nativeHostName = "local.headcanon.browser_companion"

    private let fileManager: FileManager
    private let homeDirectoryURL: URL

    init(
        fileManager: FileManager = .default,
        homeDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.homeDirectoryURL = homeDirectoryURL ?? fileManager.homeDirectoryForCurrentUser
    }

    func currentStatus() -> BrowserCompanionStatus {
        let installations = BrowserHostApplication.allCases
            .filter { $0 != .safari && $0 != .firefox && $0 != .opera && $0 != .other }
            .map(installation(for:))

        return BrowserCompanionStatus(
            checkedAt: Date(),
            protocolVersion: BrowserCompanionProtocolVersion.current,
            installations: installations,
            latestSnapshot: latestSnapshot()
        )
    }

    private func installation(for browser: BrowserHostApplication) -> BrowserCompanionInstallation {
        guard let manifestURL = manifestURL(for: browser) else {
            return BrowserCompanionInstallation(
                browser: browser,
                nativeHostManifestPath: nil,
                hostScriptPath: nil,
                hostScriptReachable: false,
                allowedExtensionIDs: []
            )
        }

        guard
            fileManager.fileExists(atPath: manifestURL.path),
            let data = try? Data(contentsOf: manifestURL),
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return BrowserCompanionInstallation(
                browser: browser,
                nativeHostManifestPath: nil,
                hostScriptPath: nil,
                hostScriptReachable: false,
                allowedExtensionIDs: []
            )
        }

        let hostScriptPath = jsonObject["path"] as? String
        let hostScriptReachable = hostScriptPath.map { fileManager.isExecutableFile(atPath: $0) } ?? false
        let extensionIDs = (jsonObject["allowed_origins"] as? [String] ?? [])
            .compactMap(Self.extensionID(fromAllowedOrigin:))

        return BrowserCompanionInstallation(
            browser: browser,
            nativeHostManifestPath: manifestURL.path,
            hostScriptPath: hostScriptPath,
            hostScriptReachable: hostScriptReachable,
            allowedExtensionIDs: extensionIDs
        )
    }

    private func manifestURL(for browser: BrowserHostApplication) -> URL? {
        guard let relativeDirectory = relativeManifestDirectory(for: browser) else {
            return nil
        }

        return homeDirectoryURL
            .appendingPathComponent(relativeDirectory, isDirectory: true)
            .appendingPathComponent("\(Self.nativeHostName).json", isDirectory: false)
    }

    private func relativeManifestDirectory(for browser: BrowserHostApplication) -> String? {
        switch browser {
        case .chrome:
            "Library/Application Support/Google/Chrome/NativeMessagingHosts"
        case .arc:
            "Library/Application Support/Arc/NativeMessagingHosts"
        case .edge:
            "Library/Application Support/Microsoft Edge/NativeMessagingHosts"
        case .brave:
            "Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
        case .safari, .firefox, .opera, .other:
            nil
        }
    }

    private static func extensionID(fromAllowedOrigin origin: String) -> String? {
        guard origin.hasPrefix("chrome-extension://"), origin.hasSuffix("/") else {
            return nil
        }

        return origin
            .replacingOccurrences(of: "chrome-extension://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func latestSnapshot() -> BrowserCompanionObservedSnapshot? {
        let snapshotURL = homeDirectoryURL
            .appendingPathComponent("Library/Application Support/HeadCanon/browser-companion", isDirectory: true)
            .appendingPathComponent("latest-target.json", isDirectory: false)

        guard
            fileManager.fileExists(atPath: snapshotURL.path),
            let data = try? Data(contentsOf: snapshotURL)
        else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BrowserCompanionObservedSnapshot.self, from: data)
    }
}
