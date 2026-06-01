import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "onboardingDone") }
    }
    @Published var selectedTab: Tab = .scan
    @Published var scannedProduct: Product?
    @Published var showingResult: Bool = false

    enum Tab { case scan, history, saved, profile }

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingDone")
    }
}
