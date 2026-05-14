import AppKit
import ApplicationServices
import Foundation

enum TextInsertionError: LocalizedError {
    case focusUnavailable
    case unsupportedTarget
    case pasteFailed
    case secureTarget
    case focusChanged

    var errorDescription: String? {
        switch self {
        case .focusUnavailable:
            "Voice Flow could not find a focused editable target."
        case .unsupportedTarget:
            "The focused target does not support direct insertion or paste fallback."
        case .pasteFailed:
            "Voice Flow could not paste into the focused app."
        case .secureTarget:
            "Voice Flow will not insert dictated text into a secure text field."
        case .focusChanged:
            "The focused target changed before paste fallback could complete."
        }
    }
}

@MainActor
protocol TextInsertionServicing {
    func insert(_ text: String, preservingClipboard: Bool) async throws
}

@MainActor
struct TextInsertionService: TextInsertionServicing {
    func insert(_ text: String, preservingClipboard: Bool) async throws {
        let target = try focusedTarget()

        if isSecureTextField(target.element) {
            throw TextInsertionError.secureTarget
        }

        if try directInsert(text: text, into: target.element) {
            return
        }

        try validateFocusUnchanged(from: target)
        try await paste(text: text, preservingClipboard: preservingClipboard)
    }

    private func focusedTarget() throws -> FocusTarget {
        let systemElement = AXUIElementCreateSystemWide()

        guard
            let application = copyAXUIElementAttribute(kAXFocusedApplicationAttribute, from: systemElement),
            let element = copyAXUIElementAttribute(kAXFocusedUIElementAttribute, from: systemElement)
        else {
            throw TextInsertionError.focusUnavailable
        }

        return FocusTarget(application: application, element: element)
    }

    private func directInsert(text: String, into element: AXUIElement) throws -> Bool {
        guard
            let currentValue = copyAttribute(kAXValueAttribute, from: element) as? String,
            isAttributeSettable(kAXValueAttribute, on: element)
        else {
            return false
        }

        guard let selectedTextRange = copyAttribute(kAXSelectedTextRangeAttribute, from: element) else {
            return false
        }

        guard CFGetTypeID(selectedTextRange) == AXValueGetTypeID() else {
            return false
        }

        let rangeValue = unsafeDowncast(selectedTextRange, to: AXValue.self)
        guard AXValueGetType(rangeValue) == .cfRange else { return false }

        var selectedRange = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &selectedRange) else {
            return false
        }

        let currentNSString = currentValue as NSString
        let location = max(0, min(selectedRange.location, currentNSString.length))
        let length = max(0, min(selectedRange.length, currentNSString.length - location))
        let safeRange = NSRange(location: location, length: length)
        let updatedValue = currentNSString.replacingCharacters(in: safeRange, with: text)

        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            updatedValue as CFTypeRef
        )

        guard setResult == .success else {
            return false
        }

        var cursorRange = CFRange(location: location + (text as NSString).length, length: 0)

        if let newRange = AXValueCreate(.cfRange, &cursorRange) {
            _ = AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextRangeAttribute as CFString,
                newRange
            )
        }

        return true
    }

    private func validateFocusUnchanged(from originalTarget: FocusTarget) throws {
        let currentTarget = try focusedTarget()

        guard
            CFEqual(currentTarget.application, originalTarget.application),
            CFEqual(currentTarget.element, originalTarget.element)
        else {
            throw TextInsertionError.focusChanged
        }

        if isSecureTextField(currentTarget.element) {
            throw TextInsertionError.secureTarget
        }
    }

    private func paste(text: String, preservingClipboard: Bool) async throws {
        let pasteboard = NSPasteboard.general
        let snapshot = preservingClipboard ? PasteboardSnapshot.capture(from: pasteboard) : nil

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw TextInsertionError.pasteFailed
        }

        guard simulatePasteKeystroke() else {
            if let snapshot {
                snapshot.restore(to: pasteboard)
            }
            throw TextInsertionError.pasteFailed
        }

        if let snapshot {
            try? await Task.sleep(for: .milliseconds(350))
            snapshot.restore(to: pasteboard)
        }
    }

    private func simulatePasteKeystroke() -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        let commandFlags: CGEventFlags = .maskCommand
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else {
            return false
        }

        keyDown.flags = commandFlags
        keyUp.flags = commandFlags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func isSecureTextField(_ element: AXUIElement) -> Bool {
        guard let subrole = copyAttribute(kAXSubroleAttribute, from: element) as? String else {
            return false
        }

        return subrole == (kAXSecureTextFieldSubrole as String)
    }

    private func copyAttribute(_ attribute: String, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else {
            return nil
        }

        return value
    }

    private func copyAXUIElementAttribute(_ attribute: String, from element: AXUIElement) -> AXUIElement? {
        guard
            let value = copyAttribute(attribute, from: element),
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
}

private struct FocusTarget {
    let application: AXUIElement
    let element: AXUIElement
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
