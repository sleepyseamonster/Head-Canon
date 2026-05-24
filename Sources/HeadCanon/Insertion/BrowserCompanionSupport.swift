import Foundation

enum BrowserHostApplication: String, Codable, Equatable, CaseIterable, Identifiable {
    case chrome
    case arc
    case safari
    case edge
    case brave
    case firefox
    case opera
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chrome:
            "Chrome"
        case .arc:
            "Arc"
        case .safari:
            "Safari"
        case .edge:
            "Edge"
        case .brave:
            "Brave"
        case .firefox:
            "Firefox"
        case .opera:
            "Opera"
        case .other:
            "Other"
        }
    }

    static func detect(bundleIdentifier: String?, applicationName: String) -> BrowserHostApplication? {
        let normalizedBundleID = bundleIdentifier?.lowercased() ?? ""
        let normalizedName = applicationName.lowercased()

        let knownMatches: [(BrowserHostApplication, [String])] = [
            (.chrome, ["com.google.chrome", "chrome"]),
            (.arc, ["company.thebrowser.browser", "arc"]),
            (.safari, ["com.apple.safari", "safari"]),
            (.edge, ["com.microsoft.edgemac", "edge"]),
            (.brave, ["com.brave.browser", "brave"]),
            (.firefox, ["org.mozilla.firefox", "firefox"]),
            (.opera, ["com.operasoftware.opera", "opera"]),
        ]

        for (browser, tokens) in knownMatches {
            if tokens.contains(where: { normalizedBundleID.contains($0) || normalizedName.contains($0) }) {
                return browser
            }
        }

        if normalizedName.contains("browser") {
            return .other
        }

        return nil
    }
}

enum BrowserTargetClass: String, Codable, Equatable, CaseIterable, Identifiable {
    case plainTextControl
    case richEditable
    case framedEditable
    case appWrappedWebEditor
    case unsupportedOrSecure
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plainTextControl:
            "Plain Text Control"
        case .richEditable:
            "Rich Editable"
        case .framedEditable:
            "Framed Editable"
        case .appWrappedWebEditor:
            "App-Wrapped Web Editor"
        case .unsupportedOrSecure:
            "Unsupported Or Secure"
        case .unknown:
            "Unknown"
        }
    }
}

enum BrowserEditorFamily: String, Codable, Equatable, CaseIterable, Identifiable {
    case textInputControl
    case textAreaControl
    case searchField
    case contentEditable
    case frameworkManagedEditor
    case codeEditor
    case secureField
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .textInputControl:
            "Text Input Control"
        case .textAreaControl:
            "Text Area Control"
        case .searchField:
            "Search Field"
        case .contentEditable:
            "Contenteditable Editor"
        case .frameworkManagedEditor:
            "Framework-Managed Editor"
        case .codeEditor:
            "Code Editor"
        case .secureField:
            "Secure Field"
        case .unknown:
            "Unknown"
        }
    }
}

enum BrowserVerificationMode: String, Codable, Equatable, CaseIterable, Identifiable {
    case exactValueReadback
    case transcriptPresenceReadback
    case focusOnly
    case unavailable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exactValueReadback:
            "Exact Value Readback"
        case .transcriptPresenceReadback:
            "Transcript Presence Readback"
        case .focusOnly:
            "Focus-Only Verification"
        case .unavailable:
            "Unavailable"
        }
    }
}

struct BrowserTargetMetadata: Codable, Equatable {
    let browser: BrowserHostApplication
    let targetClass: BrowserTargetClass
    let editorFamily: BrowserEditorFamily
    let verificationMode: BrowserVerificationMode
    let pageOrigin: String?
    let pageTitle: String?
    let framePath: String?
    let frameIdentifier: String?
    let targetFingerprint: String?
    let operationID: UUID?
    let focusCapturedAt: Date?
    let focusValidatedAt: Date?
    let protocolVersion: Int?
    let extensionVersion: String?
}

extension BrowserTargetMetadata {
    func snapshot() -> BrowserCompanionTargetSnapshot {
        BrowserCompanionTargetSnapshot(
            browser: browser,
            pageOrigin: pageOrigin,
            pageTitle: pageTitle,
            framePath: framePath,
            frameIdentifier: frameIdentifier,
            targetClass: targetClass,
            editorFamily: editorFamily,
            targetFingerprint: targetFingerprint,
            editable: verificationMode != .unavailable && targetClass != .unsupportedOrSecure,
            secure: targetClass == .unsupportedOrSecure || editorFamily == .secureField
        )
    }
}

