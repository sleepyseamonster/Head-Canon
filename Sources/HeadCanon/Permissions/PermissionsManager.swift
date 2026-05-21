import AppKit
import AVFoundation
import ApplicationServices
import Foundation
import OSLog

enum PermissionState: Equatable {
    case granted
    case denied
    case notDetermined
    case pending
    case restricted

    var isGranted: Bool {
        self == .granted
    }

    var title: String {
        switch self {
        case .granted:
            "Granted"
        case .denied:
            "Denied"
        case .notDetermined:
            "Not Determined"
        case .pending:
            "Pending Approval"
        case .restricted:
            "Restricted"
        }
    }
}

struct PermissionSnapshot: Equatable {
    var microphone: PermissionState = .notDetermined
    var accessibility: PermissionState = .notDetermined

    var isReady: Bool {
        microphone.isGranted && accessibility.isGranted
    }
}

@MainActor
protocol PermissionsManaging {
    func refreshStatus() -> PermissionSnapshot
    func requestMicrophoneAccess() async -> PermissionState
    func promptForAccessibility()
}

@MainActor
struct PermissionsManager: PermissionsManaging {
    private let defaults: UserDefaults = .standard
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "local.headcanon.app",
        category: "permissions"
    )

    func refreshStatus() -> PermissionSnapshot {
        PermissionSnapshot(
            microphone: microphoneState(),
            accessibility: accessibilityState()
        )
    }

    func requestMicrophoneAccess() async -> PermissionState {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        return granted ? .granted : .denied
    }

    func promptForAccessibility() {
        defaults.set(true, forKey: PermissionDebugDefaultsKeys.accessibilityPrompted)
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        logger.notice("Requesting Accessibility trust for bundle at \(Bundle.main.bundleURL.path, privacy: .public)")
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func microphoneState() -> PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            .granted
        case .denied:
            .denied
        case .notDetermined:
            .notDetermined
        case .restricted:
            .restricted
        @unknown default:
            .denied
        }
    }

    private func accessibilityState() -> PermissionState {
        if AXIsProcessTrusted() {
            logger.notice("Accessibility trust is granted for \(Bundle.main.bundleURL.path, privacy: .public)")
            return .granted
        }

        return defaults.bool(forKey: PermissionDebugDefaultsKeys.accessibilityPrompted) ? .pending : .notDetermined
    }
}
