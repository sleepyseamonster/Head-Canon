import AppKit
import ApplicationServices
import Foundation
import OSLog

enum TextInsertionError: LocalizedError {
    case focusUnavailable
    case accessibilityPermissionRequired
    case accessibilityAPIError(String)
    case unsupportedTarget
    case pasteFailed
    case pasteDeliveryUnconfirmed(String)
    case pasteFallbackDisabled
    case secureTarget
    case focusChanged
    case placeholderCleanupRequired(String)

    var errorDescription: String? {
        switch self {
        case .focusUnavailable:
            "Head Canon could not find a focused editable target."
        case .accessibilityPermissionRequired:
            "Head Canon needs Accessibility access before it can read or insert text in the focused app."
        case .accessibilityAPIError(let message):
            message
        case .unsupportedTarget:
            "The focused target does not support direct insertion or paste fallback."
        case .pasteFailed:
            "Head Canon could not paste into the focused app."
        case .pasteDeliveryUnconfirmed(let message):
            message
        case .pasteFallbackDisabled:
            "Direct insertion is unavailable and paste fallback is disabled."
        case .secureTarget:
            "Head Canon will not insert dictated text into a secure text field."
        case .focusChanged:
            "The focused target changed before paste fallback could complete."
        case .placeholderCleanupRequired(let message):
            message
        }
    }
}

protocol TextInsertionTargetHandle: AnyObject {}

enum InsertionStrategy: String, Equatable, CaseIterable, Identifiable {
    case axValueReplacement
    case customEditorPaste
    case pasteFallback
    case appClipboardPaste
    case unsupported

    var id: String { rawValue }

    var title: String {
        switch self {
        case .axValueReplacement:
            "AX Value Replacement"
        case .customEditorPaste:
            "Custom Editor Paste"
        case .pasteFallback:
            "Paste Fallback"
        case .appClipboardPaste:
            "App Clipboard Paste"
        case .unsupported:
            "Unsupported"
        }
    }
}

enum InsertionFailureClass: String, Equatable, Identifiable {
    case targetNotEditable
    case secureTargetBlocked
    case placeholderAmbiguous
    case directAXUnsupported
    case pasteDeniedByValidation
    case pasteDispatchFailed
    case pasteDeliveryUnconfirmed
    case focusChanged
    case unsupportedTarget
    case accessibilityPermissionRequired
    case focusUnavailable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .targetNotEditable:
            "Target Not Editable"
        case .secureTargetBlocked:
            "Secure Target Blocked"
        case .placeholderAmbiguous:
            "Placeholder Ambiguous"
        case .directAXUnsupported:
            "Direct AX Unsupported"
        case .pasteDeniedByValidation:
            "Paste Denied By Validation"
        case .pasteDispatchFailed:
            "Paste Dispatch Failed"
        case .pasteDeliveryUnconfirmed:
            "Paste Delivery Unconfirmed"
        case .focusChanged:
            "Focus Changed"
        case .unsupportedTarget:
            "Unsupported Target"
        case .accessibilityPermissionRequired:
            "Accessibility Permission Required"
        case .focusUnavailable:
            "Focus Unavailable"
        }
    }
}

enum InsertionContextKind: String, Equatable, Identifiable {
    case axFocusedElement
    case appOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .axFocusedElement:
            "Focused AX Element"
        case .appOnly:
            "App-Only Context"
        }
    }
}

enum ApplicationCapabilityProfile: String, Equatable, Identifiable {
    case nativeAXStrong
    case partialAXEditor
    case opaquePasteCapable
    case unknownConservative

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nativeAXStrong:
            "Native AX Strong"
        case .partialAXEditor:
            "Partial AX Editor"
        case .opaquePasteCapable:
            "Opaque Paste-Capable"
        case .unknownConservative:
            "Unknown / Conservative"
        }
    }
}

struct TargetCapabilities: Equatable {
    let applicationName: String
    let bundleIdentifier: String?
    let processIdentifier: pid_t
    let contextKind: InsertionContextKind
    let capabilityProfile: ApplicationCapabilityProfile
    let browserMetadata: BrowserTargetMetadata?
    let role: String?
    let subrole: String?
    let roleDescription: String?
    let title: String?
    let identifier: String?
    let placeholderValue: String?
    let placeholderLikelyActive: Bool
    let placeholderAmbiguousValueDetected: Bool
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

    init(
        applicationName: String,
        bundleIdentifier: String?,
        processIdentifier: pid_t,
        contextKind: InsertionContextKind = .axFocusedElement,
        capabilityProfile: ApplicationCapabilityProfile = .partialAXEditor,
        browserMetadata: BrowserTargetMetadata? = nil,
        role: String?,
        subrole: String?,
        roleDescription: String?,
        title: String?,
        identifier: String?,
        placeholderValue: String?,
        placeholderLikelyActive: Bool = false,
        placeholderAmbiguousValueDetected: Bool = false,
        domIdentifier: String?,
        valueReadable: Bool,
        valueSettable: Bool,
        selectedTextRangeReadable: Bool,
        selectedTextReadable: Bool,
        editable: Bool,
        secure: Bool,
        pasteCompatible: Bool,
        directInsertCompatible: Bool,
        appLevelPasteOnly: Bool = false
    ) {
        self.applicationName = applicationName
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.contextKind = contextKind
        self.capabilityProfile = capabilityProfile
        self.browserMetadata = browserMetadata
        self.role = role
        self.subrole = subrole
        self.roleDescription = roleDescription
        self.title = title
        self.identifier = identifier
        self.placeholderValue = placeholderValue
        self.placeholderLikelyActive = placeholderLikelyActive
        self.placeholderAmbiguousValueDetected = placeholderAmbiguousValueDetected
        self.domIdentifier = domIdentifier
        self.valueReadable = valueReadable
        self.valueSettable = valueSettable
        self.selectedTextRangeReadable = selectedTextRangeReadable
        self.selectedTextReadable = selectedTextReadable
        self.editable = editable
        self.secure = secure
        self.pasteCompatible = pasteCompatible
        self.directInsertCompatible = directInsertCompatible
        self.appLevelPasteOnly = appLevelPasteOnly
    }

    var hasPlaceholderValue: Bool {
        !(placeholderValue?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var targetLabel: String {
        if let title, !title.isEmpty {
            return title
        }
        if let identifier, !identifier.isEmpty {
            return identifier
        }
        return role ?? "Unknown"
    }

    var prefersOpaquePasteTransport: Bool {
        capabilityProfile == .opaquePasteCapable
    }
}

struct InsertionStrategyRejection: Equatable, Identifiable {
    let strategy: InsertionStrategy
    let reason: String

    var id: String { "\(strategy.rawValue):\(reason)" }
}

enum InsertionVerificationOutcome: String, Equatable, Codable, Identifiable {
    case verified
    case unverified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .verified:
            "Verified"
        case .unverified:
            "Unverified"
        }
    }
}

struct InsertionAttemptReport: Equatable {
    let observedAt: Date
    let observationLabel: String
    let capabilities: TargetCapabilities
    let allowPasteFallback: Bool
    let chosenStrategy: InsertionStrategy
    let appliedStrategy: InsertionStrategy?
    let predictedFailureClass: InsertionFailureClass?
    let strategyReason: String
    let verificationOutcome: InsertionVerificationOutcome?
    let placeholderHandlingOutcome: PlaceholderHandlingOutcome?
    let rejectedStrategies: [InsertionStrategyRejection]

    init(
        observedAt: Date,
        observationLabel: String,
        capabilities: TargetCapabilities,
        allowPasteFallback: Bool,
        chosenStrategy: InsertionStrategy,
        appliedStrategy: InsertionStrategy?,
        predictedFailureClass: InsertionFailureClass?,
        strategyReason: String,
        verificationOutcome: InsertionVerificationOutcome? = nil,
        placeholderHandlingOutcome: PlaceholderHandlingOutcome?,
        rejectedStrategies: [InsertionStrategyRejection]
    ) {
        self.observedAt = observedAt
        self.observationLabel = observationLabel
        self.capabilities = capabilities
        self.allowPasteFallback = allowPasteFallback
        self.chosenStrategy = chosenStrategy
        self.appliedStrategy = appliedStrategy
        self.predictedFailureClass = predictedFailureClass
        self.strategyReason = strategyReason
        self.verificationOutcome = verificationOutcome
        self.placeholderHandlingOutcome = placeholderHandlingOutcome
        self.rejectedStrategies = rejectedStrategies
    }

