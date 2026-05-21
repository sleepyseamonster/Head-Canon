import AppKit
import Carbon.HIToolbox
import CryptoKit
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
            "Keep for this app session"
        case .keepForever:
            "Keep until you clear it"
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

enum OpenAITranscriptionModel: String, CaseIterable, Identifiable {
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
    case gpt4oTranscribe = "gpt-4o-transcribe"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gpt4oMiniTranscribe:
            "gpt-4o-mini-transcribe"
        case .gpt4oTranscribe:
            "gpt-4o-transcribe"
        }
    }

    var detail: String {
        switch self {
        case .gpt4oMiniTranscribe:
            "Faster and cheaper. Best for low-latency experimentation."
        case .gpt4oTranscribe:
            "Higher-quality baseline. Best for accuracy comparisons."
        }
    }
}

enum HotkeyTrigger: Equatable {
    case key(keyCode: UInt32, carbonModifiers: UInt32)
    case modifierHold(requiredModifiers: NSEvent.ModifierFlags)
}

struct HotkeyShortcut: Equatable {
    enum Identifier: String {
        case controlOptionSpace
        case modifierHoldControlOption
        case modifierHoldControlOptionExperimental
    }

    let trigger: HotkeyTrigger
    let displayString: String
    let identifier: Identifier

    static let defaultPushToTalk = HotkeyShortcut(
        trigger: .modifierHold(requiredModifiers: [.control, .option]),
        displayString: "Hold Control + Option",
        identifier: .modifierHoldControlOption
    )

    static let spacePushToTalk = HotkeyShortcut(
        trigger: .key(
            keyCode: 49,
            carbonModifiers: UInt32(controlKey | optionKey)
        ),
        displayString: "Control + Option + Space",
        identifier: .controlOptionSpace
    )

    static let modifierHoldControlOption = defaultPushToTalk

    static let allShortcuts: [HotkeyShortcut] = [
        .defaultPushToTalk,
        .spacePushToTalk,
    ]

    static func fromStoredIdentifier(_ rawValue: String?) -> HotkeyShortcut {
        switch Identifier(rawValue: rawValue ?? "") {
        case .controlOptionSpace:
            .spacePushToTalk
        case .modifierHoldControlOption:
            .defaultPushToTalk
        case .modifierHoldControlOptionExperimental:
            .defaultPushToTalk
        case .none:
            .defaultPushToTalk
        }
    }
}

@MainActor
@Observable
final class AppPreferences {
    private enum Keys {
        static let hotkeyIdentifier = "hotkeyIdentifier"
        static let selectedMicrophoneID = "selectedMicrophoneID"
        static let historyRetentionMode = "historyRetentionMode"
        static let pasteFallbackEnabled = "pasteFallbackEnabled"
        static let transcriptionModel = "transcriptionModel"
        static let lastValidatedAPIKeyFingerprint = "lastValidatedAPIKeyFingerprint"
        static let lastValidationDate = "lastValidationDate"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var hotkey: HotkeyShortcut {
        didSet {
            defaults.set(hotkey.identifier.rawValue, forKey: Keys.hotkeyIdentifier)
        }
    }
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
    var openAITranscriptionModel: OpenAITranscriptionModel {
        didSet {
            defaults.set(openAITranscriptionModel.rawValue, forKey: Keys.transcriptionModel)
        }
    }

    var lastValidatedAPIKeyFingerprint: String? {
        defaults.string(forKey: Keys.lastValidatedAPIKeyFingerprint)
    }

    var lastValidationDate: Date? {
        defaults.object(forKey: Keys.lastValidationDate) as? Date
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hotkey = HotkeyShortcut.fromStoredIdentifier(
            defaults.string(forKey: Keys.hotkeyIdentifier)
        )
        self.selectedMicrophoneID = defaults.string(forKey: Keys.selectedMicrophoneID)
        self.historyRetentionMode =
            HistoryRetentionMode(rawValue: defaults.string(forKey: Keys.historyRetentionMode) ?? "")
            ?? .thirtyDays
        self.pasteFallbackEnabled = defaults.object(forKey: Keys.pasteFallbackEnabled) as? Bool ?? true
        self.openAITranscriptionModel =
            OpenAITranscriptionModel(rawValue: defaults.string(forKey: Keys.transcriptionModel) ?? "")
            ?? .gpt4oMiniTranscribe
    }

    func persistValidatedAPIKey(_ apiKey: String, validatedAt: Date) {
        defaults.set(Self.apiKeyFingerprint(for: apiKey), forKey: Keys.lastValidatedAPIKeyFingerprint)
        defaults.set(validatedAt, forKey: Keys.lastValidationDate)
    }

    func clearValidatedAPIKeyState() {
        defaults.removeObject(forKey: Keys.lastValidatedAPIKeyFingerprint)
        defaults.removeObject(forKey: Keys.lastValidationDate)
    }

    func hasCachedValidation(for apiKey: String) -> Bool {
        lastValidatedAPIKeyFingerprint == Self.apiKeyFingerprint(for: apiKey)
    }

    private static func apiKeyFingerprint(for apiKey: String) -> String {
        let digest = SHA256.hash(data: Data(apiKey.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
