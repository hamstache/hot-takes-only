import Foundation
import AuthenticationServices
import CryptoKit
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isSignedInWithApple = false

    private var supabase: SupabaseClient { SupabaseService.shared.client }
    private let coordinator = SIWACoordinator()

    private init() {}

    // Call once on app launch. Restores a stored session from Keychain, or signs
    // in anonymously so auth.uid() is always set for RLS policies.
    func ensureSession() async {
        guard supabase.auth.currentSession == nil else {
            isSignedInWithApple = supabase.auth.currentUser?.appMetadata["provider"] as? String == "apple"
            return
        }
        do {
            try await supabase.auth.signInAnonymously()
        } catch {}
    }

    // Presents the Apple sign-in sheet. On success, links the Apple credential to
    // the current Supabase session and returns the user's full name (only provided
    // by Apple on the very first sign-in — nil on subsequent ones).
    func signInWithApple() async -> String? {
        let nonce = randomNonce()
        do {
            let (idToken, fullName) = try await coordinator.request(hashedNonce: sha256(nonce))
            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            isSignedInWithApple = true
            return fullName
        } catch {
            return nil
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

@MainActor
private final class SIWACoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    private var continuation: CheckedContinuation<(idToken: String, fullName: String?), Error>?

    func request(hashedNonce: String) async throws -> (idToken: String, fullName: String?) {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let appleRequest = ASAuthorizationAppleIDProvider().createRequest()
            appleRequest.requestedScopes = [.fullName]
            appleRequest.nonce = hashedNonce

            let controller = ASAuthorizationController(authorizationRequests: [appleRequest])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { continuation = nil }
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let data = credential.identityToken,
              let idToken = String(data: data, encoding: .utf8) else {
            continuation?.resume(throwing: SIWAError.missingToken)
            return
        }
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        continuation?.resume(returning: (idToken, name.isEmpty ? nil : name))
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

private enum SIWAError: Error {
    case missingToken
}
