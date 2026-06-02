import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var userId: String? { currentUser?.uid }

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Email / Password

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        isLoading = true
        errorMessage = nil
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google sign-in failed: missing token."
                isLoading = false
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Error messages

    private func friendlyMessage(for error: Error) -> String {
        let code = AuthErrorCode(_nsError: error as NSError)
        switch code.code {
        case .userNotFound, .wrongPassword, .invalidEmail:
            return "Incorrect email or password."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .networkError:
            return "Network error. Check your connection."
        default:
            return error.localizedDescription
        }
    }
}
