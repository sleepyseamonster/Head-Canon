import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show(model: VoiceFlowModel) {
        let window = window ?? makeWindow(model: model)
        refreshWindowContent(window, model: model)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        model.requestStatusRefresh()
    }

    private func makeWindow(model: VoiceFlowModel) -> NSWindow {
        let controller = NSHostingController(rootView: SettingsRootView(model: model))
        let window = NSWindow(contentViewController: controller)
        window.title = "Voice Flow Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 640, height: 720))
        window.minSize = NSSize(width: 540, height: 620)
        window.isReleasedWhenClosed = false
        self.window = window
        return window
    }

    private func refreshWindowContent(_ window: NSWindow, model: VoiceFlowModel) {
        if let hostingController = window.contentViewController as? NSHostingController<SettingsRootView> {
            hostingController.rootView = SettingsRootView(model: model)
        } else {
            window.contentViewController = NSHostingController(rootView: SettingsRootView(model: model))
        }
    }
}
