import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            sender.activate(ignoringOtherApps: true)
            return true
        }

        if SettingsWindowController.shared.showLastKnownWindow() {
            return true
        }

        sender.activate(ignoringOtherApps: true)
        return true
    }
}
