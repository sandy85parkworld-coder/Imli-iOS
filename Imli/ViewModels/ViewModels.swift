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

    enum ScanState: Equatable {
        case idle, scanning, loading, success, notFound, error
    }

    func lookupBarcode(_ barcode: String, userId: String?) async {
        scanState = .loading
        scannedBarcode = barcode
        errorMessage = nil

        do {
            guard let found = try await ProductAPIService.shared.fetchProduct(barcode: barcode) else {
                scanState = .notFound
                return
            }
            product = found
            scanState = .success

            if let userId {
                try? await FirestoreService.shared.addToHistory(found, userId: userId)
            }
        } catch {
            errorMessage = "Could not reach the product database. Check your connection."
            scanState = .error
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
    @Published var history: [Product] = []
    @Published var isLoading = false

    func loadHistory(userId: String) async {
        isLoading = true
        do {
            history = try await FirestoreService.shared.fetchHistory(userId: userId)
        } catch {
            // Leave existing list intact on network error
        }
        isLoading = false
    }

    func delete(productId: String, userId: String) async {
        do {
            try await FirestoreService.shared.deleteHistory(productId: productId, userId: userId)
            history.removeAll { $0.id.uuidString == productId }
        } catch {}
    }
}

// MARK: - Saved View Model

@MainActor
class SavedViewModel: ObservableObject {
    @Published var saved: [Product] = []
    @Published var isLoading = false

    func loadSaved(userId: String) async {
        isLoading = true
        do {
            saved = try await FirestoreService.shared.fetchSaved(userId: userId)
        } catch {}
        isLoading = false
    }

    func toggleSave(_ product: Product, userId: String) async {
        let isSaved = saved.contains { $0.barcode == product.barcode }
        if isSaved {
            saved.removeAll { $0.barcode == product.barcode }
            try? await FirestoreService.shared.unsaveProduct(barcode: product.barcode, userId: userId)
        } else {
            saved.insert(product, at: 0)
            try? await FirestoreService.shared.saveProduct(product, userId: userId)
        }
    }

    func isSaved(_ barcode: String) -> Bool {
        saved.contains { $0.barcode == barcode }
    }
}

// MARK: - Profile View Model

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = .empty

    func loadProfile(userId: String) async {
        if let fetched = try? await FirestoreService.shared.fetchProfile(userId: userId) {
            profile = fetched
        }
    }

    func saveProfile(userId: String) async {
        try? await FirestoreService.shared.saveProfile(profile, userId: userId)
    }

    func updateName(_ name: String, userId: String) {
        profile.name = name
        Task { await saveProfile(userId: userId) }
    }

    func togglePreference(_ pref: UserProfile.DietPreference, userId: String) {
        if profile.dietPreferences.contains(pref) {
            profile.dietPreferences.remove(pref)
        } else {
            profile.dietPreferences.insert(pref)
        }
        Task { await saveProfile(userId: userId) }
    }

    func addFamilyMember(_ member: FamilyMember, userId: String) {
        profile.familyMembers.append(member)
        Task { await saveProfile(userId: userId) }
    }

    func deleteFamilyMember(id: UUID, userId: String) {
        profile.familyMembers.removeAll { $0.id == id }
        Task { await saveProfile(userId: userId) }
    }
}
