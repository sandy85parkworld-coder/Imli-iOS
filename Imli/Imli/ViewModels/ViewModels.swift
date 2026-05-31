import SwiftUI
import AVFoundation
import Combine

// MARK: - Scan View Model
@MainActor
class ScanViewModel: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var scannedBarcode: String?
    @Published var product: Product?
    @Published var errorMessage: String?
    @Published var torchOn: Bool = false

    enum ScanState {
        case idle, scanning, loading, success, notFound, error
    }

    // Simulate a barcode lookup — replace with real API call
    func lookupBarcode(_ barcode: String) async {
        scanState = .loading
        scannedBarcode = barcode

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        // Mock lookup by barcode
        switch barcode {
        case "8901063025059":
            product = .mockBourbonBiscuit
            scanState = .success
        case "8901030832109":
            product = .mockAashirvaadAtta
            scanState = .success
        case "8901058005016":
            product = .mockMaggiChicken
            scanState = .success
        default:
            // Return random mock for demo purposes
            let mocks: [Product] = [.mockBourbonBiscuit, .mockAashirvaadAtta, .mockMaggiChicken]
            product = mocks.randomElement()
            scanState = .success
        }
    }

    func reset() {
        scanState = .idle
        scannedBarcode = nil
        product = nil
        errorMessage = nil
    }
}

// MARK: - History View Model
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var history: [Product] = [
        .mockBourbonBiscuit,
        .mockAashirvaadAtta,
        .mockMaggiChicken
    ]

    func addScan(_ product: Product) {
        history.insert(product, at: 0)
    }
}

// MARK: - Profile View Model
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = .mock

    func togglePreference(_ pref: UserProfile.DietPreference) {
        if profile.dietPreferences.contains(pref) {
            profile.dietPreferences.remove(pref)
        } else {
            profile.dietPreferences.insert(pref)
        }
    }
}