enum BrowserTargetClassifier {
    static func editorFamily(
        role: String?,
        subrole: String?,
        roleDescription: String?,
        title: String?,
        identifier: String?,
        placeholderValue: String?,
        domIdentifier: String?,
        secure: Bool
    ) -> BrowserEditorFamily {
        if secure {
            return .secureField
        }

        let searchable = [
            role,
            subrole,
            roleDescription,
            title,
            identifier,
            placeholderValue,
            domIdentifier,
        ]
        .compactMap { $0?.lowercased() }

        if searchable.contains(where: { $0.contains("search") }) {
            return .searchField
        }

        if searchable.contains(where: { $0.contains("code") || $0.contains("monaco") || $0.contains("codemirror") }) {
            return .codeEditor
        }

        if searchable.contains(where: {
            $0.contains("editor")
                || $0.contains("composer")
                || $0.contains("markdown")
                || $0.contains("prosemirror")
                || $0.contains("slate")
                || $0.contains("lexical")
        }) {
            return .frameworkManagedEditor
        }

        if searchable.contains(where: { $0.contains("contenteditable") || $0.contains("rich text") }) {
            return .contentEditable
        }

        if searchable.contains(where: { $0.contains("textarea") || $0.contains("text area") }) {
            return .textAreaControl
        }

        if searchable.contains(where: {
            $0.contains("text field")
                || $0.contains("textfield")
                || $0.contains("input")
                || $0.contains("field")
        }) {
            return .textInputControl
        }

        return .unknown
    }

    static func targetClass(
        editorFamily: BrowserEditorFamily,
        contextKind: InsertionContextKind,
        secure: Bool
    ) -> BrowserTargetClass {
        if secure || editorFamily == .secureField {
            return .unsupportedOrSecure
        }

        if contextKind == .appOnly {
            return .unknown
        }

        switch editorFamily {
        case .textInputControl, .textAreaControl, .searchField:
            return .plainTextControl
        case .contentEditable, .frameworkManagedEditor, .codeEditor:
            return .richEditable
        case .secureField:
            return .unsupportedOrSecure
        case .unknown:
            return .unknown
        }
    }

    static func verificationMode(
        targetClass: BrowserTargetClass,
        valueReadable: Bool,
        valueSettable: Bool,
        editable: Bool
    ) -> BrowserVerificationMode {
        if targetClass == .plainTextControl && valueReadable && valueSettable {
            return .exactValueReadback
        }

        if editable && valueReadable {
            return .transcriptPresenceReadback
        }

        if editable {
            return .focusOnly
        }

        return .unavailable
    }

    static func fingerprint(
        role: String?,
        title: String?,
        identifier: String?,
        placeholderValue: String?,
        domIdentifier: String?
    ) -> String? {
        let components: [String] = [
            role?.trimmingCharacters(in: .whitespacesAndNewlines),
            title?.trimmingCharacters(in: .whitespacesAndNewlines),
            identifier?.trimmingCharacters(in: .whitespacesAndNewlines),
            placeholderValue?.trimmingCharacters(in: .whitespacesAndNewlines),
            domIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
        ]
        .compactMap { value in
            guard let value, !value.isEmpty else {
                return nil
            }
            return value
        }

        guard !components.isEmpty else {
            return nil
        }

        return components.joined(separator: " | ")
    }
}

enum BrowserCompanionProtocolVersion {
    static let current = 1
}

enum BrowserCompanionCommandKind: String, Codable, Equatable {
    case healthCheck
    case captureFocusedTarget
    case insertTranscript
    case targetSnapshotUpdate
}

enum BrowserCompanionResultKind: String, Codable, Equatable {
    case healthy
    case targetSnapshot
    case inserted
    case unverifiedInsert
    case expired
    case unsupported
    case unavailable
    case failed
}

struct BrowserCompanionTargetSnapshot: Codable, Equatable {
    let browser: BrowserHostApplication
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

struct BrowserCompanionCommandEnvelope: Codable, Equatable {
    let protocolVersion: Int
    let command: BrowserCompanionCommandKind
    let operationID: UUID
    let issuedAt: Date
    let expiresAt: Date?
    let target: BrowserCompanionTargetSnapshot?
    let transcript: String?
}

struct BrowserCompanionResultEnvelope: Codable, Equatable {
    let protocolVersion: Int
    let result: BrowserCompanionResultKind
    let operationID: UUID
    let observedAt: Date
    let target: BrowserCompanionTargetSnapshot?
    let message: String?
}
