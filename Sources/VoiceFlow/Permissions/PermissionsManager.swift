import AppKit
import AVFoundation
import ApplicationServices
import Foundation

enum PermissionState: Equatable {
    case granted
    case denied
    case notDetermined
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
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
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
        AXIsProcessTrusted() ? .granted : .denied
    }
}