    func withExecution(
        appliedStrategy: InsertionStrategy,
        placeholderHandlingOutcome: PlaceholderHandlingOutcome,
        verificationOutcome: InsertionVerificationOutcome
    ) -> InsertionAttemptReport {
        InsertionAttemptReport(
            observedAt: observedAt,
            observationLabel: observationLabel,
            capabilities: capabilities,
            allowPasteFallback: allowPasteFallback,
            chosenStrategy: chosenStrategy,
            appliedStrategy: appliedStrategy,
            predictedFailureClass: predictedFailureClass,
            strategyReason: strategyReason,
            verificationOutcome: verificationOutcome,
            placeholderHandlingOutcome: placeholderHandlingOutcome,
            rejectedStrategies: rejectedStrategies
        )
    }
}

enum PlaceholderHandlingOutcome: String, Equatable, Codable, Identifiable {
    case noneNeeded
    case exactPlaceholderRemoved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noneNeeded:
            "None Needed"
        case .exactPlaceholderRemoved:
            "Exact Placeholder Removed"
        }
    }
}

enum PlaceholderValueClassifier {
    private static let editableTerms = [
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

    private static let structuralTerms = [
        "text",
        "field",
        "area",
        "editor",
        "editable",
        "search",
        "input",
        "web",
        "document",
        "group",
        "combo",
    ]

    static func placeholderLikelyActive(
        currentValue: String?,
        placeholderValue: String?,
        selectedRange: CFRange?
    ) -> Bool {
        placeholderRangeToRemove(
            currentValue: currentValue,
            placeholderValue: placeholderValue,
            selectedRange: selectedRange
        ) != nil
    }

    static func ambiguousPlaceholderValueDetected(
        currentValue: String?,
        placeholderValue: String?,
        selectedRange: CFRange?
    ) -> Bool {
        guard
            let currentValue,
            let placeholderValue = normalized(placeholderValue),
            let selectedRange
        else {
            return false
        }

        let currentNSString = currentValue as NSString
        let clampedLocation = max(0, min(selectedRange.location, currentNSString.length))

        guard selectedRange.length == 0 else {
            return false
        }

        if axValueMatchesPlaceholder(currentValue: currentValue, placeholderValue: placeholderValue) {
            return clampedLocation == currentNSString.length && currentNSString.length > 0
        }

        let fullRange = NSRange(location: 0, length: currentNSString.length)
        let suffixRange = currentNSString.range(of: placeholderValue, options: [.backwards], range: fullRange)
        guard suffixRange.location != NSNotFound else {
            return false
        }

        let trailingSuffix = currentNSString.substring(from: suffixRange.location + suffixRange.length)
        guard trailingSuffix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        return clampedLocation >= suffixRange.location
    }

    static func valueContainsPlaceholderText(currentValue: String?, placeholderValue: String?) -> Bool {
        guard
            let normalizedCurrentValue = normalized(currentValue)?.lowercased(),
            let normalizedPlaceholderValue = normalized(placeholderValue)?.lowercased()
        else {
            return false
        }

        return normalizedCurrentValue.contains(normalizedPlaceholderValue)
    }

    static func axValueMatchesPlaceholder(currentValue: String?, placeholderValue: String?) -> Bool {
        guard
            let normalizedCurrentValue = normalized(currentValue),
            let normalizedPlaceholderValue = normalized(placeholderValue)
        else {
            return false
        }

        return normalizedCurrentValue == normalizedPlaceholderValue
    }

    static func placeholderSuggestsEditableTarget(
        placeholderValue: String?,
        supplementalMetadata: [String?]
    ) -> Bool {
        guard
            let normalizedPlaceholder = normalized(placeholderValue)?.lowercased(),
            containsEditableTerm(normalizedPlaceholder)
        else {
            return false
        }

        let normalizedMetadata = supplementalMetadata
            .compactMap { normalized($0)?.lowercased() }

        guard !normalizedMetadata.isEmpty else {
            return false
        }

        return normalizedMetadata.contains(where: containsStructuralHint(_:))
    }

    static func placeholderRangeToRemove(
        currentValue: String?,
        placeholderValue: String?,
        selectedRange: CFRange?
    ) -> NSRange? {
        guard
            let currentValue = currentValue,
            let placeholderValue = normalized(placeholderValue),
            let selectedRange
        else {
            return nil
        }

        let currentNSString = currentValue as NSString
        let clampedLocation = max(0, min(selectedRange.location, currentNSString.length))

        if axValueMatchesPlaceholder(currentValue: currentValue, placeholderValue: placeholderValue) {
            guard selectedRange.length == 0 else {
                return nil
            }

            if clampedLocation == 0 {
                return NSRange(location: 0, length: currentNSString.length)
            }

            return nil
        }
        return nil
    }

    static func sanitizedValueAndSelection(
        currentValue: String,
        placeholderValue: String?,
        selectedRange: CFRange
    ) -> (value: String, selectedRange: CFRange) {
        guard let placeholderRange = placeholderRangeToRemove(
            currentValue: currentValue,
            placeholderValue: placeholderValue,
            selectedRange: selectedRange
        ) else {
            let currentNSString = currentValue as NSString
            let clampedLocation = max(0, min(selectedRange.location, currentNSString.length))
            let clampedLength = max(0, min(selectedRange.length, currentNSString.length - clampedLocation))
            return (
                value: currentValue,
                selectedRange: CFRange(location: clampedLocation, length: clampedLength)
            )
        }

        let currentNSString = currentValue as NSString
        let sanitizedValue = currentNSString.replacingCharacters(in: placeholderRange, with: "")
        let sanitizedNSString = sanitizedValue as NSString
        let clampedLocation = max(0, min(selectedRange.location, placeholderRange.location))
        let clampedLength = max(0, min(selectedRange.length, sanitizedNSString.length - clampedLocation))

        return (
            value: sanitizedValue,
            selectedRange: CFRange(location: clampedLocation, length: clampedLength)
        )
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        return value
    }

    private static func containsEditableTerm(_ value: String) -> Bool {
        editableTerms.contains { value.contains($0) }
    }

    private static func containsStructuralHint(_ value: String) -> Bool {
        structuralTerms.contains { value.contains($0) }
    }
}

enum PasteVerificationDecision: Equatable {
    case verified
    case unavailable
    case failed(String)
}

enum PasteVerificationMode: Equatable {
    case transcriptPresenceOnly
    case exactReplacementPreferred
}

enum PasteVerificationDecider {
    static func mode(for capabilityProfile: ApplicationCapabilityProfile) -> PasteVerificationMode {
        switch capabilityProfile {
        case .nativeAXStrong:
            .exactReplacementPreferred
        case .partialAXEditor, .opaquePasteCapable, .unknownConservative:
            .transcriptPresenceOnly
        }
    }

    static func decide(
        beforeValue: String?,
        beforeSelectedRange: CFRange?,
        afterValue: String?,
        insertedText: String,
        mode: PasteVerificationMode
    ) -> PasteVerificationDecision {
        guard !insertedText.isEmpty else {
            return .verified
        }

        guard let afterValue else {
            return .unavailable
        }

        if let beforeValue, afterValue == beforeValue {
            return .failed("Head Canon pasted into the focused app, but the active field did not change.")
        }

        if mode == .exactReplacementPreferred {
            if
                let beforeValue,
                let beforeSelectedRange,
                let expectedValue = expectedValue(
                    beforeValue: beforeValue,
                    selectedRange: beforeSelectedRange,
                    insertedText: insertedText
                ),
                afterValue != expectedValue
            {
                return .failed("Head Canon pasted into the focused app, but the resulting field contents did not match the dictated text.")
            }
        }

        guard afterValue.contains(insertedText) else {
            return .failed("Head Canon pasted into the focused app but could not confirm that the dictated text appeared in the active field.")
        }

        return .verified
    }

