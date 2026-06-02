import SwiftUI
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focused: Field?

    enum Mode { case signIn, signUp }
    enum Field { case email, password, confirm }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                VStack(spacing: 16) {
                    emailField
                    passwordField
                    if mode == .signUp { confirmField }
                }
                .padding(.horizontal, 24)

                if let error = authService.errorMessage {
                    errorBanner(error)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                divider
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                googleButton
                    .padding(.horizontal, 24)

                modeToggle
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
        }
        .background(Color.imliSurface.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("🌿")
                .font(.system(size: 52))
            Text("Imli")
                .font(ImliFont.largeTitle())
                .foregroundColor(.imliGreen)
            Text(mode == .signIn ? "Welcome back" : "Create your account")
                .font(ImliFont.subheadline())
                .foregroundColor(.imliSecondary)
        }
    }

    // MARK: - Fields

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Email").font(ImliFont.footnote()).foregroundColor(.imliSecondary)
            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($focused, equals: .email)
                .submitLabel(.next)
                .onSubmit { focused = .password }
                .fieldStyle()
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password").font(ImliFont.footnote()).foregroundColor(.imliSecondary)
            SecureField("Min. 6 characters", text: $password)
                .focused($focused, equals: .password)
                .submitLabel(mode == .signUp ? .next : .done)
                .onSubmit {
                    if mode == .signUp { focused = .confirm }
                    else { Task { await submit() } }
                }
                .fieldStyle()
        }
    }

    private var confirmField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Confirm Password").font(ImliFont.footnote()).foregroundColor(.imliSecondary)
            SecureField("Re-enter password", text: $confirmPassword)
                .focused($focused, equals: .confirm)
                .submitLabel(.done)
                .onSubmit { Task { await submit() } }
                .fieldStyle()
        }
    }

    // MARK: - Buttons

    private var primaryButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Group {
                if authService.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(mode == .signIn ? "Sign In" : "Create Account")
                        .font(ImliFont.headline())
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.imliGreen)
            .clipShape(RoundedRectangle(cornerRadius: ImliRadius.lg))
        }
        .disabled(authService.isLoading || !isFormValid)
        .opacity(isFormValid ? 1 : 0.6)
    }

    private var googleButton: some View {
        Button {
            Task { await authService.signInWithGoogle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#4285F4"))
                Text("Continue with Google")
                    .font(ImliFont.callout())
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.imliCard)
            .clipShape(RoundedRectangle(cornerRadius: ImliRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: ImliRadius.lg)
                    .strokeBorder(Color.imliSeparator, lineWidth: 1)
            )
        }
        .disabled(authService.isLoading)
    }

    private var modeToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = mode == .signIn ? .signUp : .signIn
                authService.errorMessage = nil
                password = ""; confirmPassword = ""
            }
        } label: {
            HStack(spacing: 4) {
                Text(mode == .signIn ? "Don't have an account?" : "Already have an account?")
                    .foregroundColor(.imliSecondary)
                Text(mode == .signIn ? "Sign Up" : "Sign In")
                    .foregroundColor(.imliGreen)
                    .fontWeight(.semibold)
            }
            .font(ImliFont.footnote())
        }
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color.imliSeparator).frame(height: 1)
            Text("or").font(ImliFont.caption1()).foregroundColor(.imliSecondary).padding(.horizontal, 8)
            Rectangle().fill(Color.imliSeparator).frame(height: 1)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.imliRed)
            Text(message)
                .font(ImliFont.caption1())
                .foregroundColor(.imliRed)
            Spacer()
        }
        .padding(12)
        .background(Color.imliRedLight)
        .clipShape(RoundedRectangle(cornerRadius: ImliRadius.sm))
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passOK  = password.count >= 6
        if mode == .signUp { return emailOK && passOK && confirmPassword == password }
        return emailOK && passOK
    }

    private func submit() async {
        focused = nil
        if mode == .signIn {
            await authService.signIn(email: email, password: password)
        } else {
            guard password == confirmPassword else {
                authService.errorMessage = "Passwords do not match."
                return
            }
            await authService.signUp(email: email, password: password)
        }
    }
}

// MARK: - Field style modifier

private extension View {
    func fieldStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.imliCard)
            .clipShape(RoundedRectangle(cornerRadius: ImliRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ImliRadius.md)
                    .strokeBorder(Color.imliSeparator, lineWidth: 1)
            )
    }
}
