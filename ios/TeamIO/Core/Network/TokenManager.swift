import Foundation
import Security

actor TokenManager {
    static let shared = TokenManager()

    private let accessTokenKey = "com.getteamio.accessToken"
    private let refreshTokenKey = "com.getteamio.refreshToken"

    // MARK: - Public Interface

    var accessToken: String? {
        get { readKeychain(key: accessTokenKey) }
    }

    var refreshToken: String? {
        get { readKeychain(key: refreshTokenKey) }
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    func store(accessToken: String, refreshToken: String) {
        writeKeychain(key: accessTokenKey, value: accessToken)
        writeKeychain(key: refreshTokenKey, value: refreshToken)
    }

    func clearTokens() {
        deleteKeychain(key: accessTokenKey)
        deleteKeychain(key: refreshTokenKey)
    }

    func updateAccessToken(_ token: String) {
        writeKeychain(key: accessTokenKey, value: token)
    }

    // MARK: - Keychain Operations

    private func writeKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        deleteKeychain(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