    private static func expectedValue(
        beforeValue: String,
        selectedRange: CFRange,
        insertedText: String
    ) -> String? {
        let valueNSString = beforeValue as NSString
        let location = max(0, min(selectedRange.location, valueNSString.length))
        let length = max(0, min(selectedRange.length, valueNSString.length - location))
        let safeRange = NSRange(location: location, length: length)
        return valueNSString.replacingCharacters(in: safeRange, with: insertedText)
    }
}

enum PlaceholderCleanupDecision: Equatable {
    case notNeeded
    case remove(NSRange)
    case ambiguous
}

enum PlaceholderCleanupDecider {
    static func decide(
        currentValue: String?,
        placeholderValue: String?,
        selectedRange: CFRange?
    ) -> PlaceholderCleanupDecision {
        guard
            let currentValue,
            let placeholderValue,
            PlaceholderValueClassifier.valueContainsPlaceholderText(
                currentValue: currentValue,
                placeholderValue: placeholderValue
            )
        else {
            return .notNeeded
        }

        guard let selectedRange else {
            return .ambiguous
        }

        guard let removableRange = PlaceholderValueClassifier.placeholderRangeToRemove(
            currentValue: currentValue,
            placeholderValue: placeholderValue,
            selectedRange: selectedRange
        ) else {
            return .ambiguous
        }

        return .remove(removableRange)
    }
}

enum InsertionStrategyPlanner {
    static func plan(
        capabilities: TargetCapabilities,
        allowPasteFallback: Bool,
        observationLabel: String = "Current Context",
        observedAt: Date = Date()
    ) -> InsertionAttemptReport {
        let rejectedStrategies = rejectedStrategies(
            for: capabilities,
            allowPasteFallback: allowPasteFallback
        )

        if capabilities.secure {
            return InsertionAttemptReport(
                observedAt: observedAt,
                observationLabel: observationLabel,
                capabilities: capabilities,
                allowPasteFallback: allowPasteFallback,
                chosenStrategy: .unsupported,
                appliedStrategy: nil,
                predictedFailureClass: .secureTargetBlocked,
                strategyReason: "The focused target appears to be secure, so Head Canon will not attempt insertion.",
                placeholderHandlingOutcome: nil,
                rejectedStrategies: rejectedStrategies
            )
        }

        if capabilities.placeholderAmbiguousValueDetected {
            return InsertionAttemptReport(
                observedAt: observedAt,
                observationLabel: observationLabel,
                capabilities: capabilities,
                allowPasteFallback: allowPasteFallback,
                chosenStrategy: .unsupported,
                appliedStrategy: nil,
                predictedFailureClass: .placeholderAmbiguous,
                strategyReason: "The target's AX value appears to mix placeholder text with user-authored content, so Head Canon preserved the transcript instead of guessing where to insert.",
                placeholderHandlingOutcome: nil,
                rejectedStrategies: rejectedStrategies
            )
        }

        if capabilities.prefersOpaquePasteTransport && capabilities.pasteCompatible && allowPasteFallback {
            let strategy: InsertionStrategy = capabilities.appLevelPasteOnly ? .appClipboardPaste : .customEditorPaste
            let reason: String = if capabilities.appLevelPasteOnly {
                "The app is a known opaque editor, so Head Canon will use app-level clipboard paste while frontmost-app safety holds and will use focused cleanup only when AX focus metadata is available."
            } else {
                "The app is a known opaque editor, so Head Canon will prefer paste-based insertion even though AX exposes writable fields."
            }

            return InsertionAttemptReport(
                observedAt: observedAt,
                observationLabel: observationLabel,
                capabilities: capabilities,
                allowPasteFallback: allowPasteFallback,
                chosenStrategy: strategy,
                appliedStrategy: nil,
                predictedFailureClass: nil,
                strategyReason: reason,
                placeholderHandlingOutcome: nil,
                rejectedStrategies: rejectedStrategies
            )
        }

        if capabilities.directInsertCompatible {
            let reason = capabilities.placeholderLikelyActive
                ? "The focused target exposes writable AX value semantics, and Head Canon can sanitize placeholder-backed inline text before inserting."
                : "The focused target exposes writable AX value and selection-range attributes."
            return InsertionAttemptReport(
                observedAt: observedAt,
                observationLabel: observationLabel,
                capabilities: capabilities,
                allowPasteFallback: allowPasteFallback,
                chosenStrategy: .axValueReplacement,
                appliedStrategy: nil,
                predictedFailureClass: nil,
                strategyReason: reason,
                placeholderHandlingOutcome: nil,
                rejectedStrategies: rejectedStrategies
            )
        }

        if capabilities.pasteCompatible && allowPasteFallback {
            let strategy: InsertionStrategy
            if capabilities.appLevelPasteOnly {
                strategy = .appClipboardPaste
            } else if capabilities.valueReadable || capabilities.selectedTextRangeReadable {
                strategy = .pasteFallback
            } else {
                strategy = .customEditorPaste
            }
            let reason: String
            if capabilities.placeholderLikelyActive {
                reason = "The target's AX value matches its placeholder text, so Head Canon will avoid direct replacement and use paste instead."
            } else if strategy == .appClipboardPaste {
                reason = "The app is known to accept app-level clipboard paste while it remains frontmost, and Head Canon will use focused cleanup only when AX focus metadata is available."
            } else {
                reason = strategy == .customEditorPaste
                    ? "The target looks editable but does not expose the full AX text-field contract, so paste is the intended path."
                    : "The target is editable but direct AX replacement is incomplete, so Head Canon should fall back to paste."
            }

            return InsertionAttemptReport(
                observedAt: observedAt,
                observationLabel: observationLabel,
                capabilities: capabilities,
                allowPasteFallback: allowPasteFallback,
                chosenStrategy: strategy,
                appliedStrategy: nil,
                predictedFailureClass: nil,
                strategyReason: reason,
                placeholderHandlingOutcome: nil,
                rejectedStrategies: rejectedStrategies
            )
        }

        let failureClass: InsertionFailureClass = capabilities.editable
            ? (allowPasteFallback ? .directAXUnsupported : .unsupportedTarget)
            : .targetNotEditable
        let reason = !capabilities.editable
            ? "The focused target does not look editable."
            : allowPasteFallback
                ? "The target is editable, but it does not expose enough AX signals to qualify for direct insertion or paste."
                : "Paste fallback is disabled and direct AX replacement is unavailable."

        return InsertionAttemptReport(
            observedAt: observedAt,
            observationLabel: observationLabel,
            capabilities: capabilities,
            allowPasteFallback: allowPasteFallback,
            chosenStrategy: .unsupported,
            appliedStrategy: nil,
            predictedFailureClass: failureClass,
            strategyReason: reason,
            placeholderHandlingOutcome: nil,
            rejectedStrategies: rejectedStrategies
        )
    }

    private static func rejectedStrategies(
        for capabilities: TargetCapabilities,
        allowPasteFallback: Bool
    ) -> [InsertionStrategyRejection] {
        var rejections: [InsertionStrategyRejection] = []

        if capabilities.prefersOpaquePasteTransport {
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .axValueReplacement,
                    reason: "Known opaque editors stay on paste-oriented transports even when AX exposes writable value semantics."
                )
            )
        } else if !capabilities.directInsertCompatible {
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .axValueReplacement,
                    reason: "Missing writable AX value semantics or selected-text range support."
                )
            )
        }

        if !allowPasteFallback {
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .pasteFallback,
                    reason: "Paste fallback is disabled in settings."
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .customEditorPaste,
                    reason: "Paste fallback is disabled in settings."
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .appClipboardPaste,
                    reason: "Paste fallback is disabled in settings."
                )
            )
        } else if !capabilities.pasteCompatible {
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .pasteFallback,
                    reason: "The target does not look safely paste-compatible yet."
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .customEditorPaste,
                    reason: "The target does not look safely paste-compatible yet."
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .appClipboardPaste,
                    reason: "The target does not look safely paste-compatible yet."
                )
            )
        }

        if capabilities.placeholderAmbiguousValueDetected {
            let reason = "The target appears to expose placeholder text inside the current AX value, and Head Canon will not risk deleting user-authored content."
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .axValueReplacement,
                    reason: reason
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .pasteFallback,
                    reason: reason
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .customEditorPaste,
                    reason: reason
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .appClipboardPaste,
                    reason: reason
                )
            )
        }

        if capabilities.secure {
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .axValueReplacement,
                    reason: "Secure fields are blocked."
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .pasteFallback,
                    reason: "Secure fields are blocked."
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .customEditorPaste,
                    reason: "Secure fields are blocked."
                )
            )
            rejections.append(
                InsertionStrategyRejection(
                    strategy: .appClipboardPaste,
                    reason: "Secure fields are blocked."
                )
            )
        }

        return rejections
    }
}

