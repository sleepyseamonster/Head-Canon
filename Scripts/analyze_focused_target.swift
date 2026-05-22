#!/usr/bin/env swift

import AppKit
import ApplicationServices
import Foundation

struct SecureTextFieldMetadata {
    let role: String?
    let subrole: String?
    let roleDescription: String?
    let title: String?
    let description: String?
    let identifier: String?
    let placeholderValue: String?
    let domIdentifier: String?

    var searchableValues: [String] {
        [
            role,
            subrole,
            roleDescription,
            title,
            description,
            identifier,
            placeholderValue,
            domIdentifier,
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    }
}

enum SecureTextFieldClassifier {
    private static let explicitSecureSubroles = Set([
        kAXSecureTextFieldSubrole as String,
    ])

    private static let sensitiveTerms = [
        "password",
        "passcode",
        "pin",
        "otp",
        "one-time code",
        "one time code",
        "verification code",
        "security code",
        "cvv",
        "cvc",
    ]

    private static let editableHints = [
        "text",
        "field",
        "input",
        "editor",
        "editable",
        "search",
        "combo",
        "web",
    ]

    static func isSecure(_ metadata: SecureTextFieldMetadata) -> Bool {
        if let subrole = metadata.subrole, explicitSecureSubroles.contains(subrole) {
            return true
        }

        let normalizedValues = metadata.searchableValues.map { $0.lowercased() }
        guard !normalizedValues.isEmpty else {
            return false
        }

        if normalizedValues.contains(where: { $0.contains("secure text field") }) {
            return true
        }

        let containsSensitiveTerm = normalizedValues.contains(where: containsSensitiveTerm(_:))
        guard containsSensitiveTerm else {
            return false
        }

        return normalizedValues.contains(where: containsEditableHint(_:))
    }

    private static func containsSensitiveTerm(_ value: String) -> Bool {
        sensitiveTerms.contains { value.contains($0) }
    }

    private static func containsEditableHint(_ value: String) -> Bool {
        editableHints.contains { value.contains($0) }
    }
}

enum InsertionStrategy: String {
    case axValueReplacement
    case customEditorPaste
    case pasteFallback
    case appClipboardPaste
    case unsupported
}

enum InsertionContextKind: String, Codable {
    case axFocusedElement
    case appOnly
}

enum ApplicationCapabilityProfile: String, Codable {
    case nativeAXStrong
    case partialAXEditor
    case opaquePasteCapable
    case unknownConservative
}

struct StrategyRejection: Codable {
    let strategy: String
    let reason: String
}

struct FocusedTargetReport: Codable {
    let observedAt: String
    let applicationName: String
    let bundleIdentifier: String?
    let processIdentifier: Int32
    let contextKind: InsertionContextKind
    let capabilityProfile: ApplicationCapabilityProfile
    let role: String?
    let subrole: String?
    let roleDescription: String?
    let title: String?
    let identifier: String?
    let placeholderValue: String?
    let domIdentifier: String?
    let valueReadable: Bool
    let valueSettable: Bool
    let selectedTextRangeReadable: Bool
    let selectedTextReadable: Bool
    let editable: Bool
    let secure: Bool
    let pasteCompatible: Bool
    let directInsertCompatible: Bool
    let appLevelPasteOnly: Bool
    let allowPasteFallback: Bool
    let chosenStrategy: String
    let predictedFailureClass: String?
    let strategyReason: String
    let rejectedStrategies: [StrategyRejection]
}

enum FocusedTargetError: LocalizedError {
    case focusUnavailable
    case accessibilityPermissionRequired
    case accessibilityAPIError(String)

    var errorDescription: String? {
        switch self {
        case .focusUnavailable:
            return "Could not find a focused editable target."
        case .accessibilityPermissionRequired:
            return "Accessibility access is required to inspect the focused app."
        case .accessibilityAPIError(let message):
            return message
        }
    }
}

func copyAttribute(_ attribute: String, from element: AXUIElement) throws -> CFTypeRef? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

