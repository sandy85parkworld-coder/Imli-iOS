import XCTest
@testable import Imli

final class AppStateTests: XCTestCase {

    private let onboardingKey = "onboardingDone"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        super.tearDown()
    }

    // MARK: - Onboarding flag

    func testDefaultOnboardingIsFalse() {
        let state = AppState()
        XCTAssertFalse(state.hasCompletedOnboarding)
    }

    func testSettingOnboardingPersistsToUserDefaults() {
        let state = AppState()
        state.hasCompletedOnboarding = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: onboardingKey))
    }

    func testOnboardingRestoredFromUserDefaults() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        let state = AppState()
        XCTAssertTrue(state.hasCompletedOnboarding)
    }

    func testClearingOnboardingPersists() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        let state = AppState()
        state.hasCompletedOnboarding = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: onboardingKey))
    }

    // MARK: - Default state

    func testDefaultTabIsScan() {
        let state = AppState()
        XCTAssertEqual(state.selectedTab, .scan)
    }

    func testDefaultProductIsNil() {
        let state = AppState()
        XCTAssertNil(state.scannedProduct)
    }

    func testDefaultShowingResultIsFalse() {
        let state = AppState()
        XCTAssertFalse(state.showingResult)
    }

    // MARK: - Tab switching

    func testTabSwitchToHistory() {
        let state = AppState()
        state.selectedTab = .history
        XCTAssertEqual(state.selectedTab, .history)
    }

    func testTabSwitchToSaved() {
        let state = AppState()
        state.selectedTab = .saved
        XCTAssertEqual(state.selectedTab, .saved)
    }

    func testTabSwitchToProfile() {
        let state = AppState()
        state.selectedTab = .profile
        XCTAssertEqual(state.selectedTab, .profile)
    }

    func testTabCycleBackToScan() {
        let state = AppState()
        state.selectedTab = .profile
        state.selectedTab = .scan
        XCTAssertEqual(state.selectedTab, .scan)
    }

    // MARK: - Product state

    func testAssigningScannedProduct() {
        let state = AppState()
        state.scannedProduct = .mockBourbonBiscuit
        XCTAssertNotNil(state.scannedProduct)
        XCTAssertEqual(state.scannedProduct?.barcode, "8901063025059")
    }

    func testClearingScannedProduct() {
        let state = AppState()
        state.scannedProduct = .mockBourbonBiscuit
        state.scannedProduct = nil
        XCTAssertNil(state.scannedProduct)
    }

    func testShowingResultFlag() {
        let state = AppState()
        state.showingResult = true
        XCTAssertTrue(state.showingResult)
        state.showingResult = false
        XCTAssertFalse(state.showingResult)
    }
}