enum PlaceholderCleanupPlanner {
    enum Plan: Equatable {
        case useFocusedTarget
        case skipCleanup
        case blockUnsafeBlindPaste
    }

    static func plan(
        strategy: InsertionStrategy,
        plannedContextKind: InsertionContextKind,
        currentFocusProcessMatches: Bool,
        currentFocusAvailable: Bool
    ) -> Plan {
        switch plannedContextKind {
        case .axFocusedElement:
            return currentFocusAvailable ? .useFocusedTarget : .skipCleanup
        case .appOnly:
            guard strategy == .appClipboardPaste else {
                return .skipCleanup
            }
            guard currentFocusAvailable else {
                // Known opaque editors can still accept app-level paste even when AX focus
                // metadata is unavailable at insertion time. In that case we skip placeholder
                // cleanup instead of planning a route that always self-blocks.
                return .skipCleanup
            }
            guard currentFocusProcessMatches else {
                return .blockUnsafeBlindPaste
            }
            return .useFocusedTarget
        }
    }

}

enum FocusTargetEquivalenceDecider {
    static func appearEquivalent(
        lhs: SecureTextFieldMetadata,
        rhs: SecureTextFieldMetadata,
        allowsWeakTextTargetFallback: Bool
    ) -> Bool {
        guard lhs.role == rhs.role, lhs.subrole == rhs.subrole else {
            return false
        }

        if matchingNonEmpty(lhs.domIdentifier, rhs.domIdentifier) {
            return true
        }

        if matchingNonEmpty(lhs.identifier, rhs.identifier) {
            return true
        }

        guard allowsWeakTextTargetFallback else {
            return false
        }

        guard !hasConflictingStableIdentifier(lhs.domIdentifier, rhs.domIdentifier),
              !hasConflictingStableIdentifier(lhs.identifier, rhs.identifier),
              isWeaklyIdentifiableTextTarget(lhs),
              isWeaklyIdentifiableTextTarget(rhs)
        else {
            return false
        }

        return compatibleWeakLabel(lhs.title, rhs.title)
            && compatibleWeakLabel(lhs.placeholderValue, rhs.placeholderValue)
    }

    private static func matchingNonEmpty(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalized(lhs), let rhs = normalized(rhs) else {
            return false
        }
        return lhs == rhs
    }

    private static func hasConflictingStableIdentifier(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalized(lhs), let rhs = normalized(rhs) else {
            return false
        }
        return lhs != rhs
    }

    private static func compatibleWeakLabel(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalized(lhs), let rhs = normalized(rhs) else {
            return true
        }
        return lhs == rhs
    }

    private static func isWeaklyIdentifiableTextTarget(_ metadata: SecureTextFieldMetadata) -> Bool {
        let searchable = [
            metadata.role,
            metadata.roleDescription,
            metadata.title,
            metadata.placeholderValue,
        ]
        .compactMap { normalized($0) }

        guard !searchable.isEmpty else {
            return false
        }

        return searchable.contains { value in
            value.contains("text area")
                || value.contains("textarea")
                || value.contains("editor")
                || value.contains("editable text")
                || value == (kAXTextAreaRole as String).lowercased()
        }
    }

    private static func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed.lowercased()
    }
}

@MainActor
protocol TextInsertionServicing {
    func captureFocusedTarget() throws -> any TextInsertionTargetHandle
    func planInsertion(
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) throws -> InsertionAttemptReport
    func planExecutionInsertion(
        relativeTo target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) throws -> InsertionAttemptReport
    func insert(
        _ text: String,
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String
    ) async throws -> InsertionAttemptReport
}

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