    switch result {
    case .success:
        return value
    case .apiDisabled:
        throw FocusedTargetError.accessibilityPermissionRequired
    case .noValue, .attributeUnsupported:
        return nil
    default:
        throw FocusedTargetError.accessibilityAPIError(
            "Accessibility read failed for \(attribute) with AX error \(result.rawValue)."
        )
    }
}

func copyAXUIElementAttribute(_ attribute: String, from element: AXUIElement) throws -> AXUIElement? {
    guard
        let value = try copyAttribute(attribute, from: element),
        CFGetTypeID(value) == AXUIElementGetTypeID()
    else {
        return nil
    }

    return unsafeDowncast(value, to: AXUIElement.self)
}

func copyStringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
    (try? copyAttribute(attribute, from: element)) as? String
}

func isAttributeSettable(_ attribute: String, on element: AXUIElement) -> Bool {
    var settable = DarwinBoolean(false)
    let result = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
    return result == .success && settable.boolValue
}

func metadata(for element: AXUIElement) -> SecureTextFieldMetadata {
    SecureTextFieldMetadata(
        role: copyStringAttribute(kAXRoleAttribute, from: element),
        subrole: copyStringAttribute(kAXSubroleAttribute, from: element),
        roleDescription: copyStringAttribute(kAXRoleDescriptionAttribute, from: element),
        title: copyStringAttribute(kAXTitleAttribute, from: element),
        description: copyStringAttribute(kAXDescriptionAttribute, from: element),
        identifier: copyStringAttribute(kAXIdentifierAttribute, from: element),
        placeholderValue: copyStringAttribute(kAXPlaceholderValueAttribute, from: element),
        domIdentifier: copyStringAttribute("AXDOMIdentifier", from: element)
    )
}

