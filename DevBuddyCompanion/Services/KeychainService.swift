import Foundation
import Security

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
}

struct KeychainService {
    private static let service = "com.devbuddy.companion"
    private static let tokenAccount = "api-token"
    private static let importSecretAccount = "import-secret"

    // MARK: - Token

    static func save(token: String) throws {
        try saveItem(account: tokenAccount, value: token)
    }

    static func load() -> String? {
        loadItem(account: tokenAccount)
    }

    static func getToken() -> String? {
        load()
    }

    static func delete() throws {
        try deleteItem(account: tokenAccount)
    }

    // MARK: - Import Secret

    static func saveImportSecret(_ secret: String) throws {
        try saveItem(account: importSecretAccount, value: secret)
    }

    static func loadImportSecret() -> String? {
        loadItem(account: importSecretAccount)
    }

    static func deleteImportSecret() throws {
        try deleteItem(account: importSecretAccount)
    }

    // MARK: - Generic Keychain Operations

    private static func saveItem(account: String, value: String) throws {
        let data = Data(value.utf8)

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private static func loadItem(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func deleteItem(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
