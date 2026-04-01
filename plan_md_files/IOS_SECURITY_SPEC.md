# Doto — iOS Security Spec
**Version:** 1.0
**Feature:** iOS client hardening — certificate pinning, Keychain, token handling, safe logging
**Scope:** SwiftUI iOS
**Depends on:** Core IOS_SPEC.md, ONBOARDING_IOS_SPEC.md

---

## 1. Overview

Security on the iOS side falls into five areas. The backend does the heavy lifting
but the iOS app has its own responsibilities — especially around token storage,
network trust, and not leaking data in logs or caches.

| Priority | Area |
|---|---|
| 🔴 | Token storage — Keychain only, never UserDefaults |
| 🔴 | 429 / 423 error handling — graceful UI, no retry storms |
| 🔴 | No sensitive data in logs |
| 🟡 | Certificate pinning — refuse connections to untrusted servers |
| 🟡 | App backgrounding — clear sensitive views when app goes to background |
| 🟠 | Biometric re-authentication on return from background |
| 🟠 | Jailbreak detection |

---

## 2. Token Storage 🔴

Already specced in `IOS_SPEC.md` via `KeychainHelper`. Documenting here for completeness
and to add the `logout` call to the API.

### 2.1 Rules

- JWT is stored **exclusively in Keychain** — never `UserDefaults`, never `@AppStorage`,
  never in memory beyond the current session
- On logout: delete from Keychain AND call `POST /api/auth/logout` to blocklist the token
  server-side
- On 401 response from any endpoint: delete from Keychain and transition to
  `.unauthenticated` state

### 2.2 Updated AuthViewModel.logout()

```swift
// Auth/AuthViewModel.swift
func logout() async {
    // 1. Call logout endpoint to blocklist the JWT server-side
    // Fire and forget — if it fails, token expires naturally in 7 days
    if KeychainHelper.loadToken() != nil {
        _ = try? await APIClient.shared.post(
            "/auth/logout",
            body: EmptyBody()
        ) as EmptyResponse
    }

    // 2. Always clear local state regardless of API result
    KeychainHelper.deleteToken()
    currentProfile = nil
    state = .unauthenticated
}
```

**Important:** Clear the Keychain token first in case the API call hangs.
The user should always be able to log out even if the network is down.

### 2.3 KeychainHelper — Verified Implementation

The accessibility level must be `kSecAttrAccessibleAfterFirstUnlock` — this allows
the token to be read when the app wakes from background (e.g. for push notification
handling) without requiring the device to be unlocked first:

```swift
// Auth/KeychainHelper.swift
struct KeychainHelper {
    private static let service = "com.doto.app"
    private static let account = "jwt_token"

    static func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass:                 kSecClassGenericPassword,
            kSecAttrService:           service,
            kSecAttrAccount:           account,
            kSecValueData:             data,
            kSecAttrAccessible:        kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            // Keychain write failed — token not saved
            // This should never happen in production but log in DEBUG
            #if DEBUG
            print("[Keychain] Failed to save token: \(status)")
            #endif
        }
    }

    static func loadToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

---

## 3. Handling 429 and 423 Responses 🔴

The server returns `429 Too Many Requests` when rate limits are hit and
`423 Locked` when an account is locked out. The iOS app must handle both
gracefully — never crash, never retry in a tight loop.

### 3.1 Update APIError

```swift
// Networking/APIError.swift — add two new cases
enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case validation(String)
    case conflict(String)
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited(retryAfterSeconds: Int)  // 429
    case accountLocked(message: String)        // 423
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in again."
        case .notFound:
            return "Not found."
        case .validation(let msg):
            return msg
        case .conflict(let msg):
            return msg
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .decodingError(let e):
            return "Data error: \(e.localizedDescription)"
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .rateLimited(let seconds):
            let minutes = Int(ceil(Double(seconds) / 60.0))
            if minutes <= 1 {
                return "Too many attempts. Please wait a moment and try again."
            } else {
                return "Too many attempts. Please try again in \(minutes) minutes."
            }
        case .accountLocked(let msg):
            return msg
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}
```

### 3.2 Update APIClient to Parse 429 and 423

```swift
// Networking/APIClient.swift — add to the switch on http.statusCode:
case 423:
    let err = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
    throw APIError.accountLocked(err?.message ?? "Account temporarily locked.")

