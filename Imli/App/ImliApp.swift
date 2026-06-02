import SwiftUI
import FirebaseCore

@main
struct ImliApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.currentUser == nil {
                    AuthView()
                        .environmentObject(authService)
                } else if appState.hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(appState)
                        .environmentObject(authService)
                } else {
                    OnboardingView()
                        .environmentObject(appState)
                        .environmentObject(authService)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: authService.currentUser?.uid)
        }
    }
}
