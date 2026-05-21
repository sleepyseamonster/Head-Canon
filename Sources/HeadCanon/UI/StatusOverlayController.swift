import AppKit
import SwiftUI

@MainActor
protocol StatusOverlayPresenting {
    func update(status: WorkflowStatus, detail: String?)
}

struct StatusOverlayGeometry {
    static let hudSize = NSSize(width: 44, height: 44)
    static let inset: CGFloat = 18

    static func targetFrame(in visibleFrame: NSRect) -> NSRect {
        NSRect(
            x: visibleFrame.maxX - hudSize.width - inset,
            y: visibleFrame.minY + inset,
            width: hudSize.width,
            height: hudSize.height
        )
    }
}

@MainActor
final class StatusOverlayController: StatusOverlayPresenting {
    static let shared = StatusOverlayController()

    private var panel: NSPanel?
    private var hostingController: NSHostingController<StatusOverlayView>?
    private var dismissTask: Task<Void, Never>?
    private var ownedScreenNumber: NSNumber?

    private init() {
        ownedScreenNumber = Self.screenNumber(for: Self.pointerScreen() ?? NSScreen.screens.first)
        _ = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleScreenParametersChanged()
            }
        }
    }

    func update(status: WorkflowStatus, detail: String?) {
        switch status {
        case .ready, .setupRequired:
            dismiss(after: .zero)
        case .recording, .transcribing:
            dismissTask?.cancel()
            show(status: status)
        case .inserted:
            show(status: status)
            dismiss(after: .seconds(1.2))
        case .failed:
            show(status: status)
            dismiss(after: .seconds(2.4))
        }
    }

    private func show(status: WorkflowStatus) {
        let panel = ensurePanel()
        hostingController?.rootView = StatusOverlayView(status: status)
        enforcePanelSize(panel)
        position(panel)
        panel.orderFrontRegardless()
    }

    private func dismiss(after delay: Duration) {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor [weak self] in
            if delay != .zero {
                try? await Task.sleep(for: delay)
            }

            guard !Task.isCancelled else {
                return
            }

            self?.panel?.orderOut(nil)
        }
    }

    private func ensurePanel() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: StatusOverlayGeometry.hudSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        if #available(macOS 13.0, *) {
            panel.collectionBehavior.insert(.canJoinAllApplications)
        }

        let hostingController = NSHostingController(rootView: StatusOverlayView(status: .ready))
        panel.contentViewController = hostingController
        enforcePanelSize(panel)

        self.hostingController = hostingController
        self.panel = panel
        return panel
    }

    private func enforcePanelSize(_ panel: NSPanel) {
        panel.setContentSize(StatusOverlayGeometry.hudSize)
        panel.contentView?.frame = NSRect(origin: .zero, size: StatusOverlayGeometry.hudSize)
        panel.contentViewController?.view.frame = NSRect(origin: .zero, size: StatusOverlayGeometry.hudSize)
    }

    private func position(_ panel: NSPanel) {
        guard let screen = ownedScreen() else {
            return
        }

        enforcePanelSize(panel)
        let targetFrame = StatusOverlayGeometry.targetFrame(in: screen.visibleFrame)
        let constrainedFrame = panel.constrainFrameRect(targetFrame, to: screen)
        panel.setFrame(constrainedFrame, display: false)
    }

    private func handleScreenParametersChanged() {
        if ownedScreen() == nil {
            ownedScreenNumber = Self.screenNumber(for: Self.pointerScreen() ?? NSScreen.screens.first)
        }

        if let panel {
            position(panel)
        }
    }

    private func ownedScreen() -> NSScreen? {
        if let ownedScreenNumber,
           let screen = NSScreen.screens.first(where: { Self.screenNumber(for: $0) == ownedScreenNumber }) {
            return screen
        }

        let fallbackScreen = Self.pointerScreen() ?? NSScreen.screens.first
        ownedScreenNumber = Self.screenNumber(for: fallbackScreen)
        return fallbackScreen
    }

    private static func pointerScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
    }

    private static func screenNumber(for screen: NSScreen?) -> NSNumber? {
        screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
    }
}

private struct StatusOverlayView: View {
    let status: WorkflowStatus

    var body: some View {
        let appearance = OverlayAppearance(status: status)

        ZStack {
            Circle()
                .fill(Color.black.opacity(0.86))

            Circle()
                .strokeBorder(appearance.tint.opacity(0.9), lineWidth: 2)

            Image(systemName: appearance.symbolName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating, isActive: status == .recording)
        }
        .frame(width: StatusOverlayGeometry.hudSize.width, height: StatusOverlayGeometry.hudSize.height)
    }
}

private struct OverlayAppearance {
    let symbolName: String
    let tint: Color

    init(status: WorkflowStatus) {
        switch status {
        case .recording:
            symbolName = "mic.fill"
            tint = .red
        case .transcribing:
            symbolName = "waveform.and.magnifyingglass"
            tint = Color(
                red: 37 / 255,
                green: 169 / 255,
                blue: 191 / 255
            )
        case .inserted:
            symbolName = "checkmark.circle.fill"
            tint = .green
        case .failed:
            symbolName = "exclamationmark.triangle.fill"
            tint = .yellow
        case .ready, .setupRequired:
            symbolName = "mic.circle.fill"
            tint = .secondary
        }
    }
}
