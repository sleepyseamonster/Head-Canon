import Foundation
import Security

enum APIKeyStoreError: LocalizedError, Equatable {
    case fileAccessFailed(String)
    case loadFailed(OSStatus)
    case migrationFailed(String)
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .fileAccessFailed(let message):
            "Head Canon could not access the legacy stored OpenAI API key file: \(message)"
        case .loadFailed(let status):
            "Head Canon could not access the stored OpenAI API key in Keychain (OSStatus \(status))."
        case .migrationFailed(let message):
            "Head Canon could not migrate a legacy plaintext API key into Keychain: \(message)"
        case .unexpectedStatus(let status):
            "Head Canon hit a Keychain error (OSStatus \(status))."
        }
    }
}

protocol APIKeyStoring {
    func loadAPIKey() throws -> String?
    func saveAPIKey(_ apiKey: String) throws
    func removeAPIKey() throws
}

struct SecureAPIKeyStore: APIKeyStoring {
    private let primaryStore: any APIKeyStoring
    private let legacyPlaintextStore: any APIKeyStoring

    init(
        primaryStore: any APIKeyStoring = KeychainAPIKeyStore(),
        legacyPlaintextStore: any APIKeyStoring = LegacyPlaintextAPIKeyStore()
    ) {
        self.primaryStore = primaryStore
        self.legacyPlaintextStore = legacyPlaintextStore
    }

    func loadAPIKey() throws -> String? {
        if let apiKey = try normalizedKey(from: primaryStore.loadAPIKey()) {
            return apiKey
        }

        guard let legacyAPIKey = try normalizedKey(from: legacyPlaintextStore.loadAPIKey()) else {
            return nil
        }

        do {
            try primaryStore.saveAPIKey(legacyAPIKey)
            try legacyPlaintextStore.removeAPIKey()
        } catch let error as APIKeyStoreError {
            throw error
        } catch {
            throw APIKeyStoreError.migrationFailed(error.localizedDescription)
        }

        return legacyAPIKey
    }

    func saveAPIKey(_ apiKey: String) throws {
        try primaryStore.saveAPIKey(apiKey)
        try removeLegacyPlaintextKeyIfPresent()
    }

    func removeAPIKey() throws {
        try primaryStore.removeAPIKey()
        try removeLegacyPlaintextKeyIfPresent()
    }

    private func removeLegacyPlaintextKeyIfPresent() throws {
        do {
            try legacyPlaintextStore.removeAPIKey()
        } catch let error as APIKeyStoreError {
            throw error
        } catch {
            throw APIKeyStoreError.migrationFailed(error.localizedDescription)
        }
    }

    private func normalizedKey(from value: String?) throws -> String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

struct LegacyPlaintextAPIKeyStore: APIKeyStoring {
    private let fileManager: FileManager
    private let appSupportDirectoryURL: URL?

    init(
        fileManager: FileManager = .default,
        appSupportDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.appSupportDirectoryURL = appSupportDirectoryURL
    }

    func loadAPIKey() throws -> String? {
        let fileURL = try apiKeyFileURL()

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            guard let value = String(data: data, encoding: .utf8) else {
                throw APIKeyStoreError.fileAccessFailed("The stored API key is not valid UTF-8.")
            }

            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue.isEmpty ? nil : trimmedValue
        } catch let error as APIKeyStoreError {
            throw error
        } catch {
            throw APIKeyStoreError.fileAccessFailed(error.localizedDescription)
        }
    }

    func saveAPIKey(_ apiKey: String) throws {
        let fileURL = try apiKeyFileURL()
        let directoryURL = fileURL.deletingLastPathComponent()
        let data = Data(apiKey.utf8)

        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )

            try data.write(to: fileURL, options: [.atomic])
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            throw APIKeyStoreError.fileAccessFailed(error.localizedDescription)
        }

    }

    func removeAPIKey() throws {
        let fileURL = try apiKeyFileURL()

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            throw APIKeyStoreError.fileAccessFailed(error.localizedDescription)
        }
    }

    private func apiKeyFileURL() throws -> URL {
        if let appSupportDirectoryURL {
            return appSupportDirectoryURL
                .appendingPathComponent("HeadCanon", isDirectory: true)
                .appendingPathComponent("openai_api_key.txt", isDirectory: false)
        }

        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw APIKeyStoreError.fileAccessFailed("Application Support is unavailable.")
        }

        return appSupportURL
            .appendingPathComponent("HeadCanon", isDirectory: true)
            .appendingPathComponent("openai_api_key.txt", isDirectory: false)
    }
}

struct KeychainAPIKeyStore: APIKeyStoring {
    private let service = "local.headcanon"
    private let account = "openai_api_key"

    func loadAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess else {
            throw APIKeyStoreError.loadFailed(status)
        }

        guard
            let data = item as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            throw APIKeyStoreError.loadFailed(errSecDecode)
        }

        return value
    }

    func saveAPIKey(_ apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw APIKeyStoreError.unexpectedStatus(errSecParam)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw APIKeyStoreError.unexpectedStatus(addStatus)
            }
        default:
            throw APIKeyStoreError.unexpectedStatus(updateStatus)
        }
    }

    func removeAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyStoreError.unexpectedStatus(status)
        }
    }
}
