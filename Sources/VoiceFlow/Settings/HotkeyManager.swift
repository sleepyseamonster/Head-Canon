import Carbon.HIToolbox
import Foundation

@MainActor
protocol HotkeyManaging: AnyObject {
    func register(shortcut: HotkeyShortcut, onPress: @escaping @MainActor () -> Void, onRelease: @escaping @MainActor () -> Void) throws
    func unregister()
}

enum HotkeyRegistrationError: LocalizedError {
    case handlerInstallFailed(OSStatus)
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .handlerInstallFailed(let status):
            "Voice Flow could not install the hotkey handler (OSStatus \(status))."
        case .registrationFailed(let status):
            "Voice Flow could not register the hotkey (OSStatus \(status))."
        }
    }
}

@MainActor
final class HotkeyManager: HotkeyManaging {
    fileprivate static var sharedHandler: EventHandlerRef?
    fileprivate static weak var activeManager: HotkeyManager?
    fileprivate static let hotkeySignature = fourCharCode("VFLW")

    private var onPress: (@MainActor () -> Void)?
    private var onRelease: (@MainActor () -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var trackedShortcut: HotkeyShortcut?
    private var registeredHotKeyID: UInt32?

    func register(shortcut: HotkeyShortcut, onPress: @escaping @MainActor () -> Void, onRelease: @escaping @MainActor () -> Void) throws {
        unregister()
        trackedShortcut = shortcut
        self.onPress = onPress
        self.onRelease = onRelease
        try Self.installHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: Self.hotkeySignature, id: 1)
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            UInt32(shortcut.carbonModifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            self.onPress = nil
            self.onRelease = nil
            trackedShortcut = nil
            throw HotkeyRegistrationError.registrationFailed(status)
        }

        registeredHotKeyID = hotKeyID.id
        Self.activeManager = self
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if Self.activeManager === self {
            Self.activeManager = nil
        }

        registeredHotKeyID = nil
        trackedShortcut = nil
        onPress = nil
        onRelease = nil
    }

    fileprivate func handleHotkeyEvent(kind: UInt32, hotKeyID: EventHotKeyID) {
        guard hotKeyID.signature == Self.hotkeySignature, hotKeyID.id == registeredHotKeyID else {
            return
        }

        switch kind {
        case UInt32(kEventHotKeyPressed):
            onPress?()
        case UInt32(kEventHotKeyReleased):
            onRelease?()
        default:
            break
        }
    }

    private static func installHandlerIfNeeded() throws {
        guard sharedHandler == nil else {
            return
        }

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            2,
            &eventTypes,
            nil,
            &sharedHandler
        )

        guard status == noErr else {
            throw HotkeyRegistrationError.handlerInstallFailed(status)
        }
    }
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { partialResult, character in
        (partialResult << 8) + OSType(character)
    }
}

private func hotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID()
    let parameterStatus = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard parameterStatus == noErr else {
        return parameterStatus
    }

    let kind = GetEventKind(event)
    Task { @MainActor in
        HotkeyManager.activeManager?.handleHotkeyEvent(kind: kind, hotKeyID: hotKeyID)
    }

    return noErr
}
