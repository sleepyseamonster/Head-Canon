import AppKit
import ApplicationServices
import Foundation

enum PermissionDebugDefaultsKeys {
    static let accessibilityPrompted = "accessibilityPrompted"
    static let accessibilityRelaunchRequested = "accessibilityRelaunchRequested"
}

enum AccessibilityDiagnosis: Equatable {
    case granted
    case notPrompted
    case promptedAwaitingApproval
    case deniedOrRestricted
    case stillUntrustedAfterRelaunch
    case trustStateMismatch

    var title: String {
        switch self {
        case .granted:
            "Granted"
        case .notPrompted:
            "Not Prompted"
        case .promptedAwaitingApproval:
            "Prompted, Awaiting Approval"
        case .deniedOrRestricted:
            "Denied or Restricted"
        case .stillUntrustedAfterRelaunch:
            "Still Untrusted After Relaunch"
        case .trustStateMismatch:
            "Trust State Mismatch"
        }
    }

    var detail: String {
        switch self {
        case .granted:
            "macOS currently reports this app as trusted for Accessibility."
        case .notPrompted:
            "Head Canon has not yet prompted for Accessibility in this app identity."
        case .promptedAwaitingApproval:
            "Head Canon has already prompted for Accessibility, but macOS has not yet reported this app as trusted."
        case .deniedOrRestricted:
            "macOS is treating Accessibility access as denied or restricted for this app identity."
        case .stillUntrustedAfterRelaunch:
            "Head Canon requested a relaunch after Accessibility setup, but macOS still does not report the app as trusted."
        case .trustStateMismatch:
            "The app-facing Accessibility state and the raw AX trust check do not agree. Treat the raw trust check as authoritative first."
        }
    }

    var nextAction: String {
        switch self {
        case .granted:
            "Move to the TextEdit hotkey smoke test."
        case .notPrompted:
            "Prompt for Accessibility and approve this exact installed app bundle."
        case .promptedAwaitingApproval:
            "Approve the installed app in Accessibility settings, then relaunch the app."
        case .deniedOrRestricted:
            "Open Accessibility settings, re-enable this exact app bundle, then relaunch."
        case .stillUntrustedAfterRelaunch:
            "Treat this as a macOS trust problem first. Do not continue to hotkey or insertion debugging yet."
        case .trustStateMismatch:
            "Refresh permissions again and resolve the trust mismatch before testing hotkeys or insertion."
        }
    }
}

struct PermissionDebugContext {
    let bundlePath: String
    let bundleIdentifier: String
    let isInstalledBundle: Bool
    let microphoneState: PermissionState
    let accessibilityState: PermissionState
    let lastPermissionRefreshDate: Date?
    let lastSelfTestDate: Date?
}

struct PermissionDebugSnapshot: Equatable {
    let bundlePath: String
    let bundleIdentifier: String
    let isInstalledBundle: Bool
    let microphoneState: PermissionState
    let accessibilityState: PermissionState
    let accessibilityTrusted: Bool
    let accessibilityPrompted: Bool
    let accessibilityRelaunchRequested: Bool
    let lastPermissionRefreshDate: Date?
    let lastSelfTestDate: Date?
    let diagnosis: AccessibilityDiagnosis

    static let empty = PermissionDebugSnapshot(
        bundlePath: "",
        bundleIdentifier: "",
        isInstalledBundle: false,
        microphoneState: .notDetermined,
        accessibilityState: .notDetermined,
        accessibilityTrusted: false,
        accessibilityPrompted: false,
        accessibilityRelaunchRequested: false,
        lastPermissionRefreshDate: nil,
        lastSelfTestDate: nil,
        diagnosis: .notPrompted
    )
}

enum PermissionSelfTestStatus: Equatable {
    case passed
    case warning
    case failed

    var title: String {
        switch self {
        case .passed:
            "Passed"
        case .warning:
            "Warning"
        case .failed:
            "Failed"
        }
    }
}

enum PermissionSelfTestKind: String, Equatable, Identifiable {
    case trustCheck
    case targetAppPrecondition
    case focusedApplication
    case focusedElement
    case focusedMetadata
    case insertabilityProbe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trustCheck:
            "Trust Check"
        case .targetAppPrecondition:
            "Target App Precondition"
        case .focusedApplication:
            "Focused Application"
        case .focusedElement:
            "Focused UI Element"
        case .focusedMetadata:
            "Focused Target Metadata"
        case .insertabilityProbe:
            "Insertability Probe"
        }
    }
}

