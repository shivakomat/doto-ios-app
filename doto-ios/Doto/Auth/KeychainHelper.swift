import Foundation
import Security

struct KeychainHelper {
    private static let service = "com.doto.app"
    private static let account = "jwt_token"

    // In-memory cache guards against transient Keychain failures in the simulator
    private static var _cachedToken: String?

    static func saveToken(_ token: String) {
        _cachedToken = token
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData: data
        ]
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        NSLog("[DOTO] KeychainHelper: token saved (len=\(token.count))")
    }

    static func loadToken() -> String? {
        if let cached = _cachedToken {
            NSLog("[DOTO] KeychainHelper: token from cache (len=\(cached.count))")
            return cached
        }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            NSLog("[DOTO] KeychainHelper: loadToken returned nil (status=\(status))")
            return nil
        }
        _cachedToken = token
        NSLog("[DOTO] KeychainHelper: token from keychain (len=\(token.count))")
        return token
    }

    static func deleteToken() {
        _cachedToken = nil
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
        NSLog("[DOTO] KeychainHelper: token deleted")
    }
}