func isEditableTarget(
    role: String?,
    subrole: String?,
    roleDescription: String?,
    title: String?,
    identifier: String?,
    placeholderValue: String?,
    domIdentifier: String?,
    valueReadable: Bool,
    valueSettable: Bool,
    selectedTextRangeReadable: Bool,
    selectedTextReadable: Bool
) -> Bool {
    if valueSettable || selectedTextRangeReadable || selectedTextReadable {
        return true
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

    let editableTerms = [
        "text",
        "field",
        "area",
        "editor",
        "editable",
        "search",
        "code",
        "markdown",
        "composer",
        "input",
    ]

    if searchable.contains(where: { value in
        editableTerms.contains(where: { value.contains($0) })
    }) {
        return true
    }

    return valueReadable
}

func rejectedStrategies(
    directInsertCompatible: Bool,
    pasteCompatible: Bool,
    appLevelPasteOnly: Bool,
    secure: Bool,
    allowPasteFallback: Bool
) -> [StrategyRejection] {
    var rejections: [StrategyRejection] = []

    if !directInsertCompatible {
        rejections.append(
            StrategyRejection(
                strategy: "AX Value Replacement",
                reason: "Missing writable AX value semantics or selected-text range support."
            )
        )
    }

    if !allowPasteFallback {
        rejections.append(
            StrategyRejection(
                strategy: "Paste Fallback",
                reason: "Paste fallback is disabled in settings."
            )
        )
        rejections.append(
            StrategyRejection(
                strategy: "Custom Editor Paste",
                reason: "Paste fallback is disabled in settings."
            )
        )
        rejections.append(
            StrategyRejection(
                strategy: "App Clipboard Paste",
                reason: "Paste fallback is disabled in settings."
            )
        )
    } else if !pasteCompatible {
        rejections.append(
            StrategyRejection(
                strategy: "Paste Fallback",
                reason: "The target does not look safely paste-compatible yet."
            )
        )
        rejections.append(
            StrategyRejection(
                strategy: "Custom Editor Paste",
                reason: "The target does not look safely paste-compatible yet."
            )
        )
        rejections.append(
            StrategyRejection(
                strategy: "App Clipboard Paste",
                reason: "The target does not look safely paste-compatible yet."
            )
        )
    }

    if secure {
        rejections.append(
            StrategyRejection(strategy: "AX Value Replacement", reason: "Secure fields are blocked.")
        )
        rejections.append(
            StrategyRejection(strategy: "Paste Fallback", reason: "Secure fields are blocked.")
        )
        rejections.append(
            StrategyRejection(strategy: "Custom Editor Paste", reason: "Secure fields are blocked.")
        )
        rejections.append(
            StrategyRejection(strategy: "App Clipboard Paste", reason: "Secure fields are blocked.")
        )
    }

    return rejections
}

func frontmostApplicationTarget() -> NSRunningApplication? {
    NSWorkspace.shared.frontmostApplication
}

func capabilityProfile(
    bundleIdentifier: String?,
    applicationName: String,
    directInsertCompatible: Bool,
    editable: Bool
) -> ApplicationCapabilityProfile {
    let normalizedName = applicationName.lowercased()
    switch bundleIdentifier {
    case "com.openai.codex",
        "com.tinyspeck.slackmacgap",
        "notion.id",
        "com.figma.desktop",
        "com.todesktop.230313mzl4w4u92",
        "com.linear",
        "com.anthropic.claudefordesktop":
        return .opaquePasteCapable
    default:
        break
    }

    if normalizedName.contains("codex")
        || normalizedName.contains("slack")
        || normalizedName.contains("notion")
        || normalizedName.contains("figma")
        || normalizedName.contains("cursor")
        || normalizedName.contains("linear")
        || normalizedName.contains("claude")
    {
        return .opaquePasteCapable
    }

    if directInsertCompatible {
        return .nativeAXStrong
    }

    if editable {
        return .partialAXEditor
    }

    return .unknownConservative
}

let allowPasteFallback = !CommandLine.arguments.contains("--no-paste-fallback")

do {
    let systemElement = AXUIElementCreateSystemWide()
    guard let application = try copyAXUIElementAttribute(kAXFocusedApplicationAttribute, from: systemElement) else {
        throw FocusedTargetError.focusUnavailable
    }

    var pid: pid_t = 0
    guard AXUIElementGetPid(application, &pid) == .success else {
        throw FocusedTargetError.focusUnavailable
    }

    let runningApplication = NSRunningApplication(processIdentifier: pid)
    let focusedElement = try copyAXUIElementAttribute(kAXFocusedUIElementAttribute, from: systemElement)
    let targetMetadata = focusedElement.map(metadata(for:)) ?? SecureTextFieldMetadata(
        role: nil,
        subrole: nil,
        roleDescription: nil,
        title: nil,
        description: nil,
        identifier: nil,
        placeholderValue: nil,
        domIdentifier: nil
    )
    let valueReadable = focusedElement.flatMap { try? copyAttribute(kAXValueAttribute, from: $0) } != nil
    let valueSettable = focusedElement.map { isAttributeSettable(kAXValueAttribute, on: $0) } ?? false
    let selectedTextRangeReadable = focusedElement.flatMap { try? copyAttribute(kAXSelectedTextRangeAttribute, from: $0) } != nil
    let selectedTextReadable = focusedElement.flatMap { try? copyAttribute(kAXSelectedTextAttribute, from: $0) } != nil
    let secure = focusedElement.map { SecureTextFieldClassifier.isSecure(metadata(for: $0)) } ?? false
    let editable = focusedElement.map { _ in
        isEditableTarget(
            role: targetMetadata.role,
            subrole: targetMetadata.subrole,
            roleDescription: targetMetadata.roleDescription,
            title: targetMetadata.title,
            identifier: targetMetadata.identifier,
            placeholderValue: targetMetadata.placeholderValue,
            domIdentifier: targetMetadata.domIdentifier,
            valueReadable: valueReadable,
            valueSettable: valueSettable,
            selectedTextRangeReadable: selectedTextRangeReadable,
            selectedTextReadable: selectedTextReadable
        )
    } ?? false
    let directInsertCompatible = valueReadable && valueSettable && selectedTextRangeReadable
    let profile = capabilityProfile(
        bundleIdentifier: runningApplication?.bundleIdentifier,
        applicationName: runningApplication?.localizedName ?? "Unknown",
        directInsertCompatible: directInsertCompatible,
        editable: editable
    )
    let appLevelPasteOnly = focusedElement == nil && profile == .opaquePasteCapable
    let pasteCompatible = (editable && !secure) || appLevelPasteOnly
    let contextKind: InsertionContextKind = focusedElement == nil ? .appOnly : .axFocusedElement
    let rejections = rejectedStrategies(
        directInsertCompatible: directInsertCompatible,
        pasteCompatible: pasteCompatible,
        appLevelPasteOnly: appLevelPasteOnly,
        secure: secure,
        allowPasteFallback: allowPasteFallback
    )

    let chosenStrategy: InsertionStrategy
    let predictedFailureClass: String?
    let strategyReason: String

    if secure {
        chosenStrategy = .unsupported
        predictedFailureClass = "Secure Target Blocked"
        strategyReason = "The focused target appears to be secure, so Head Canon will not attempt insertion."
    } else if profile == .opaquePasteCapable && pasteCompatible && allowPasteFallback {
        if appLevelPasteOnly {
            chosenStrategy = .appClipboardPaste
            strategyReason = "The app is a known opaque editor, so Head Canon will use app-level clipboard paste while frontmost-app safety holds and will use focused cleanup only when AX focus metadata is available."
        } else {
            chosenStrategy = .customEditorPaste
            strategyReason = "The app is a known opaque editor, so Head Canon will prefer paste-based insertion even though AX exposes writable fields."
        }
        predictedFailureClass = nil
    } else if directInsertCompatible {
        chosenStrategy = .axValueReplacement
        predictedFailureClass = nil
        strategyReason = "The focused target exposes writable AX value and selection-range attributes."
    } else if pasteCompatible && allowPasteFallback {
        if appLevelPasteOnly {
            chosenStrategy = .appClipboardPaste
            strategyReason = "The app is known to accept app-level clipboard paste while it remains frontmost, and Head Canon will use focused cleanup only when AX focus metadata is available."
        } else if valueReadable || selectedTextRangeReadable {
            chosenStrategy = .pasteFallback
            strategyReason = "The target is editable but direct AX replacement is incomplete, so Head Canon should fall back to paste."
        } else {
            chosenStrategy = .customEditorPaste
            strategyReason = "The target looks editable but does not expose the full AX text-field contract, so paste is the intended path."
        }
        predictedFailureClass = nil
    } else {
        chosenStrategy = .unsupported
        predictedFailureClass = editable
            ? (allowPasteFallback ? "Direct AX Unsupported" : "Unsupported Target")
            : "Target Not Editable"
        strategyReason = !editable
            ? "The focused target does not look editable."
            : allowPasteFallback
                ? "The target is editable, but it does not expose enough AX signals to qualify for direct insertion or paste."
                : "Paste fallback is disabled and direct AX replacement is unavailable."
    }

    let formatter = ISO8601DateFormatter()
    let report = FocusedTargetReport(
        observedAt: formatter.string(from: Date()),
        applicationName: runningApplication?.localizedName ?? "Unknown",
        bundleIdentifier: runningApplication?.bundleIdentifier,
        processIdentifier: pid,
        contextKind: contextKind,
        capabilityProfile: profile,
        role: targetMetadata.role,
        subrole: targetMetadata.subrole,
        roleDescription: targetMetadata.roleDescription,
        title: targetMetadata.title,
        identifier: targetMetadata.identifier,
        placeholderValue: targetMetadata.placeholderValue,
        domIdentifier: targetMetadata.domIdentifier,
        valueReadable: valueReadable,
        valueSettable: valueSettable,
        selectedTextRangeReadable: selectedTextRangeReadable,
        selectedTextReadable: selectedTextReadable,
        editable: editable,
        secure: secure,
        pasteCompatible: pasteCompatible,
        directInsertCompatible: directInsertCompatible,
        appLevelPasteOnly: appLevelPasteOnly,
        allowPasteFallback: allowPasteFallback,
        chosenStrategy: chosenStrategy.rawValue,
        predictedFailureClass: predictedFailureClass,
        strategyReason: strategyReason,
        rejectedStrategies: rejections
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(report)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data([0x0A]))
} catch {
    let payload: [String: String] = [
        "error": error.localizedDescription,
        "errorType": String(describing: type(of: error)),
    ]
    let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data([0x0A]))
    Foundation.exit(1)
}