case 429:
    // Read Retry-After header if present
    let retryAfter = (response as? HTTPURLResponse)?
        .value(forHTTPHeaderField: "Retry-After")
        .flatMap(Int.init) ?? 60
    throw APIError.rateLimited(retryAfterSeconds: retryAfter)
```

### 3.3 No Retry on 429

The app must **never automatically retry** a request that received a 429.
Some network layers retry on failure — make sure this is disabled:

```swift
// Networking/APIClient.swift
// URLSession configuration — disable automatic retries
private let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true      // wait for connectivity, don't fail immediately
    // No retry logic — 429s must propagate to the ViewModel
    return URLSession(configuration: config)
}()
```

### 3.4 Rate Limit UI on Login / Register

`SignInView` and `RegisterView` should show a countdown when rate limited:

```swift
// Auth/SignInView.swift — add countdown state
@State private var rateLimitCountdown: Int = 0
@State private var countdownTimer: Timer?

// In the login action:
do {
    await authVM.login(username: username, password: password)
} catch APIError.rateLimited(let seconds) {
    startCountdown(seconds: seconds)
}

private func startCountdown(seconds: Int) {
    rateLimitCountdown = seconds
    countdownTimer?.invalidate()
    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
        if rateLimitCountdown > 0 {
            rateLimitCountdown -= 1
        } else {
            timer.invalidate()
        }
    }
}

// In the button view:
if rateLimitCountdown > 0 {
    Text("Try again in \(rateLimitCountdown)s")
        .font(.system(size: 14))
        .foregroundColor(Color.textMuted)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.screenBg)
        .cornerRadius(10)
} else {
    PrimaryButton(title: "Sign in", isLoading: authVM.isLoading) {
        Task { await authVM.login(...) }
    }
}
```

---

## 4. Safe Logging 🔴

The iOS app must never log sensitive data — JWT tokens, passwords, usernames, or
any family member PII — to the console or crash reporters.

### 4.1 Rules

- All `print()` statements that touch network responses must be wrapped in `#if DEBUG`
- Never log the full `URLRequest` — it contains the `Authorization` header
- Never log response bodies from auth endpoints
- If using a crash reporter (Crashlytics, Sentry) in future: scrub PII before sending

### 4.2 Safe Debug Logger

```swift
// Shared/DotoLogger.swift
struct DotoLogger {

    static func request(_ req: URLRequest) {
        #if DEBUG
        // Log method + URL only — never headers (contains JWT) or body (may contain password)
        print("[API] \(req.httpMethod ?? "?") \(req.url?.path ?? "?")")
        #endif
    }

    static func response(statusCode: Int, path: String) {
        #if DEBUG
        print("[API] \(statusCode) \(path)")
        #endif
    }

    static func error(_ error: Error, context: String) {
        #if DEBUG
        print("[Error] \(context): \(error.localizedDescription)")
        #endif
        // In production: send to crash reporter WITHOUT the error message
        // (may contain server-side detail). Send only context + error type.
    }

    // Never call this with sensitive values
    static func debug(_ message: String) {
        #if DEBUG
        print("[Debug] \(message)")
        #endif
    }
}
```

Use `DotoLogger` instead of bare `print()` throughout the app.

### 4.3 APIClient Logging Integration

```swift
// Networking/APIClient.swift — replace any print statements with:
DotoLogger.request(req)
// ... after response:
DotoLogger.response(statusCode: http.statusCode, path: req.url?.path ?? "")
```

---

## 5. Certificate Pinning 🟡

Certificate pinning makes the app refuse to connect to any server that doesn't
present a certificate from a known issuer. This prevents man-in-the-middle attacks
on compromised WiFi — even if an attacker installs a rogue root CA on the device,
the app won't trust it.

