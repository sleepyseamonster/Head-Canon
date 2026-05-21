import AppKit
import Carbon.HIToolbox
import Foundation

@MainActor
protocol HotkeyManaging: AnyObject {
    func register(
        shortcut: HotkeyShortcut,
        onPress: @escaping @MainActor () -> Void,
        onRelease: @escaping @MainActor (HotkeyReleaseContext) -> Void
    ) throws
    func unregister()
}

enum HotkeyRegistrationError: LocalizedError {
    case handlerInstallFailed(OSStatus)
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .handlerInstallFailed(let status):
            "Head Canon could not install the hotkey handler (OSStatus \(status))."
        case .registrationFailed(let status):
            "Head Canon could not register the hotkey (OSStatus \(status))."
        }
    }
}

@MainActor
final class HotkeyManager: HotkeyManaging {
    fileprivate static var sharedHandler: EventHandlerRef?
    fileprivate static weak var activeManager: HotkeyManager?
    fileprivate static let hotkeySignature = fourCharCode("VFLW")

    private var onPress: (@MainActor () -> Void)?
    private var onRelease: (@MainActor (HotkeyReleaseContext) -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var trackedShortcut: HotkeyShortcut?
    private var registeredHotKeyID: UInt32?
    private var trackedModifierFlags: NSEvent.ModifierFlags?
    private var isModifierShortcutPressed = false

    func register(
        shortcut: HotkeyShortcut,
        onPress: @escaping @MainActor () -> Void,
        onRelease: @escaping @MainActor (HotkeyReleaseContext) -> Void
    ) throws {
        unregister()
        trackedShortcut = shortcut
        self.onPress = onPress
        self.onRelease = onRelease

        switch shortcut.trigger {
        case .key(let keyCode, let carbonModifiers):
            try Self.installHandlerIfNeeded()

            let hotKeyID = EventHotKeyID(signature: Self.hotkeySignature, id: 1)
            let status = RegisterEventHotKey(
                keyCode,
                carbonModifiers,
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
        case .modifierHold(let requiredModifiers):
            trackedModifierFlags = Self.normalizedModifierFlags(requiredModifiers)
            installModifierFlagsMonitors()
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let globalFlagsMonitor {
            NSEvent.removeMonitor(globalFlagsMonitor)
            self.globalFlagsMonitor = nil
        }

        if let localFlagsMonitor {
            NSEvent.removeMonitor(localFlagsMonitor)
            self.localFlagsMonitor = nil
        }

        if Self.activeManager === self {
            Self.activeManager = nil
        }

        trackedModifierFlags = nil
        isModifierShortcutPressed = false
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
            onRelease?(
                HotkeyReleaseContext(
                    source: .carbonKeyUp,
                    observedAt: Date()
                )
            )
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

    private func installModifierFlagsMonitors() {
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let modifierFlags = event.modifierFlags
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    self?.handleModifierFlagsChanged(modifierFlags, source: .globalModifierMonitor)
                }
            }
        }

        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let modifierFlags = event.modifierFlags
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    self?.handleModifierFlagsChanged(modifierFlags, source: .localModifierMonitor)
                }
            }
            return event
        }
    }

    private func handleModifierFlagsChanged(_ flags: NSEvent.ModifierFlags, source: HotkeyReleaseSource) {
        guard let trackedModifierFlags else {
            return
        }

        let normalizedFlags = Self.normalizedModifierFlags(flags)
        let isPressed = normalizedFlags == trackedModifierFlags
        guard isPressed != isModifierShortcutPressed else {
            return
        }

        isModifierShortcutPressed = isPressed

        if isPressed {
            onPress?()
        } else {
            onRelease?(
                HotkeyReleaseContext(
                    source: source,
                    observedAt: Date()
                )
            )
        }
    }

    private static func normalizedModifierFlags(_ flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection([.command, .control, .option, .shift])
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
    DispatchQueue.main.async {
        MainActor.assumeIsolated {
            HotkeyManager.activeManager?.handleHotkeyEvent(kind: kind, hotKeyID: hotKeyID)
        }
    }

    return noErr
}
