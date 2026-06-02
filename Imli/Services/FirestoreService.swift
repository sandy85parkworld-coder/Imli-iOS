import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Collection helpers

    private func historyRef(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("history")
    }

    private func savedRef(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("saved")
    }

    private func profileRef(userId: String) -> DocumentReference {
        db.collection("users").document(userId).collection("profile").document("data")
    }

    // MARK: - Scan History

    func addToHistory(_ product: Product, userId: String) async throws {
        try historyRef(userId: userId).document(product.id.uuidString).setData(from: product)
    }

    func fetchHistory(userId: String) async throws -> [Product] {
        let snapshot = try await historyRef(userId: userId)
            .order(by: "scannedAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Product.self) }
    }

    func deleteHistory(productId: String, userId: String) async throws {
        try await historyRef(userId: userId).document(productId).delete()
    }

    // MARK: - Saved Products

    func saveProduct(_ product: Product, userId: String) async throws {
        try savedRef(userId: userId).document(product.barcode).setData(from: product)
    }

    func unsaveProduct(barcode: String, userId: String) async throws {
        try await savedRef(userId: userId).document(barcode).delete()
    }

    func fetchSaved(userId: String) async throws -> [Product] {
        let snapshot = try await savedRef(userId: userId)
            .order(by: "scannedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Product.self) }
    }

    func isProductSaved(barcode: String, userId: String) async throws -> Bool {
        let doc = try await savedRef(userId: userId).document(barcode).getDocument()
        return doc.exists
    }

    // MARK: - User Profile

    func saveProfile(_ profile: UserProfile, userId: String) async throws {
        let data = FirestoreUserProfile(from: profile)
        try profileRef(userId: userId).setData(from: data)
    }

    func fetchProfile(userId: String) async throws -> UserProfile? {
        let doc = try await profileRef(userId: userId).getDocument()
        guard doc.exists,
              let data = try? doc.data(as: FirestoreUserProfile.self) else { return nil }
        return data.toUserProfile()
    }
}

// MARK: - Firestore-safe UserProfile wrapper
// UserProfile.dietPreferences is Set<DietPreference> which Codable encodes
// as an unordered array. This wrapper makes the intent explicit.

private struct FirestoreUserProfile: Codable {
    var name: String
    var dietPreferences: [String]
    var familyMembers: [FamilyMember]
    var totalScans: Int
    var safePercentage: Double

    init(from profile: UserProfile) {
        name             = profile.name
        dietPreferences  = profile.dietPreferences.map { $0.rawValue }
        familyMembers    = profile.familyMembers
        totalScans       = profile.totalScans
        safePercentage   = profile.safePercentage
    }

    func toUserProfile() -> UserProfile {
        let prefs = Set(dietPreferences.compactMap(UserProfile.DietPreference.init(rawValue:)))
        return UserProfile(
            name:            name,
            dietPreferences: prefs,
            familyMembers:   familyMembers,
            totalScans:      totalScans,
            safePercentage:  safePercentage
        )
    }
}
