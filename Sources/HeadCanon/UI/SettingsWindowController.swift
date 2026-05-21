import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private weak var currentModel: HeadCanonModel?

    func show(model: HeadCanonModel) {
        currentModel = model
        let window = window ?? makeWindow(model: model)
        refreshWindowContent(window, model: model)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @discardableResult
    func showLastKnownWindow() -> Bool {
        guard let currentModel else {
            return false
        }

        show(model: currentModel)
        return true
    }

    private func makeWindow(model: HeadCanonModel) -> NSWindow {
        let controller = NSHostingController(rootView: SettingsRootView(model: model))
        let window = NSWindow(contentViewController: controller)
        window.title = "Head Canon Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 640, height: 720))
        window.minSize = NSSize(width: 540, height: 620)
        window.isReleasedWhenClosed = false
        self.window = window
        return window
    }

    private func refreshWindowContent(_ window: NSWindow, model: HeadCanonModel) {
        if let hostingController = window.contentViewController as? NSHostingController<SettingsRootView> {
            hostingController.rootView = SettingsRootView(model: model)
        } else {
            window.contentViewController = NSHostingController(rootView: SettingsRootView(model: model))
        }
    }
}