@MainActor
struct TextInsertionService: TextInsertionServicing {
    private let pasteVirtualKey: CGKeyCode = 9
    private let selectAllVirtualKey: CGKeyCode = 0
    private let deleteVirtualKey: CGKeyCode = 51
    private let standardPasteboardRestoreDelay: Duration = .milliseconds(180)
    private let customEditorPasteboardRestoreDelay: Duration = .milliseconds(180)
    private let appClipboardPasteboardRestoreDelay: Duration = .milliseconds(450)
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "local.headcanon.app",
        category: "text-insertion"
    )

    func captureFocusedTarget() throws -> any TextInsertionTargetHandle {
        switch try currentInsertionContext() {
        case .ax(let target):
            return AXTextInsertionTargetHandle(target: target)
        case .application(let target):
            return ApplicationTextInsertionTargetHandle(target: target)
        }
    }

    func planInsertion(
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String = "Current Context"
    ) throws -> InsertionAttemptReport {
        InsertionStrategyPlanner.plan(
            capabilities: capabilities(for: try resolvedContext(from: target)),
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
    }

    func planExecutionInsertion(
        relativeTo target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String = "Current Context"
    ) throws -> InsertionAttemptReport {
        let executionContext = try executionPlanningContext(from: resolvedContext(from: target))
        return InsertionStrategyPlanner.plan(
            capabilities: capabilities(for: executionContext),
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )
    }

    func insert(
        _ text: String,
        target: (any TextInsertionTargetHandle)?,
        allowPasteFallback: Bool,
        observationLabel: String = "Current Context"
    ) async throws -> InsertionAttemptReport {
        let resolvedTarget = try executionPlanningContext(from: resolvedContext(from: target))
        let attempt = InsertionStrategyPlanner.plan(
            capabilities: capabilities(for: resolvedTarget),
            allowPasteFallback: allowPasteFallback,
            observationLabel: observationLabel
        )

        switch attempt.chosenStrategy {
        case .unsupported:
            throw error(for: attempt.predictedFailureClass)
        case .axValueReplacement:
            try validateTargetStillEligible(resolvedTarget, strategy: .axValueReplacement)
            guard case .ax(let focusTarget) = resolvedTarget else {
                throw TextInsertionError.unsupportedTarget
            }
            let directInsertResult = try directInsert(text: text, into: focusTarget.element)
            if directInsertResult.didInsert {
                return attempt.withExecution(
                    appliedStrategy: .axValueReplacement,
                    placeholderHandlingOutcome: directInsertResult.placeholderHandlingOutcome,
                    verificationOutcome: .verified
                )
            }

            guard allowPasteFallback else {
                throw TextInsertionError.pasteFallbackDisabled
            }

            let pasteResult = try await paste(text: text, into: resolvedTarget, strategy: .pasteFallback)
            return attempt.withExecution(
                appliedStrategy: .pasteFallback,
                placeholderHandlingOutcome: pasteResult.placeholderHandlingOutcome,
                verificationOutcome: pasteResult.verificationOutcome
            )
        case .customEditorPaste, .pasteFallback, .appClipboardPaste:
            guard allowPasteFallback else {
                throw TextInsertionError.pasteFallbackDisabled
            }

            let pasteResult = try await paste(text: text, into: resolvedTarget, strategy: attempt.chosenStrategy)
            return attempt.withExecution(
                appliedStrategy: attempt.chosenStrategy,
                placeholderHandlingOutcome: pasteResult.placeholderHandlingOutcome,
                verificationOutcome: pasteResult.verificationOutcome
            )
        }
    }

    private func focusedTarget() throws -> FocusTarget {
        let systemElement = AXUIElementCreateSystemWide()

        guard
            let application = try copyAXUIElementAttribute(kAXFocusedApplicationAttribute, from: systemElement),
            let element = try copyAXUIElementAttribute(kAXFocusedUIElementAttribute, from: systemElement),
            let processIdentifier = processIdentifier(for: application)
        else {
            throw TextInsertionError.focusUnavailable
        }

        return FocusTarget(application: application, element: element, processIdentifier: processIdentifier)
    }

    private func currentInsertionContext() throws -> ResolvedInsertionContext {
        do {
            let focusedTarget = try focusedTarget()
            return .ax(focusedTarget)
        } catch TextInsertionError.focusUnavailable {
            // Fall through to app-level context capture for editors that do not expose a stable AX target.
        } catch {
            throw error
        }

        if let frontmostApplicationTarget = frontmostApplicationTarget() {
            return .application(frontmostApplicationTarget)
        }

        throw TextInsertionError.focusUnavailable
    }

    private func resolvedContext(from targetHandle: (any TextInsertionTargetHandle)?) throws -> ResolvedInsertionContext {
        guard let targetHandle else {
            return try currentInsertionContext()
        }

        if let target = (targetHandle as? AXTextInsertionTargetHandle)?.target {
            return .ax(target)
        }

        if let target = (targetHandle as? ApplicationTextInsertionTargetHandle)?.target {
            return .application(target)
        }

        throw TextInsertionError.unsupportedTarget
    }

    private func executionPlanningContext(from originalTarget: ResolvedInsertionContext) throws -> ResolvedInsertionContext {
        let originalCapabilities = capabilities(for: originalTarget)
        guard originalCapabilities.prefersOpaquePasteTransport else {
            return originalTarget
        }

        let currentContext = try currentInsertionContext()
        guard currentContext.processIdentifier == originalTarget.processIdentifier else {
            throw TextInsertionError.focusChanged
        }

        switch (originalTarget, currentContext) {
        case (.ax(let originalFocusTarget), .ax(let currentFocusTarget)):
            guard focusTargetsAppearEquivalent(currentFocusTarget, originalFocusTarget) else {
                throw TextInsertionError.focusChanged
            }
            return .ax(currentFocusTarget)
        case (.application, _):
            return currentContext
        case (.ax, .application):
            throw TextInsertionError.focusChanged
        }
    }

    private func capabilities(for context: ResolvedInsertionContext) -> TargetCapabilities {
        switch context {
        case .ax(let target):
            return capabilities(for: target)
        case .application(let target):
            let profile = capabilityProfile(for: target.bundleIdentifier, applicationName: target.applicationName)
            let pasteCompatible = profile == .opaquePasteCapable
            let browserMetadata = browserMetadata(
                bundleIdentifier: target.bundleIdentifier,
                applicationName: target.applicationName,
                contextKind: .appOnly,
                role: nil,
                subrole: nil,
                roleDescription: nil,
                title: nil,
                identifier: nil,
                placeholderValue: nil,
                domIdentifier: nil,
                valueReadable: false,
                valueSettable: false,
                editable: false,
                secure: false
            )
            return TargetCapabilities(
                applicationName: target.applicationName,
                bundleIdentifier: target.bundleIdentifier,
                processIdentifier: target.processIdentifier,
                contextKind: .appOnly,
                capabilityProfile: profile,
                browserMetadata: browserMetadata,
                role: nil,
                subrole: nil,
                roleDescription: nil,
                title: nil,
                identifier: nil,
                placeholderValue: nil,
                placeholderAmbiguousValueDetected: false,
                domIdentifier: nil,
                valueReadable: false,
                valueSettable: false,
                selectedTextRangeReadable: false,
                selectedTextReadable: false,
                editable: false,
                secure: false,
                pasteCompatible: pasteCompatible,
                directInsertCompatible: false,
                appLevelPasteOnly: pasteCompatible
            )
        }
    }

    private func capabilities(for target: FocusTarget) -> TargetCapabilities {
        let metadata = metadata(for: target.element)
        let role = metadata.role
        let subrole = metadata.subrole
        let roleDescription = metadata.roleDescription
        let currentValue = (try? copyStringAttribute(kAXValueAttribute, from: target.element)) ?? nil
        let selectedRange = (try? selectedRange(for: target.element)) ?? nil
        let valueReadable = currentValue != nil
        let valueSettable = isAttributeSettable(kAXValueAttribute, on: target.element)
        let selectedTextRangeReadable = selectedRange != nil
        let selectedTextReadable = (try? copyAttribute(kAXSelectedTextAttribute, from: target.element)) != nil
        let secure = SecureTextFieldClassifier.isSecure(metadata)
        let placeholderLikelyActive = PlaceholderValueClassifier.placeholderLikelyActive(
            currentValue: currentValue,
            placeholderValue: metadata.placeholderValue,
            selectedRange: selectedRange
        )
        let placeholderAmbiguousValueDetected = PlaceholderValueClassifier.ambiguousPlaceholderValueDetected(
            currentValue: currentValue,
            placeholderValue: metadata.placeholderValue,
            selectedRange: selectedRange
        )
        let editable = isEditableTarget(
            role: role,
            subrole: subrole,
            roleDescription: roleDescription,
            title: metadata.title,
            identifier: metadata.identifier,
            placeholderValue: metadata.placeholderValue,
            domIdentifier: metadata.domIdentifier,
            valueReadable: valueReadable,
            valueSettable: valueSettable,
            selectedTextRangeReadable: selectedTextRangeReadable,
            selectedTextReadable: selectedTextReadable
        )
        let directInsertCompatible = valueReadable
            && valueSettable
            && selectedTextRangeReadable
        let pasteCompatible = editable && !secure
        let application = NSRunningApplication(processIdentifier: target.processIdentifier)
        let profile = capabilityProfile(
            for: application?.bundleIdentifier,
            applicationName: application?.localizedName ?? "Unknown",
            directInsertCompatible: directInsertCompatible,
            editable: editable
        )
        let browserMetadata = browserMetadata(
            bundleIdentifier: application?.bundleIdentifier,
            applicationName: application?.localizedName ?? "Unknown",
            contextKind: .axFocusedElement,
            role: role,
            subrole: subrole,
            roleDescription: roleDescription,
            title: metadata.title,
            identifier: metadata.identifier,
            placeholderValue: metadata.placeholderValue,
            domIdentifier: metadata.domIdentifier,
            valueReadable: valueReadable,
            valueSettable: valueSettable,
            editable: editable,
            secure: secure
        )

        return TargetCapabilities(
            applicationName: application?.localizedName ?? "Unknown",
            bundleIdentifier: application?.bundleIdentifier,
            processIdentifier: target.processIdentifier,
            contextKind: .axFocusedElement,
            capabilityProfile: profile,
            browserMetadata: browserMetadata,
            role: role,
            subrole: subrole,
            roleDescription: roleDescription,
            title: metadata.title,
            identifier: metadata.identifier,
            placeholderValue: metadata.placeholderValue,
            placeholderLikelyActive: placeholderLikelyActive,
            placeholderAmbiguousValueDetected: placeholderAmbiguousValueDetected,
            domIdentifier: metadata.domIdentifier,
            valueReadable: valueReadable,
            valueSettable: valueSettable,
            selectedTextRangeReadable: selectedTextRangeReadable,
            selectedTextReadable: selectedTextReadable,
            editable: editable,
            secure: secure,
            pasteCompatible: pasteCompatible,
            directInsertCompatible: directInsertCompatible
        )
    }

    private struct DirectInsertResult {
        let didInsert: Bool
        let placeholderHandlingOutcome: PlaceholderHandlingOutcome
    }

    private struct PasteTransportResult {
        let placeholderHandlingOutcome: PlaceholderHandlingOutcome
        let verificationOutcome: InsertionVerificationOutcome
    }

    private func directInsert(text: String, into element: AXUIElement) throws -> DirectInsertResult {
        guard
            let currentValue = try copyStringAttribute(kAXValueAttribute, from: element),
            isAttributeSettable(kAXValueAttribute, on: element)
        else {
            return DirectInsertResult(didInsert: false, placeholderHandlingOutcome: .noneNeeded)
        }

        guard let selectedRange = try selectedRange(for: element) else {
            return DirectInsertResult(didInsert: false, placeholderHandlingOutcome: .noneNeeded)
        }

        let placeholderValue = (try? copyStringAttribute(kAXPlaceholderValueAttribute, from: element)) ?? nil
        let placeholderRange = PlaceholderValueClassifier.placeholderRangeToRemove(
            currentValue: currentValue,
            placeholderValue: placeholderValue,
            selectedRange: selectedRange
        )
        let sanitizedState = PlaceholderValueClassifier.sanitizedValueAndSelection(
            currentValue: currentValue,
            placeholderValue: placeholderValue,
            selectedRange: selectedRange
        )

        let currentNSString = sanitizedState.value as NSString
        let location = max(0, min(sanitizedState.selectedRange.location, currentNSString.length))
        let length = max(0, min(sanitizedState.selectedRange.length, currentNSString.length - location))
        let safeRange = NSRange(location: location, length: length)
        let updatedValue = currentNSString.replacingCharacters(in: safeRange, with: text)

        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            updatedValue as CFTypeRef
        )

        if setResult == .apiDisabled {
            throw TextInsertionError.accessibilityPermissionRequired
        }

        guard setResult == .success else {
            logger.error("AX set failed for value attribute with error \(self.axErrorName(setResult), privacy: .public)")
            return DirectInsertResult(didInsert: false, placeholderHandlingOutcome: .noneNeeded)
        }

        guard let verifiedValue = try copyStringAttribute(kAXValueAttribute, from: element), verifiedValue == updatedValue else {
            logger.error("AX value verification failed after direct insertion; falling back to paste transport.")
            return DirectInsertResult(didInsert: false, placeholderHandlingOutcome: .noneNeeded)
        }

        var cursorRange = CFRange(location: location + (text as NSString).length, length: 0)

        if let newRange = AXValueCreate(.cfRange, &cursorRange) {
            _ = AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextRangeAttribute as CFString,
                newRange
            )
        }

        return DirectInsertResult(
            didInsert: true,
            placeholderHandlingOutcome: placeholderRange == nil ? .noneNeeded : .exactPlaceholderRemoved
        )
    }

    private func validateTargetStillEligible(
        _ originalTarget: ResolvedInsertionContext,
        strategy: InsertionStrategy
    ) throws {
        guard isApplicationFrontmost(originalTarget.processIdentifier) else {
            throw TextInsertionError.focusChanged
        }

        let currentContext = try currentInsertionContext()

        guard currentContext.processIdentifier == originalTarget.processIdentifier else {
            throw TextInsertionError.focusChanged
        }

        if let currentTarget = currentContext.focusTarget, isSecureTextField(currentTarget.element) {
            throw TextInsertionError.secureTarget
        }

        switch strategy {
        case .customEditorPaste:
            let currentCapabilities = capabilities(for: currentContext)
            guard currentCapabilities.editable else {
                throw TextInsertionError.unsupportedTarget
            }
            guard
                case .ax(let originalFocusTarget) = originalTarget,
                case .ax(let currentTarget) = currentContext,
                focusTargetsAppearEquivalent(currentTarget, originalFocusTarget)
            else {
                throw TextInsertionError.focusChanged
            }
        case .appClipboardPaste:
            let currentCapabilities = capabilities(for: currentContext)
            guard currentCapabilities.pasteCompatible else {
                throw TextInsertionError.unsupportedTarget
            }
        case .axValueReplacement, .pasteFallback, .unsupported:
            guard
                case .ax(let originalFocusTarget) = originalTarget,
                case .ax(let currentTarget) = currentContext
            else {
                throw TextInsertionError.focusChanged
            }
            guard
                CFEqual(currentTarget.application, originalFocusTarget.application),
                CFEqual(currentTarget.element, originalFocusTarget.element)
            else {
                throw TextInsertionError.focusChanged
            }
        }
    }

    private func paste(
        text: String,
        into target: ResolvedInsertionContext,
        strategy: InsertionStrategy
    ) async throws -> PasteTransportResult {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)

        try validateTargetStillEligible(target, strategy: strategy)
        let placeholderHandlingOutcome: PlaceholderHandlingOutcome
        switch placeholderCleanupPlan(for: target, strategy: strategy) {
        case .useFocusedTarget(let cleanupTarget):
            placeholderHandlingOutcome = try await clearPlaceholderIfNeeded(beforePastingInto: cleanupTarget)
        case .skipCleanup:
            placeholderHandlingOutcome = .noneNeeded
        case .blockUnsafeBlindPaste:
            throw TextInsertionError.placeholderCleanupRequired(
                "Head Canon could not verify the focused text field in this app, so it preserved the transcript instead of blindly pasting into a placeholder-prone composer."
            )
        }

        try validateTargetStillEligible(target, strategy: strategy)
        let verificationBaseline = capturePasteVerificationSnapshot(for: target)

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw TextInsertionError.pasteFailed
        }
        let injectedChangeCount = pasteboard.changeCount

        try? await Task.sleep(for: pasteboardDispatchDelay(for: strategy))

        do {
            guard simulatePasteKeystroke(for: target.processIdentifier, strategy: strategy) else {
                throw TextInsertionError.pasteFailed
            }
        } catch {
            if pasteboard.changeCount == injectedChangeCount {
                snapshot.restore(to: pasteboard)
            }
            throw error
        }

        try? await Task.sleep(for: pasteboardRestoreDelay(for: strategy))
        let verificationOutcome = try verifyPasteDelivery(of: text, into: target, baseline: verificationBaseline)

        // Avoid clobbering newer clipboard contents if the user changed them during fallback.
        guard pasteboard.changeCount == injectedChangeCount else {
            return PasteTransportResult(
                placeholderHandlingOutcome: placeholderHandlingOutcome,
                verificationOutcome: verificationOutcome
            )
        }

        snapshot.restore(to: pasteboard)
        return PasteTransportResult(
            placeholderHandlingOutcome: placeholderHandlingOutcome,
            verificationOutcome: verificationOutcome
        )
    }

    private func pasteboardRestoreDelay(for strategy: InsertionStrategy) -> Duration {
        switch strategy {
        case .appClipboardPaste:
            return appClipboardPasteboardRestoreDelay
        case .customEditorPaste:
            return customEditorPasteboardRestoreDelay
        case .pasteFallback, .axValueReplacement, .unsupported:
            return standardPasteboardRestoreDelay
        }
    }

    private func pasteboardDispatchDelay(for strategy: InsertionStrategy) -> Duration {
        switch strategy {
        case .appClipboardPaste, .customEditorPaste:
            return .milliseconds(45)
        case .pasteFallback, .axValueReplacement, .unsupported:
            return .milliseconds(20)
        }
    }

    private func capturePasteVerificationSnapshot(for target: ResolvedInsertionContext) -> PasteVerificationSnapshot? {
        guard
            let currentFocusTarget = try? focusedTarget(),
            currentFocusTarget.processIdentifier == target.processIdentifier,
            !isSecureTextField(currentFocusTarget.element)
        else {
            return nil
        }

        let currentValue = try? copyStringAttribute(kAXValueAttribute, from: currentFocusTarget.element)
        let currentSelectedRange = try? selectedRange(for: currentFocusTarget.element)
        return PasteVerificationSnapshot(
            target: currentFocusTarget,
            value: currentValue,
            selectedRange: currentSelectedRange
        )
    }

    private func verifyPasteDelivery(
        of text: String,
        into target: ResolvedInsertionContext,
        baseline: PasteVerificationSnapshot?
    ) throws -> InsertionVerificationOutcome {
        guard let baseline else {
            return .unverified
        }

        let currentContext = try currentInsertionContext()
        guard currentContext.processIdentifier == target.processIdentifier else {
            throw TextInsertionError.focusChanged
        }

        guard let currentFocusTarget = currentContext.focusTarget else {
            return .unverified
        }

        guard focusTargetsAppearEquivalent(currentFocusTarget, baseline.target) else {
            throw TextInsertionError.focusChanged
        }

        let afterValue = try? copyStringAttribute(kAXValueAttribute, from: currentFocusTarget.element)
        let verificationMode = PasteVerificationDecider.mode(
            for: capabilities(for: currentContext).capabilityProfile
        )
        switch PasteVerificationDecider.decide(
            beforeValue: baseline.value,
            beforeSelectedRange: baseline.selectedRange,
            afterValue: afterValue,
            insertedText: text,
            mode: verificationMode
        ) {
        case .verified:
            return .verified
        case .unavailable:
            return .unverified
        case .failed(let message):
            throw TextInsertionError.pasteDeliveryUnconfirmed(message)
        }
    }

    private func simulatePasteKeystroke(
        for processIdentifier: pid_t,
        strategy: InsertionStrategy
    ) -> Bool {
        guard strategy == .appClipboardPaste else {
            return simulateKeystroke(
                virtualKey: pasteVirtualKey,
                flags: .maskCommand,
                processIdentifier: processIdentifier
            )
        }

        guard isApplicationFrontmost(processIdentifier) else {
            return false
        }

        return simulateFrontmostKeystroke(
            virtualKey: pasteVirtualKey,
            flags: .maskCommand
        )
    }

    private func simulateDeleteKeystroke(for processIdentifier: pid_t) -> Bool {
        simulateKeystroke(
            virtualKey: deleteVirtualKey,
            flags: [],
            processIdentifier: processIdentifier
        )
    }

    private func simulateSelectAllAndDelete(for processIdentifier: pid_t) -> Bool {
        guard simulateKeystroke(
            virtualKey: selectAllVirtualKey,
            flags: .maskCommand,
            processIdentifier: processIdentifier
        ) else {
            return false
        }

        return simulateDeleteKeystroke(for: processIdentifier)
    }

    private func simulateKeystroke(
        virtualKey: CGKeyCode,
        flags: CGEventFlags,
        processIdentifier: pid_t
    ) -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)
        else {
            return false
        }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.postToPid(processIdentifier)
        keyUp.postToPid(processIdentifier)
        return true
    }

    private func simulateFrontmostKeystroke(
        virtualKey: CGKeyCode,
        flags: CGEventFlags
    ) -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)
        else {
            return false
        }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func isSecureTextField(_ element: AXUIElement) -> Bool {
        SecureTextFieldClassifier.isSecure(metadata(for: element))
    }

    private func metadata(for element: AXUIElement) -> SecureTextFieldMetadata {
        SecureTextFieldMetadata(
            role: try? copyAttribute(kAXRoleAttribute, from: element) as? String,
            subrole: try? copyAttribute(kAXSubroleAttribute, from: element) as? String,
            roleDescription: try? copyAttribute(kAXRoleDescriptionAttribute, from: element) as? String,
            title: try? copyAttribute(kAXTitleAttribute, from: element) as? String,
            description: try? copyAttribute(kAXDescriptionAttribute, from: element) as? String,
            identifier: try? copyAttribute(kAXIdentifierAttribute, from: element) as? String,
            placeholderValue: try? copyAttribute(kAXPlaceholderValueAttribute, from: element) as? String,
            domIdentifier: try? copyAttribute(kAXDOMIdentifierAttribute as String, from: element) as? String
        )
    }

    private func processIdentifier(for element: AXUIElement) -> pid_t? {
        var processIdentifier: pid_t = 0
        let result = AXUIElementGetPid(element, &processIdentifier)
        guard result == .success else {
            return nil
        }

        return processIdentifier
    }

    private func isApplicationFrontmost(_ processIdentifier: pid_t) -> Bool {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == processIdentifier
    }

    private func frontmostApplicationTarget() -> ApplicationTarget? {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        return ApplicationTarget(
            processIdentifier: application.processIdentifier,
            applicationName: application.localizedName ?? "Unknown",
            bundleIdentifier: application.bundleIdentifier
        )
    }

    private func capabilityProfile(
        for bundleIdentifier: String?,
        applicationName: String,
        directInsertCompatible: Bool = false,
        editable: Bool = false
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

    private func browserMetadata(
        bundleIdentifier: String?,
        applicationName: String,
        contextKind: InsertionContextKind,
        role: String?,
        subrole: String?,
        roleDescription: String?,
        title: String?,
        identifier: String?,
        placeholderValue: String?,
        domIdentifier: String?,
        valueReadable: Bool,
        valueSettable: Bool,
        editable: Bool,
        secure: Bool
    ) -> BrowserTargetMetadata? {
        guard let browser = BrowserHostApplication.detect(
            bundleIdentifier: bundleIdentifier,
            applicationName: applicationName
        ) else {
            return nil
        }

        let editorFamily = BrowserTargetClassifier.editorFamily(
            role: role,
            subrole: subrole,
            roleDescription: roleDescription,
            title: title,
            identifier: identifier,
            placeholderValue: placeholderValue,
            domIdentifier: domIdentifier,
            secure: secure
        )
        let targetClass = BrowserTargetClassifier.targetClass(
            editorFamily: editorFamily,
            contextKind: contextKind,
            secure: secure
        )
        let verificationMode = BrowserTargetClassifier.verificationMode(
            targetClass: targetClass,
            valueReadable: valueReadable,
            valueSettable: valueSettable,
            editable: editable
        )
        let fingerprint = BrowserTargetClassifier.fingerprint(
            role: role,
            title: title,
            identifier: identifier,
            placeholderValue: placeholderValue,
            domIdentifier: domIdentifier
        )

        return BrowserTargetMetadata(
            browser: browser,
            targetClass: targetClass,
            editorFamily: editorFamily,
            verificationMode: verificationMode,
            pageOrigin: nil,
            pageTitle: nil,
            framePath: nil,
            frameIdentifier: nil,
            targetFingerprint: fingerprint,
            operationID: nil,
            focusCapturedAt: nil,
            focusValidatedAt: nil,
            protocolVersion: nil,
            extensionVersion: nil
        )
    }

    private func isEditableTarget(
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

        if PlaceholderValueClassifier.placeholderSuggestsEditableTarget(
            placeholderValue: placeholderValue,
            supplementalMetadata: [role, subrole, roleDescription, title, identifier, domIdentifier]
        ) {
            return true
        }

        return valueReadable
    }

    private func clearPlaceholderIfNeeded(beforePastingInto target: FocusTarget) async throws -> PlaceholderHandlingOutcome {
        let currentValue = (try? copyStringAttribute(kAXValueAttribute, from: target.element)) ?? nil
        let placeholderValue = (try? copyStringAttribute(kAXPlaceholderValueAttribute, from: target.element)) ?? nil
        let currentSelectedRange = (try? selectedRange(for: target.element)) ?? nil

        switch PlaceholderCleanupDecider.decide(
            currentValue: currentValue,
            placeholderValue: placeholderValue,
            selectedRange: currentSelectedRange
        ) {
        case .notNeeded:
            return .noneNeeded
        case .ambiguous:
            throw TextInsertionError.placeholderCleanupRequired(
                "Head Canon detected placeholder text in the target field but could not remove it safely. The transcript was preserved instead of pasting into ambiguous composer state."
            )
        case .remove(let placeholderRange):
            if trySelectPlaceholderRangeAndDelete(placeholderRange, on: target.element, processIdentifier: target.processIdentifier) {
                try? await Task.sleep(for: .milliseconds(60))
                return .exactPlaceholderRemoved
            }

            throw TextInsertionError.placeholderCleanupRequired(
                "Head Canon detected placeholder text in the target field but could not clear it safely. The transcript was preserved instead of pasting into ambiguous composer state."
            )
        }
    }

    private enum PlaceholderCleanupExecutionPlan {
        case useFocusedTarget(FocusTarget)
        case skipCleanup
        case blockUnsafeBlindPaste
    }

    private func placeholderCleanupPlan(
        for target: ResolvedInsertionContext,
        strategy: InsertionStrategy
    ) -> PlaceholderCleanupExecutionPlan {
        switch target {
        case .ax(let focusedTarget):
            let currentFocusTarget = try? self.focusedTarget()
            let currentFocusProcessMatches = currentFocusTarget?.processIdentifier == focusedTarget.processIdentifier
            let currentFocusEquivalent = if let currentFocusTarget {
                focusTargetsAppearEquivalent(currentFocusTarget, focusedTarget)
            } else {
                false
            }
            let plan = PlaceholderCleanupPlanner.plan(
                strategy: strategy,
                plannedContextKind: .axFocusedElement,
                currentFocusProcessMatches: currentFocusProcessMatches && currentFocusEquivalent,
                currentFocusAvailable: currentFocusTarget != nil
            )
            switch plan {
            case .useFocusedTarget:
                if let currentFocusTarget, currentFocusEquivalent, !isSecureTextField(currentFocusTarget.element) {
                    return .useFocusedTarget(currentFocusTarget)
                }
                return .blockUnsafeBlindPaste
            case .skipCleanup:
                return .skipCleanup
            case .blockUnsafeBlindPaste:
                return .blockUnsafeBlindPaste
            }
        case .application(let applicationTarget):
            let currentFocusTarget = try? focusedTarget()
            let currentFocusProcessMatches = currentFocusTarget?.processIdentifier == applicationTarget.processIdentifier
            let plan = PlaceholderCleanupPlanner.plan(
                strategy: strategy,
                plannedContextKind: .appOnly,
                currentFocusProcessMatches: currentFocusProcessMatches,
                currentFocusAvailable: currentFocusTarget != nil
            )

            switch plan {
            case .skipCleanup:
                return .skipCleanup
            case .blockUnsafeBlindPaste:
                return .blockUnsafeBlindPaste
            case .useFocusedTarget:
                guard
                    let currentFocusTarget,
                    !isSecureTextField(currentFocusTarget.element)
                else {
                    return .blockUnsafeBlindPaste
                }
                return .useFocusedTarget(currentFocusTarget)
            }
        }
    }

    private func trySelectPlaceholderRangeAndDelete(
        _ range: NSRange,
        on element: AXUIElement,
        processIdentifier: pid_t
    ) -> Bool {
        if setSelectedRange(range, on: element) {
            return simulateDeleteKeystroke(for: processIdentifier)
        }

        if range.location == 0 {
            return simulateSelectAllAndDelete(for: processIdentifier)
        }

        return false
    }

    private func setSelectedRange(_ range: NSRange, on element: AXUIElement) -> Bool {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let value = AXValueCreate(.cfRange, &cfRange) else {
            return false
        }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            value
        )

        return result == .success
    }

    private func focusTargetsAppearEquivalent(_ lhs: FocusTarget, _ rhs: FocusTarget) -> Bool {
        guard lhs.processIdentifier == rhs.processIdentifier else {
            return false
        }

        if CFEqual(lhs.application, rhs.application), CFEqual(lhs.element, rhs.element) {
            return true
        }

        let lhsMetadata = metadata(for: lhs.element)
        let rhsMetadata = metadata(for: rhs.element)
        let application = NSRunningApplication(processIdentifier: lhs.processIdentifier)
        let applicationProfile = capabilityProfile(
            for: application?.bundleIdentifier,
            applicationName: application?.localizedName ?? "Unknown"
        )

        return FocusTargetEquivalenceDecider.appearEquivalent(
            lhs: lhsMetadata,
            rhs: rhsMetadata,
            allowsWeakTextTargetFallback: applicationProfile == .opaquePasteCapable
        )
    }

    private func selectedRange(for element: AXUIElement) throws -> CFRange? {
        guard let selectedTextRange = try copyAttribute(kAXSelectedTextRangeAttribute, from: element) else {
            return nil
        }

        guard CFGetTypeID(selectedTextRange) == AXValueGetTypeID() else {
            return nil
        }

        let rangeValue = unsafeDowncast(selectedTextRange, to: AXValue.self)
        guard AXValueGetType(rangeValue) == .cfRange else {
            return nil
        }

        var selectedRange = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &selectedRange) else {
            return nil
        }

        return selectedRange
    }

    private func copyStringAttribute(_ attribute: String, from element: AXUIElement) throws -> String? {
        try copyAttribute(attribute, from: element) as? String
    }

    private func error(for failureClass: InsertionFailureClass?) -> TextInsertionError {
        switch failureClass {
        case .targetNotEditable:
            return .unsupportedTarget
        case .secureTargetBlocked:
            return .secureTarget
        case .placeholderAmbiguous:
            return .placeholderCleanupRequired(
                "Head Canon detected placeholder-style text already inside the field and preserved the transcript instead of risking text loss."
            )
        case .directAXUnsupported:
            return .unsupportedTarget
        case .pasteDeniedByValidation:
            return .focusChanged
        case .pasteDispatchFailed:
            return .pasteFailed
        case .pasteDeliveryUnconfirmed:
            return .pasteFailed
        case .focusChanged:
            return .focusChanged
        case .unsupportedTarget:
            return .unsupportedTarget
        case .accessibilityPermissionRequired:
            return .accessibilityPermissionRequired
        case .focusUnavailable:
            return .focusUnavailable
        case nil:
            return .unsupportedTarget
        }
    }

    private func copyAttribute(_ attribute: String, from element: AXUIElement) throws -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        switch result {
        case .success:
            return value
        case .apiDisabled:
            logger.error("Accessibility disabled while reading \(attribute, privacy: .public)")
            throw TextInsertionError.accessibilityPermissionRequired
        case .noValue, .attributeUnsupported:
            return nil
        default:
            let message = "Head Canon hit an Accessibility API error while reading \(attribute): \(axErrorName(result))."
            logger.error("\(message, privacy: .public)")
            throw TextInsertionError.accessibilityAPIError(message)
        }
    }

    private func copyAXUIElementAttribute(_ attribute: String, from element: AXUIElement) throws -> AXUIElement? {
        guard
            let value = try copyAttribute(attribute, from: element),
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }

        return unsafeDowncast(value, to: AXUIElement.self)
    }

    private func isAttributeSettable(_ attribute: String, on element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        return result == .success && settable.boolValue
    }

    private func axErrorName(_ error: AXError) -> String {
        switch error {
        case .success:
            "success"
        case .failure:
            "failure"
        case .illegalArgument:
            "illegalArgument"
        case .invalidUIElement:
            "invalidUIElement"
        case .invalidUIElementObserver:
            "invalidUIElementObserver"
        case .cannotComplete:
            "cannotComplete"
        case .attributeUnsupported:
            "attributeUnsupported"
        case .actionUnsupported:
            "actionUnsupported"
        case .notificationUnsupported:
            "notificationUnsupported"
        case .notImplemented:
            "notImplemented"
        case .notificationAlreadyRegistered:
            "notificationAlreadyRegistered"
        case .notificationNotRegistered:
            "notificationNotRegistered"
        case .apiDisabled:
            "apiDisabled"
        case .noValue:
            "noValue"
        case .parameterizedAttributeUnsupported:
            "parameterizedAttributeUnsupported"
        case .notEnoughPrecision:
            "notEnoughPrecision"
        @unknown default:
            "unknown(\(error.rawValue))"
        }
    }

}