struct PermissionSelfTestResult: Identifiable, Equatable {
    let id = UUID()
    let kind: PermissionSelfTestKind
    let status: PermissionSelfTestStatus
    let summary: String
    let detail: String
    let observedAt: Date
}

@MainActor
protocol PermissionDebugging {
    func snapshot(for context: PermissionDebugContext) -> PermissionDebugSnapshot
    func runSelfTests(using snapshot: PermissionDebugSnapshot) -> [PermissionSelfTestResult]
}

@MainActor
struct PermissionDebugService: PermissionDebugging {
    private let defaults: UserDefaults
    private let accessibilityTrustEvaluator: () -> Bool

    init(
        defaults: UserDefaults = .standard,
        accessibilityTrustEvaluator: @escaping () -> Bool = { AXIsProcessTrusted() }
    ) {
        self.defaults = defaults
        self.accessibilityTrustEvaluator = accessibilityTrustEvaluator
    }

    func snapshot(for context: PermissionDebugContext) -> PermissionDebugSnapshot {
        let accessibilityPrompted = defaults.bool(forKey: PermissionDebugDefaultsKeys.accessibilityPrompted)
        let accessibilityRelaunchRequested = defaults.bool(forKey: PermissionDebugDefaultsKeys.accessibilityRelaunchRequested)
        let accessibilityTrusted = accessibilityTrustEvaluator()

        let diagnosis: AccessibilityDiagnosis
        if context.accessibilityState == .granted && !accessibilityTrusted {
            diagnosis = .trustStateMismatch
        } else if accessibilityTrusted {
            diagnosis = .granted
        } else {
            switch context.accessibilityState {
            case .denied, .restricted:
                diagnosis = .deniedOrRestricted
            case .pending:
                diagnosis = accessibilityRelaunchRequested ? .stillUntrustedAfterRelaunch : .promptedAwaitingApproval
            case .notDetermined:
                diagnosis = accessibilityPrompted ? .promptedAwaitingApproval : .notPrompted
            case .granted:
                diagnosis = .granted
            }
        }

        return PermissionDebugSnapshot(
            bundlePath: context.bundlePath,
            bundleIdentifier: context.bundleIdentifier,
            isInstalledBundle: context.isInstalledBundle,
            microphoneState: context.microphoneState,
            accessibilityState: context.accessibilityState,
            accessibilityTrusted: accessibilityTrusted,
            accessibilityPrompted: accessibilityPrompted,
            accessibilityRelaunchRequested: accessibilityRelaunchRequested,
            lastPermissionRefreshDate: context.lastPermissionRefreshDate,
            lastSelfTestDate: context.lastSelfTestDate,
            diagnosis: diagnosis
        )
    }

