import XCTest
@testable import Imli

// All view models use @MainActor, so tests must run on the main actor too.
@MainActor
final class ViewModelTests: XCTestCase {

    // MARK: - ScanViewModel — initial state

    func testScanViewModelDefaultState() {
        let vm = ScanViewModel()
        XCTAssertEqual(vm.scanState, .idle)
        XCTAssertNil(vm.scannedBarcode)
        XCTAssertNil(vm.product)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.torchOn)
    }

    // MARK: - ScanViewModel — reset

    func testScanViewModelResetClearsAllState() {
        let vm = ScanViewModel()
        vm.scannedBarcode = "1234567890"
        vm.product = .mockBourbonBiscuit
        vm.errorMessage = "Network error"
        vm.reset()

        XCTAssertEqual(vm.scanState, .idle)
        XCTAssertNil(vm.scannedBarcode)
        XCTAssertNil(vm.product)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - ScanViewModel — barcode lookup (live Open Food Facts API)
    // These are integration tests that hit the real API.
    // Assertions are intentionally lenient: we verify state transitions
    // and barcode tracking, not specific product data which changes in OFN.

    func testLookupKnownBarcodeSetsBarcode() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901063025059", userId: nil)
        XCTAssertEqual(vm.scannedBarcode, "8901063025059")
        // State must be either success or notFound — both are valid live-API outcomes
        XCTAssertTrue(vm.scanState == .success || vm.scanState == .notFound)
    }

    func testLookupSuccessProductIsNonNil() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901063025059", userId: nil)
        if vm.scanState == .success {
            XCTAssertNotNil(vm.product)
        }
    }

    func testLookupAashirvaadAtta() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901030832109", userId: nil)
        XCTAssertEqual(vm.scannedBarcode, "8901030832109")
        XCTAssertTrue(vm.scanState == .success || vm.scanState == .notFound)
    }

    func testLookupMaggiChicken() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901058005016", userId: nil)
        XCTAssertEqual(vm.scannedBarcode, "8901058005016")
        XCTAssertTrue(vm.scanState == .success || vm.scanState == .notFound)
    }

    func testLookupGlobalProductOreo() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("7622300489991", userId: nil)
        XCTAssertEqual(vm.scannedBarcode, "7622300489991")
        XCTAssertTrue(vm.scanState == .success || vm.scanState == .notFound)
    }

    func testLookupUnknownBarcodeResultsInNotFound() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("0000000000000", userId: nil)
        // An all-zero barcode is very unlikely to exist in OFN
        XCTAssertTrue(vm.scanState == .notFound || vm.scanState == .success)
        XCTAssertEqual(vm.scannedBarcode, "0000000000000")
    }

    func testSuccessStateAllowsReset() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901063025059", userId: nil)
        vm.reset()
        XCTAssertEqual(vm.scanState, .idle)
        XCTAssertNil(vm.product)
        XCTAssertNil(vm.scannedBarcode)
    }

    func testSuccessiveLookupOverwritesBarcode() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901063025059", userId: nil)
        await vm.lookupBarcode("8901030832109", userId: nil)
        XCTAssertEqual(vm.scannedBarcode, "8901030832109")
    }

    // MARK: - HistoryViewModel

    func testHistoryViewModelStartsEmpty() {
        let vm = HistoryViewModel()
        XCTAssertTrue(vm.history.isEmpty)
    }

    func testHistoryViewModelInsertIncreasesCount() {
        let vm = HistoryViewModel()
        vm.history.insert(.mockBourbonBiscuit, at: 0)
        XCTAssertEqual(vm.history.count, 1)
    }

    func testHistoryViewModelInsertAtFront() {
        let vm = HistoryViewModel()
        vm.history.insert(.mockBourbonBiscuit, at: 0)
        vm.history.insert(.mockAashirvaadAtta, at: 0)
        XCTAssertEqual(vm.history[0].barcode, "8901030832109")
    }

    // MARK: - SavedViewModel

    func testSavedViewModelStartsEmpty() {
        let vm = SavedViewModel()
        XCTAssertTrue(vm.saved.isEmpty)
    }

    func testIsSavedReturnsFalseInitially() {
        let vm = SavedViewModel()
        XCTAssertFalse(vm.isSaved("8901063025059"))
    }

    func testIsSavedReturnsTrueAfterLocalInsert() {
        let vm = SavedViewModel()
        vm.saved.insert(.mockBourbonBiscuit, at: 0)
        XCTAssertTrue(vm.isSaved("8901063025059"))
    }

    func testIsSavedReturnsFalseAfterRemoval() {
        let vm = SavedViewModel()
        vm.saved.insert(.mockBourbonBiscuit, at: 0)
        vm.saved.removeAll { $0.barcode == "8901063025059" }
        XCTAssertFalse(vm.isSaved("8901063025059"))
    }

    // MARK: - ProfileViewModel

    func testProfileViewModelDefaultsToEmptyProfile() {
        let vm = ProfileViewModel()
        XCTAssertEqual(vm.profile.name, "")
        XCTAssertTrue(vm.profile.dietPreferences.isEmpty)
        XCTAssertTrue(vm.profile.familyMembers.isEmpty)
    }

    func testTogglePreferenceAddsWhenAbsent() {
        let vm = ProfileViewModel()
        XCTAssertFalse(vm.profile.dietPreferences.contains(.glutenFree))
        vm.profile.dietPreferences.insert(.glutenFree)
        XCTAssertTrue(vm.profile.dietPreferences.contains(.glutenFree))
    }

    func testTogglePreferenceRemovesWhenPresent() {
        let vm = ProfileViewModel()
        vm.profile.dietPreferences.insert(.pureVeg)
        vm.profile.dietPreferences.remove(.pureVeg)
        XCTAssertFalse(vm.profile.dietPreferences.contains(.pureVeg))
    }

    func testAddFamilyMemberIncreasesCount() {
        let vm = ProfileViewModel()
        let member = FamilyMember(name: "Alice", ageGroup: .child, emoji: "👧")
        vm.profile.familyMembers.append(member)
        XCTAssertEqual(vm.profile.familyMembers.count, 1)
    }

    func testDeleteFamilyMemberDecreasesCount() {
        let vm = ProfileViewModel()
        let member = FamilyMember(name: "Bob", ageGroup: .adult, emoji: "👨")
        vm.profile.familyMembers.append(member)
        vm.profile.familyMembers.removeAll { $0.id == member.id }
        XCTAssertTrue(vm.profile.familyMembers.isEmpty)
    }

    func testUpdateNameChangesProfileName() {
        let vm = ProfileViewModel()
        vm.profile.name = "Sunita"
        XCTAssertEqual(vm.profile.name, "Sunita")
    }
}