private struct FocusTarget {
    let application: AXUIElement
    let element: AXUIElement
    let processIdentifier: pid_t
}

private struct ApplicationTarget {
    let processIdentifier: pid_t
    let applicationName: String
    let bundleIdentifier: String?
}

private enum ResolvedInsertionContext {
    case ax(FocusTarget)
    case application(ApplicationTarget)

    var processIdentifier: pid_t {
        switch self {
        case .ax(let target):
            return target.processIdentifier
        case .application(let target):
            return target.processIdentifier
        }
    }

    var focusTarget: FocusTarget? {
        switch self {
        case .ax(let target):
            return target
        case .application:
            return nil
        }
    }
}

private final class AXTextInsertionTargetHandle: TextInsertionTargetHandle {
    let target: FocusTarget

    init(target: FocusTarget) {
        self.target = target
    }
}

private final class ApplicationTextInsertionTargetHandle: TextInsertionTargetHandle {
    let target: ApplicationTarget

    init(target: ApplicationTarget) {
        self.target = target
    }
}

private struct PasteVerificationSnapshot {
    let target: FocusTarget
    let value: String?
    let selectedRange: CFRange?
}

private struct PasteboardSnapshot {
    struct Item {
        let values: [(NSPasteboard.PasteboardType, Data)]
    }

    let items: [Item]

    static func capture(from pasteboard: NSPasteboard) -> Self {
        let items: [Item] = pasteboard.pasteboardItems?.map { item in
            let values = item.types.compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
                guard let data = item.data(forType: type) else {
                    return nil
                }

                return (type, data)
            }

            return Item(values: values)
        } ?? []

        return Self(items: items)
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        for item in items {
            let pasteboardItem = NSPasteboardItem()
            for (type, data) in item.values {
                pasteboardItem.setData(data, forType: type)
            }
            pasteboard.writeObjects([pasteboardItem])
        }
    }
}