    func runSelfTests(using snapshot: PermissionDebugSnapshot) -> [PermissionSelfTestResult] {
        let observedAt = Date()
        let trustCheck = makeTrustCheckResult(using: snapshot, observedAt: observedAt)

        guard trustCheck.status == .passed else {
            return [
                trustCheck,
                makeBlockedResult(.targetAppPrecondition, observedAt: observedAt),
                makeBlockedResult(.focusedApplication, observedAt: observedAt),
                makeBlockedResult(.focusedElement, observedAt: observedAt),
                makeBlockedResult(.focusedMetadata, observedAt: observedAt),
                makeBlockedResult(.insertabilityProbe, observedAt: observedAt),
            ]
        }

        do {
            let target = try focusedTarget()
            let targetAppPrecondition = targetAppPreconditionResult(
                processIdentifier: target.processIdentifier,
                observedAt: observedAt
            )
            guard targetAppPrecondition.status == .passed else {
                return [
                    trustCheck,
                    targetAppPrecondition,
                    makeBlockedResult(.focusedApplication, observedAt: observedAt),
                    makeBlockedResult(.focusedElement, observedAt: observedAt),
                    makeBlockedResult(.focusedMetadata, observedAt: observedAt),
                    makeBlockedResult(.insertabilityProbe, observedAt: observedAt),
                ]
            }

            let metadata = readMetadata(from: target.element)
            return [
                trustCheck,
                targetAppPrecondition,
                PermissionSelfTestResult(
                    kind: .focusedApplication,
                    status: .passed,
                    summary: "Focused application is readable.",
                    detail: "Process identifier: \(target.processIdentifier)",
                    observedAt: observedAt
                ),
                PermissionSelfTestResult(
                    kind: .focusedElement,
                    status: .passed,
                    summary: "Focused UI element is readable.",
                    detail: "Role: \(metadata.role ?? "Unknown")",
                    observedAt: observedAt
                ),
                PermissionSelfTestResult(
                    kind: .focusedMetadata,
                    status: metadata.searchableValues.isEmpty ? .warning : .passed,
                    summary: metadata.searchableValues.isEmpty
                        ? "Focused target metadata is sparse."
                        : "Focused target metadata is readable.",
                    detail: metadataDebugSummary(metadata),
                    observedAt: observedAt
                ),
                insertabilityProbeResult(for: target.element, observedAt: observedAt),
            ]
        } catch {
            let detail = error.localizedDescription
            return [
                trustCheck,
                makeBlockedResult(.targetAppPrecondition, observedAt: observedAt),
                PermissionSelfTestResult(
                    kind: .focusedApplication,
                    status: .failed,
                    summary: "Could not read the focused application.",
                    detail: detail,
                    observedAt: observedAt
                ),
                PermissionSelfTestResult(
                    kind: .focusedElement,
                    status: .failed,
                    summary: "Could not read the focused UI element.",
                    detail: detail,
                    observedAt: observedAt
                ),
                PermissionSelfTestResult(
                    kind: .focusedMetadata,
                    status: .failed,
                    summary: "Could not read focused target metadata.",
                    detail: detail,
                    observedAt: observedAt
                ),
                PermissionSelfTestResult(
                    kind: .insertabilityProbe,
                    status: .failed,
                    summary: "Could not inspect insertability.",
                    detail: detail,
                    observedAt: observedAt
                ),
            ]
        }
    }

    private func makeTrustCheckResult(using snapshot: PermissionDebugSnapshot, observedAt: Date) -> PermissionSelfTestResult {
        let trusted = snapshot.accessibilityTrusted
        return PermissionSelfTestResult(
            kind: .trustCheck,
            status: trusted ? .passed : .failed,
            summary: trusted
                ? "macOS reports this app as trusted for Accessibility."
                : "macOS does not currently report this app as trusted for Accessibility.",
            detail: "AXIsProcessTrusted() == \(trusted)",
            observedAt: observedAt
        )
    }

    private func targetAppPreconditionResult(processIdentifier: pid_t, observedAt: Date) -> PermissionSelfTestResult {
        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier

        guard processIdentifier != currentProcessIdentifier else {
            return PermissionSelfTestResult(
                kind: .targetAppPrecondition,
                status: .warning,
                summary: "Head Canon is frontmost, so focus tests would only inspect the debugger window.",
                detail: "Switch to TextEdit or another target app before running these read-only focus tests.",
                observedAt: observedAt
            )
        }

        return PermissionSelfTestResult(
            kind: .targetAppPrecondition,
            status: .passed,
            summary: "A non-Head Canon target app is frontmost.",
            detail: "Process identifier: \(processIdentifier)",
            observedAt: observedAt
        )
    }

    private func makeBlockedResult(_ kind: PermissionSelfTestKind, observedAt: Date) -> PermissionSelfTestResult {
        PermissionSelfTestResult(
            kind: kind,
            status: .failed,
            summary: "Skipped because Accessibility trust is not available.",
            detail: "Run this test again after macOS reports the app as trusted.",
            observedAt: observedAt
        )
    }

    private func focusedTarget() throws -> PermissionDebugFocusTarget {
        let systemElement = AXUIElementCreateSystemWide()

        guard
            let application = try copyAXUIElementAttribute(kAXFocusedApplicationAttribute, from: systemElement),
            let element = try copyAXUIElementAttribute(kAXFocusedUIElementAttribute, from: systemElement)
        else {
            throw TextInsertionError.focusUnavailable
        }

        let processIdentifier = try processIdentifier(for: application)
        return PermissionDebugFocusTarget(application: application, element: element, processIdentifier: processIdentifier)
    }

