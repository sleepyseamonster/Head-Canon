import Carbon.HIToolbox
import Foundation
import Observation

enum HistoryRetentionMode: String, CaseIterable, Identifiable {
    case thirtyDays
    case keepForever
    case neverStore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thirtyDays:
            "Auto-delete after 30 days"
        case .keepForever:
            "Keep until deleted"
        case .neverStore:
            "Never store"
        }
    }

    var currentBehaviorDetail: String {
        switch self {
        case .thirtyDays:
            "Current v1 behavior: keep only the last transcript in memory for this app session."
        case .keepForever:
            "Current v1 behavior: keep only the last transcript in memory until you clear it or quit the app."
        case .neverStore:
            "Current v1 behavior: do not retain transcript text after insertion or failure."
        }
    }
}

struct HotkeyShortcut: Equatable {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let displayString: String

    static let defaultPushToTalk = HotkeyShortcut(
        keyCode: 49,
        carbonModifiers: UInt32(controlKey | optionKey),
        displayString: "Control + Option + Space"
    )
}

@MainActor
@Observable
final class AppPreferences {
    private enum Keys {
        static let selectedMicrophoneID = "selectedMicrophoneID"
        static let historyRetentionMode = "historyRetentionMode"
        static let pasteFallbackEnabled = "pasteFallbackEnabled"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var hotkey: HotkeyShortcut = .defaultPushToTalk
    var selectedMicrophoneID: String? {
        didSet {
            defaults.set(selectedMicrophoneID, forKey: Keys.selectedMicrophoneID)
        }
    }
    var historyRetentionMode: HistoryRetentionMode {
        didSet {
            defaults.set(historyRetentionMode.rawValue, forKey: Keys.historyRetentionMode)
        }
    }
    var pasteFallbackEnabled: Bool {
        didSet {
            defaults.set(pasteFallbackEnabled, forKey: Keys.pasteFallbackEnabled)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedMicrophoneID = defaults.string(forKey: Keys.selectedMicrophoneID)
        self.historyRetentionMode =
            HistoryRetentionMode(rawValue: defaults.string(forKey: Keys.historyRetentionMode) ?? "")
            ?? .thirtyDays
        self.pasteFallbackEnabled = defaults.object(forKey: Keys.pasteFallbackEnabled) as? Bool ?? true
    }
}
