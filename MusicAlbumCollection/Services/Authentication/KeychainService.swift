import Foundation
import Security

/// Keychain-related errors.
enum KeychainError: LocalizedError, Equatable {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
    case dataConversionError

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "No stored credentials found in Keychain."
        case .duplicateItem:
            return "Item already exists in Keychain."
        case .unexpectedStatus(let status):
            return "Keychain error: OSStatus \(status)."
        case .dataConversionError:
            return "Failed to convert credential data."
        }
    }
}

/// Payload structure for securely serializing credentials into the iOS Keychain.
struct StoredCredentialPayload: Codable, Sendable {
    let username: String
    let password: String
}

/// Protocol defining secure storage operations for user credentials.
protocol KeychainServiceProtocol: Sendable {
    func saveCredentials(username: String, password: String) throws
    func getCredentials() -> (username: String, password: String)?
    func hasCredentials() -> Bool
    func deleteCredentials() throws
}

/// Secure Keychain-backed credential storage implementation.
struct KeychainService: KeychainServiceProtocol {
    private let serviceIdentifier: String
    private let primaryAccountKey: String

    /// Initializes KeychainService with service identifier and account key.
    /// - Parameters:
    ///   - serviceIdentifier: The Keychain service domain identifier.
    ///   - primaryAccountKey: The primary account key identifier.
    init(
        serviceIdentifier: String = "com.typetech.MusicAlbumCollection.auth",
        primaryAccountKey: String = "primary_account"
    ) {
        self.serviceIdentifier = serviceIdentifier
        self.primaryAccountKey = primaryAccountKey
    }

    /// Securely stores or updates credentials in the iOS Keychain without writing to UserDefaults or disk.
    /// - Parameters:
    ///   - username: The master account username.
    ///   - password: The master account password.
    func saveCredentials(username: String, password: String) throws {
        let payload = StoredCredentialPayload(username: username, password: password)
        let encoder = JSONEncoder()
        guard let credentialData = try? encoder.encode(payload) else {
            throw KeychainError.dataConversionError
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: primaryAccountKey
        ]

        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: credentialData,
            kSecAttrDescription as String: username
        ]

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = credentialData
            newItem[kSecAttrDescription as String] = username
            newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Retrieves securely stored credentials without logging or exposing them unsafely.
    /// - Returns: A tuple of (username, password) if credentials exist in Keychain.
    func getCredentials() -> (username: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: primaryAccountKey,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let existingItem = item as? [String: Any],
              let data = existingItem[kSecValueData as String] as? Data else {
            return nil
        }

        if let payload = try? JSONDecoder().decode(StoredCredentialPayload.self, from: data) {
            return (payload.username, payload.password)
        }

        // Backwards compatibility for plain-text password fallback
        if let password = String(data: data, encoding: .utf8),
           let username = existingItem[kSecAttrDescription as String] as? String,
           !username.isEmpty {
            return (username, password)
        }

        return nil
    }

    /// Checks if any user credentials are registered in the Keychain.
    /// - Returns: True if valid credentials exist.
    func hasCredentials() -> Bool {
        getCredentials() != nil
    }

    /// Removes stored credentials from the Keychain.
    func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: primaryAccountKey
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