    private func readMetadata(from element: AXUIElement) -> SecureTextFieldMetadata {
        SecureTextFieldMetadata(
            role: try? copyStringAttribute(kAXRoleAttribute, from: element),
            subrole: try? copyStringAttribute(kAXSubroleAttribute, from: element),
            roleDescription: try? copyStringAttribute(kAXRoleDescriptionAttribute, from: element),
            title: try? copyStringAttribute(kAXTitleAttribute, from: element),
            description: try? copyStringAttribute(kAXDescriptionAttribute, from: element),
            identifier: try? copyStringAttribute(kAXIdentifierAttribute, from: element),
            placeholderValue: try? copyStringAttribute(kAXPlaceholderValueAttribute, from: element),
            domIdentifier: try? copyStringAttribute("AXDOMIdentifier", from: element)
        )
    }

    private func metadataDebugSummary(_ metadata: SecureTextFieldMetadata) -> String {
        [
            "role=\(metadata.role ?? "nil")",
            "subrole=\(metadata.subrole ?? "nil")",
            "title=\(metadata.title ?? "nil")",
            "identifier=\(metadata.identifier ?? "nil")",
        ].joined(separator: " · ")
    }

    private func insertabilityProbeResult(for element: AXUIElement, observedAt: Date) -> PermissionSelfTestResult {
        let hasValue = (try? copyAttribute(kAXValueAttribute, from: element)) != nil
        let valueSettable = isAttributeSettable(kAXValueAttribute, on: element)
        let hasSelectedTextRange = (try? copyAttribute(kAXSelectedTextRangeAttribute, from: element)) != nil
        let currentValue = (try? copyStringAttribute(kAXValueAttribute, from: element)) ?? nil
        let placeholderValue = (try? copyStringAttribute(kAXPlaceholderValueAttribute, from: element)) ?? nil
        let selectedRange = (try? copySelectedRange(from: element)) ?? nil
        let placeholderLikelyActive = PlaceholderValueClassifier.placeholderLikelyActive(
            currentValue: currentValue,
            placeholderValue: placeholderValue,
            selectedRange: selectedRange
        )

        let status: PermissionSelfTestStatus
        if placeholderLikelyActive {
            status = .warning
        } else if valueSettable && hasSelectedTextRange {
            status = .passed
        } else if hasValue || hasSelectedTextRange {
            status = .warning
        } else {
            status = .failed
        }

        return PermissionSelfTestResult(
            kind: .insertabilityProbe,
            status: status,
            summary: placeholderLikelyActive
                ? "Focused target exposes placeholder-backed AX text, so direct value replacement is unsafe."
                : status == .passed
                    ? "Focused target exposes writable text attributes."
                    : status == .warning
                        ? "Focused target is partially readable, but writable text attributes are incomplete."
                        : "Focused target does not expose the expected writable text attributes.",
            detail: "valueReadable=\(hasValue) · valueSettable=\(valueSettable) · selectedRangeReadable=\(hasSelectedTextRange) · placeholderLikelyActive=\(placeholderLikelyActive)",
            observedAt: observedAt
        )
    }

    private func copyAttribute(_ attribute: String, from element: AXUIElement) throws -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        switch result {
        case .success:
            return value
        case .noValue:
            return nil
        case .apiDisabled:
            throw TextInsertionError.accessibilityPermissionRequired
        default:
            throw TextInsertionError.accessibilityAPIError("Accessibility read failed for \(attribute) with AX error \(result.rawValue).")
        }
    }

    private func copyAXUIElementAttribute(_ attribute: String, from element: AXUIElement) throws -> AXUIElement? {
        guard let value = try copyAttribute(attribute, from: element) else {
            return nil
        }

        guard CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return unsafeDowncast(value, to: AXUIElement.self)
    }

    private func copyStringAttribute(_ attribute: String, from element: AXUIElement) throws -> String? {
        guard let value = try copyAttribute(attribute, from: element) else {
            return nil
        }

        return value as? String
    }

    private func copySelectedRange(from element: AXUIElement) throws -> CFRange? {
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

    private func processIdentifier(for element: AXUIElement) throws -> pid_t {
        var pid: pid_t = 0
        let result = AXUIElementGetPid(element, &pid)

        guard result == .success else {
            throw TextInsertionError.accessibilityAPIError("Could not determine the focused application's process identifier.")
        }

        return pid
    }

    private func isAttributeSettable(_ attribute: String, on element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        return result == .success && settable.boolValue
    }
}

private struct PermissionDebugFocusTarget {
    let application: AXUIElement
    let element: AXUIElement
    let processIdentifier: pid_t
}