### 5.1 Approach — Public Key Pinning

Pin the **public key hash** of your server's certificate rather than the full certificate.
This means you don't need to update the app when the certificate renews — only if you
change your CA or key pair.

### 5.2 Getting the Public Key Hash

Run this against your production domain after deployment:

```bash
# Get the public key hash for certificate pinning
openssl s_client -connect api.getdoto.com:443 -servername api.getdoto.com \
  | openssl x509 -noout -pubkey \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | base64
```

Store this hash — it goes into `CertificatePinner.swift`.

### 5.3 Implementation

```swift
// Networking/CertificatePinner.swift
import Foundation
import CryptoKit

class CertificatePinner: NSObject, URLSessionDelegate {

    // Replace with the actual hash from your server after deployment
    // Get a backup hash from your CA as well in case you need to rotate
    private let pinnedHashes: Set<String> = [
        "REPLACE_WITH_YOUR_PRIMARY_KEY_HASH=",
        "REPLACE_WITH_YOUR_BACKUP_KEY_HASH="    // backup — can be from CA
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod
                == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract the server's public key
        guard let publicKey     = SecCertificateCopyKey(certificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Hash the public key
        let hash = SHA256.hash(data: publicKeyData)
        let hashBase64 = Data(hash).base64EncodedString()

        if pinnedHashes.contains(hashBase64) {
            // Certificate trusted — proceed
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // Certificate not pinned — reject
            DotoLogger.error(
                NSError(domain: "CertPin", code: -1),
                context: "Certificate pinning failed for \(challenge.protectionSpace.host)"
            )
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

### 5.4 Wire Into APIClient

```swift
// Networking/APIClient.swift — updated init
class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true

        #if DEBUG
        // Skip certificate pinning in development (localhost has no real cert)
        session = URLSession(configuration: config)
        #else
        // Enable certificate pinning in production
        let pinner = CertificatePinner()
        session = URLSession(configuration: config, delegate: pinner, delegateQueue: nil)
        #endif
    }
    // ... rest of APIClient unchanged
}
```

### 5.5 Important: Update Pins Before Rotating Certificates

When your server certificate is about to expire and you rotate to a new one:
1. Add the new public key hash to `pinnedHashes` alongside the existing one
2. Ship the app update to the App Store
3. Wait for adoption rate to climb (at least 80% of users on new version)
4. Only then rotate the server certificate
5. Ship another update removing the old hash

If you rotate the certificate before shipping the updated pin, all users on the old
app version will be locked out.

---

## 6. Background Privacy Protection 🟡

When the app goes to background (user presses Home or switches apps), iOS takes a
screenshot for the app switcher. This screenshot can expose family data — task lists,
shopping items, children's names and points.

### 6.1 BlurOverlayModifier

Apply a blur overlay when the app enters the background:

```swift
// Shared/BlurOverlayModifier.swift
struct PrivacyScreenModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        ZStack {
            content
            if scenePhase == .inactive || scenePhase == .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color.textMuted)
                            Text("Doto")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                        }
                    )
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: scenePhase)
    }
}

extension View {
    func privacyScreen() -> some View {
        modifier(PrivacyScreenModifier())
    }
}
```

Apply in `MainTabView` so it covers all authenticated screens:

```swift
// MainTabView.swift
var body: some View {
    TabView { ... }
        .privacyScreen()
}
```

---

## 7. Biometric Re-Authentication 🟠

Optionally require Face ID / Touch ID when the app returns from background after
more than 5 minutes. Appropriate for a family app that may be on a shared device.

### 7.1 Implementation

```swift
// Shared/BiometricLockViewModel.swift
import LocalAuthentication

@MainActor
class BiometricLockViewModel: ObservableObject {
    @Published var isLocked = false

