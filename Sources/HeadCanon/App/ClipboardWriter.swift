import AppKit
import Foundation

protocol ClipboardWriting {
    @discardableResult
    func write(_ text: String) -> Bool
}

struct SystemClipboardWriter: ClipboardWriting {
    @discardableResult
    func write(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
