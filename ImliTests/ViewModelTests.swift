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

    func testScanViewModelResetFromSuccessState() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901063025059")
        XCTAssertEqual(vm.scanState, .success)

        vm.reset()

        XCTAssertEqual(vm.scanState, .idle)
        XCTAssertNil(vm.product)
    }

    // MARK: - ScanViewModel — barcode lookup (known barcodes)

    func testLookupBourbonBiscuit() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901063025059")

        XCTAssertEqual(vm.scanState, .success)
        XCTAssertEqual(vm.scannedBarcode, "8901063025059")
        XCTAssertNotNil(vm.product)
        XCTAssertEqual(vm.product?.name, "Bourbon Biscuits Original")
        XCTAssertEqual(vm.product?.grade, .d)
    }

    func testLookupAashirvaadAtta() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901030832109")

        XCTAssertEqual(vm.scanState, .success)
        XCTAssertEqual(vm.product?.grade, .a)
        XCTAssertEqual(vm.product?.vegStatus, .veg)
    }

    func testLookupMaggiChicken() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901058005016")

        XCTAssertEqual(vm.scanState, .success)
        XCTAssertEqual(vm.product?.vegStatus, .nonVeg)
        XCTAssertFalse(vm.product?.kidSafe ?? true)
    }

    func testLookupUnknownBarcodeReturnsSomeMock() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("0000000000000")

        XCTAssertEqual(vm.scanState, .success)
        XCTAssertNotNil(vm.product)
        XCTAssertEqual(vm.scannedBarcode, "0000000000000")
    }

    func testLookupSetsScannedBarcode() async {
        let vm = ScanViewModel()
        let barcode = "8901030832109"
        await vm.lookupBarcode(barcode)

        XCTAssertEqual(vm.scannedBarcode, barcode)
    }

    func testSuccessiveLookupsOverwriteProduct() async {
        let vm = ScanViewModel()
        await vm.lookupBarcode("8901063025059")
        let firstProduct = vm.product

        await vm.lookupBarcode("8901030832109")
        let secondProduct = vm.product

        XCTAssertNotEqual(firstProduct?.barcode, secondProduct?.barcode)
        XCTAssertEqual(secondProduct?.barcode, "8901030832109")
    }

    // MARK: - HistoryViewModel

    func testHistoryViewModelStartsWithThreeMockItems() {
        let vm = HistoryViewModel()
        XCTAssertEqual(vm.history.count, 3)
    }

    func testHistoryViewModelAddScanIncreasesCount() {
        let vm = HistoryViewModel()
        let before = vm.history.count
        vm.addScan(.mockBourbonBiscuit)
        XCTAssertEqual(vm.history.count, before + 1)
    }

    func testHistoryViewModelAddScanPrependsToFront() {
        let vm = HistoryViewModel()
        vm.addScan(.mockAashirvaadAtta)
        XCTAssertEqual(vm.history.first?.barcode, "8901030832109")
    }

    func testHistoryViewModelAddMultipleScansPreservesOrder() {
        let vm = HistoryViewModel()
        vm.addScan(.mockBourbonBiscuit)
        vm.addScan(.mockMaggiChicken)

        XCTAssertEqual(vm.history[0].barcode, "8901058005016")
        XCTAssertEqual(vm.history[1].barcode, "8901063025059")
    }

    func testHistoryViewModelAddScanDoesNotDeduplicateByDefault() {
        let vm = HistoryViewModel()
        let before = vm.history.count
        vm.addScan(.mockBourbonBiscuit)
        vm.addScan(.mockBourbonBiscuit)
        XCTAssertEqual(vm.history.count, before + 2)
    }

    // MARK: - ProfileViewModel

    func testProfileViewModelDefaultsToMockProfile() {
        let vm = ProfileViewModel()
        XCTAssertEqual(vm.profile.name, "Ramesh Kumar")
        XCTAssertFalse(vm.profile.dietPreferences.isEmpty)
    }

    func testTogglePreferenceAddsWhenAbsent() {
        let vm = ProfileViewModel()
        XCTAssertFalse(vm.profile.dietPreferences.contains(.glutenFree))

        vm.togglePreference(.glutenFree)

        XCTAssertTrue(vm.profile.dietPreferences.contains(.glutenFree))
    }

    func testTogglePreferenceRemovesWhenPresent() {
        let vm = ProfileViewModel()
        XCTAssertTrue(vm.profile.dietPreferences.contains(.pureVeg))

        vm.togglePreference(.pureVeg)

        XCTAssertFalse(vm.profile.dietPreferences.contains(.pureVeg))
    }

    func testTogglePreferenceTogglesTwiceRestoresState() {
        let vm = ProfileViewModel()
        let initial = vm.profile.dietPreferences.contains(.vegan)

        vm.togglePreference(.vegan)
        vm.togglePreference(.vegan)

        XCTAssertEqual(vm.profile.dietPreferences.contains(.vegan), initial)
    }

    func testTogglePreferenceDoesNotAffectOtherPreferences() {
        let vm = ProfileViewModel()
        let beforeCount = vm.profile.dietPreferences.count
        XCTAssertTrue(vm.profile.dietPreferences.contains(.pureVeg))

        vm.togglePreference(.glutenFree) // add one that wasn't there

        XCTAssertTrue(vm.profile.dietPreferences.contains(.pureVeg), "Existing preference should be untouched")
        XCTAssertEqual(vm.profile.dietPreferences.count, beforeCount + 1)
    }

    func testToggleAllPreferencesAndBack() {
        let vm = ProfileViewModel()
        let allPrefs = UserProfile.DietPreference.allCases

        for pref in allPrefs { vm.togglePreference(pref) }
        for pref in allPrefs { vm.togglePreference(pref) }

        XCTAssertEqual(vm.profile.dietPreferences, UserProfile.mock.dietPreferences)
    }
}