    private var backgroundedAt: Date?
    private let lockAfterSeconds: TimeInterval = 5 * 60   // 5 minutes

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            backgroundedAt = Date()
        case .active:
            if let bg = backgroundedAt,
               Date().timeIntervalSince(bg) > lockAfterSeconds {
                isLocked = true
                authenticate()
            }
            backgroundedAt = nil
        default:
            break
        }
    }

    func authenticate() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        else {
            // No biometrics available — unlock without authentication
            isLocked = false
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock Doto"
        ) { success, _ in
            DispatchQueue.main.async {
                self.isLocked = !success
            }
        }
    }
}
```

Apply in `RootView`:

```swift
// RootView.swift — add biometric lock
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var biometricVM = BiometricLockViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if biometricVM.isLocked {
                BiometricLockView(onUnlock: { biometricVM.authenticate() })
            } else {
                switch authVM.state {
                case .unauthenticated: LandingView()
                case .noFamily:        FamilySetupView()
                case .ready:           MainTabView()
                }
            }
        }
        .onChange(of: scenePhase) { biometricVM.handleScenePhaseChange($0) }
        .task { await authVM.restoreSession() }
    }
}
```

**Note:** This feature should be opt-in, not forced. Add a toggle in Settings:
`Settings → Profile → Require Face ID when reopening app`.
Default: off.

---

## 8. Jailbreak Detection 🟠

On a jailbroken device, Keychain security guarantees are weakened — other apps
may be able to read Keychain entries. For a family app this is low risk, but
worth a soft warning.

### 8.1 Basic Detection

```swift
// Shared/JailbreakDetector.swift
struct JailbreakDetector {
    static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false   // simulators always "fail" these checks
        #else
        // Check 1: Cydia or common jailbreak paths exist
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        if jailbreakPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
            return true
        }

        // Check 2: Can write outside the sandbox?
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true   // should not be possible on non-jailbroken device
        } catch {
            return false
        }
        #endif
    }
}
```

### 8.2 Soft Warning Only

Do not block the app on jailbroken devices — this causes support issues and false
positives. Show a one-time warning instead:

```swift
// In RootView.onAppear or DotoApp.init:
if JailbreakDetector.isJailbroken &&
   !UserDefaults.standard.bool(forKey: "jailbreakWarningShown") {
    // Show alert:
    // "Security notice: Your device may be modified. For your family's privacy,
    //  we recommend using Doto on a standard device."
    UserDefaults.standard.set(true, forKey: "jailbreakWarningShown")
}
```

---

## 9. Summary of Required Changes to Existing Files

These files from the core iOS spec need to be updated:

| File | Change |
|---|---|
| `Auth/AuthViewModel.swift` | `logout()` becomes `async`, calls `POST /api/auth/logout` before clearing Keychain |
| `Networking/APIError.swift` | Add `.rateLimited(retryAfterSeconds:)` and `.accountLocked(message:)` cases |
| `Networking/APIClient.swift` | Handle 429 + 423 status codes, use `DotoLogger` instead of `print()`, wire in `CertificatePinner` in release builds |
| `Auth/KeychainHelper.swift` | Add `kSecAttrAccessibleAfterFirstUnlock` accessibility level |
| `MainTabView.swift` | Apply `.privacyScreen()` modifier |
| `Auth/SignInView.swift` | Add `rateLimitCountdown` state + countdown button |
| `Auth/RegisterView.swift` | Handle `.rateLimited` error from register |
| `RootView.swift` | Add `BiometricLockViewModel` (optional, off by default) |

---

## 10. Build Order

```
1. Safe logging (DotoLogger)          — replace all print() statements first
2. Keychain accessibility level       — one-line change to KeychainHelper
3. 429 / 423 error handling           — update APIError + APIClient + auth views
4. Logout calls API                   — update AuthViewModel.logout()
5. Background privacy screen          — add PrivacyScreenModifier to MainTabView
6. Certificate pinning                — after backend is deployed to production domain
7. Biometric lock (optional)          — add Settings toggle, off by default
8. Jailbreak detection (optional)     — soft warning only, one-time
```
