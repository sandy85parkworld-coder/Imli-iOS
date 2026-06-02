import XCTest
@testable import Imli

// Pure-logic tests — no network, no async, deterministic.
final class FamilyAnalysisTests: XCTestCase {

    // MARK: - Helpers

    private func member(
        name: String = "Test",
        ageGroup: FamilyMember.AgeGroup = .adult,
        emoji: String = "👤",
        prefs: Set<UserProfile.DietPreference> = []
    ) -> FamilyMember {
        FamilyMember(name: name, ageGroup: ageGroup, emoji: emoji, dietPreferences: prefs)
    }

    private func product(
        vegStatus: VegStatus = .veg,
        grade: SafetyGrade = .b,
        kidSafe: Bool = true,
        kidSafeNote: String? = nil,
        flags: [IngredientFlag] = [],
        transFat: Double = 0,
        sugar: Double = 5,
        sodium: Double = 200,
        ingredients: String = ""
    ) -> Product {
        let nutrition = NutritionInfo(
            energy: 200, protein: 5, carbs: 30,
            totalSugars: sugar, addedSugars: nil,
            totalFat: 8, saturatedFat: 2, transFat: transFat,
            sodium: sodium, fiber: nil, servingSize: "100g"
        )
        return Product(
            barcode: "0000000000000",
            name: "Test Product", brand: "Test Brand",
            category: "Snacks", imageEmoji: "🍪",
            vegStatus: vegStatus, grade: grade,
            flags: flags, nutrition: nutrition,
            ingredients: ingredients,
            fssaiApproved: true,
            kidSafe: kidSafe, kidSafeNote: kidSafeNote
        )
    }

    // MARK: - MemberSafetyResult.Verdict helpers

    func testVerdictLabels() {
        XCTAssertEqual(MemberSafetyResult.Verdict.safe.label,    "Safe")
        XCTAssertEqual(MemberSafetyResult.Verdict.caution.label, "Caution")
        XCTAssertEqual(MemberSafetyResult.Verdict.avoid.label,   "Avoid")
    }

    func testVerdictIcons() {
        XCTAssertEqual(MemberSafetyResult.Verdict.safe.icon,    "checkmark.circle.fill")
        XCTAssertEqual(MemberSafetyResult.Verdict.caution.icon, "exclamationmark.circle.fill")
        XCTAssertEqual(MemberSafetyResult.Verdict.avoid.icon,   "xmark.circle.fill")
    }

    func testVerdictRawValueOrdering() {
        XCTAssertLessThan(MemberSafetyResult.Verdict.safe.rawValue, MemberSafetyResult.Verdict.caution.rawValue)
        XCTAssertLessThan(MemberSafetyResult.Verdict.caution.rawValue, MemberSafetyResult.Verdict.avoid.rawValue)
    }

    // MARK: - Age group: toddler / child

    func testToddlerNotKidSafe_Avoid() {
        let p = product(kidSafe: false, kidSafeNote: "Not for toddlers")
        let result = p.analyze(for: member(ageGroup: .toddler))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("toddler") }))
    }

    func testChildNotKidSafe_Avoid() {
        let p = product(kidSafe: false)
        let result = p.analyze(for: member(ageGroup: .child))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("children") }))
    }

    func testChildWithMSGFlag_Avoid() {
        let msgFlag = IngredientFlag(name: "MSG (E621)", detail: "Avoid for children", severity: .warning)
        let p = product(flags: [msgFlag])
        let result = p.analyze(for: member(ageGroup: .child))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("MSG") }))
    }

    func testChildWithArtificialColourFlag_Caution() {
        let colourFlag = IngredientFlag(name: "Artificial Colours", detail: "Synthetic dyes", severity: .danger)
        let p = product(flags: [colourFlag])
        let result = p.analyze(for: member(ageGroup: .child))
        XCTAssertEqual(result.verdict, .caution)
        XCTAssertTrue(result.concerns.contains(where: { $0.lowercased().contains("colour") }))
    }

    func testToddlerWithHighTransFat_Avoid() {
        let p = product(transFat: 0.5)
        let result = p.analyze(for: member(ageGroup: .toddler))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("Trans fat") }))
    }

    func testChildWithTransFatBelowThreshold_NoTransFatConcern() {
        let p = product(transFat: 0.05, kidSafe: true)
        let result = p.analyze(for: member(ageGroup: .child))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("Trans fat") }))
    }

    func testKidSafeProductForToddler_Safe() {
        let p = product(kidSafe: true)
        let result = p.analyze(for: member(ageGroup: .toddler))
        XCTAssertNotEqual(result.verdict, .avoid)
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("toddler") }))
    }

    // MARK: - Age group: senior

    func testSeniorWithVeryHighSodium_Caution() {
        let p = product(sodium: 750)
        let result = p.analyze(for: member(ageGroup: .senior))
        XCTAssertEqual(result.verdict, .caution)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("sodium") }))
    }

    func testSeniorWithModerateSodium_NoSodiumConcern() {
        let p = product(sodium: 400)
        let result = p.analyze(for: member(ageGroup: .senior))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("sodium") }))
    }

    // MARK: - Diet preference: veg / non-veg

    func testPureVegPreference_NonVegProduct_Avoid() {
        let p = product(vegStatus: .nonVeg)
        let result = p.analyze(for: member(prefs: [.pureVeg]))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("non-vegetarian") }))
    }

    func testVeganPreference_NonVegProduct_Avoid() {
        let p = product(vegStatus: .nonVeg)
        let result = p.analyze(for: member(prefs: [.vegan]))
        XCTAssertEqual(result.verdict, .avoid)
    }

    func testJainPreference_NonVegProduct_Avoid() {
        let p = product(vegStatus: .nonVeg)
        let result = p.analyze(for: member(prefs: [.jain]))
        XCTAssertEqual(result.verdict, .avoid)
    }

    func testPureVegPreference_VegProduct_NoVegConcern() {
        let p = product(vegStatus: .veg)
        let result = p.analyze(for: member(prefs: [.pureVeg]))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("non-vegetarian") }))
    }

    // MARK: - Diet preference: palm oil

    func testNoPalmOilPreference_PalmOilFlag_Caution() {
        let palmFlag = IngredientFlag(name: "Refined Palm Oil", detail: "High saturated fat", severity: .warning)
        let p = product(flags: [palmFlag])
        let result = p.analyze(for: member(prefs: [.noPalmOil]))
        XCTAssertEqual(result.verdict, .caution)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("palm oil") }))
    }

    func testNoPalmOilPreference_NoPalmFlag_NoConcern() {
        let p = product(flags: [])
        let result = p.analyze(for: member(prefs: [.noPalmOil]))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("palm") }))
    }

    // MARK: - Diet preference: sugar

    func testLowSugarPreference_HighSugar_Caution() {
        let p = product(sugar: 20)
        let result = p.analyze(for: member(prefs: [.lowSugar]))
        XCTAssertEqual(result.verdict, .caution)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("sugar") }))
    }

    func testLowSugarPreference_LowSugar_NoConcern() {
        let p = product(sugar: 5)
        let result = p.analyze(for: member(prefs: [.lowSugar]))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("sugar") }))
    }

    func testDiabeticPreference_ModerateSugar_Avoid() {
        let p = product(sugar: 12)
        let result = p.analyze(for: member(prefs: [.diabetic]))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("diabetic") }))
    }

    func testDiabeticPreference_LowSugar_NoConcern() {
        let p = product(sugar: 8)
        let result = p.analyze(for: member(prefs: [.diabetic]))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("diabetic") }))
    }

    // MARK: - Diet preference: gluten-free

    func testGlutenFreePreference_WheatIngredient_Avoid() {
        let p = product(ingredients: "Refined wheat flour, sugar, palm oil")
        let result = p.analyze(for: member(prefs: [.glutenFree]))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("gluten") }))
    }

    func testGlutenFreePreference_BarleyIngredient_Avoid() {
        let p = product(ingredients: "Barley malt extract, sugar")
        let result = p.analyze(for: member(prefs: [.glutenFree]))
        XCTAssertEqual(result.verdict, .avoid)
    }

    func testGlutenFreePreference_NoGluten_NoConcern() {
        let p = product(ingredients: "Rice flour, tapioca starch, salt")
        let result = p.analyze(for: member(prefs: [.glutenFree]))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("gluten") }))
    }

    // MARK: - Grade fallback

    func testGradeDFallback_NoOtherConcerns_Caution() {
        let p = product(grade: .d)
        let result = p.analyze(for: member())
        XCTAssertEqual(result.verdict, .caution)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("Poor") }))
    }

    func testGradeEFallback_NoOtherConcerns_Avoid() {
        let p = product(grade: .e)
        let result = p.analyze(for: member())
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.contains(where: { $0.contains("Avoid") }))
    }

    func testGradeAFallback_NoPrefs_Safe() {
        let p = product(grade: .a)
        let result = p.analyze(for: member())
        XCTAssertEqual(result.verdict, .safe)
        XCTAssertTrue(result.concerns.isEmpty)
    }

    func testGradeBFallback_NoPrefs_Safe() {
        let p = product(grade: .b)
        let result = p.analyze(for: member())
        XCTAssertEqual(result.verdict, .safe)
        XCTAssertTrue(result.concerns.isEmpty)
    }

    // MARK: - Multiple preferences / worst verdict wins

    func testMultipleConcerns_WorstVerdictIsAvoid() {
        let palmFlag = IngredientFlag(name: "Refined Palm Oil", detail: "", severity: .warning)
        let p = product(vegStatus: .nonVeg, flags: [palmFlag])
        let result = p.analyze(for: member(prefs: [.pureVeg, .noPalmOil]))
        XCTAssertEqual(result.verdict, .avoid)
        XCTAssertTrue(result.concerns.count >= 2)
    }

    func testCautionAndCaution_VerdictIsStillCaution() {
        let palmFlag = IngredientFlag(name: "Refined Palm Oil", detail: "", severity: .warning)
        let p = product(sugar: 20, flags: [palmFlag])
        let result = p.analyze(for: member(prefs: [.noPalmOil, .lowSugar]))
        XCTAssertEqual(result.verdict, .caution)
        XCTAssertEqual(result.concerns.count, 2)
    }

    func testNoPrefsNoAgeIssues_Safe() {
        let p = product(grade: .a, kidSafe: true)
        let result = p.analyze(for: member(ageGroup: .adult))
        XCTAssertEqual(result.verdict, .safe)
        XCTAssertTrue(result.concerns.isEmpty)
    }

    // MARK: - FamilyMember model

    func testFamilyMemberDefaultDietPreferencesEmpty() {
        let m = FamilyMember(name: "Test", ageGroup: .adult, emoji: "👨")
        XCTAssertTrue(m.dietPreferences.isEmpty)
    }

    func testFamilyMemberWithPreferences() {
        let m = FamilyMember(name: "Test", ageGroup: .adult, emoji: "👨",
                             dietPreferences: [.pureVeg, .noPalmOil])
        XCTAssertTrue(m.dietPreferences.contains(.pureVeg))
        XCTAssertTrue(m.dietPreferences.contains(.noPalmOil))
        XCTAssertFalse(m.dietPreferences.contains(.vegan))
    }

    func testFamilyMemberCodableRoundTrip() throws {
        let m = FamilyMember(name: "Alice", ageGroup: .child, emoji: "👧",
                             dietPreferences: [.glutenFree, .lowSugar])
        let data = try JSONEncoder().encode(m)
        let decoded = try JSONDecoder().decode(FamilyMember.self, from: data)
        XCTAssertEqual(decoded.id, m.id)
        XCTAssertEqual(decoded.name, m.name)
        XCTAssertEqual(decoded.ageGroup, m.ageGroup)
        XCTAssertEqual(decoded.dietPreferences, m.dietPreferences)
    }

    func testFamilyMemberCodableBackwardsCompatibility() throws {
        // Old document without dietPreferences field should decode with empty set
        let json = """
        {"id":"\(UUID().uuidString)","name":"Bob","ageGroup":"Adult (18+ yrs)","emoji":"👨"}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(FamilyMember.self, from: json)
        XCTAssertTrue(decoded.dietPreferences.isEmpty)
    }

    // MARK: - Mock product integration

    func testBourbonBiscuitForToddler_Avoid() {
        let result = Product.mockBourbonBiscuit.analyze(for: member(ageGroup: .toddler))
        XCTAssertEqual(result.verdict, .avoid)
    }

    func testAashirvaadAttaForToddler_NotAvoid() {
        let result = Product.mockAashirvaadAtta.analyze(for: member(ageGroup: .toddler))
        XCTAssertNotEqual(result.verdict, .avoid)
    }

    func testMaggiChickenForPureVeg_Avoid() {
        let result = Product.mockMaggiChicken.analyze(for: member(prefs: [.pureVeg]))
        XCTAssertEqual(result.verdict, .avoid)
    }

    func testAashirvaadAttaForPureVeg_NoConcern() {
        let result = Product.mockAashirvaadAtta.analyze(for: member(prefs: [.pureVeg]))
        XCTAssertFalse(result.concerns.contains(where: { $0.contains("non-vegetarian") }))
    }

    func testBourbonBiscuitForDiabeticAdult_Avoid() {
        let result = Product.mockBourbonBiscuit.analyze(for: member(prefs: [.diabetic]))
        XCTAssertEqual(result.verdict, .avoid)
    }
}
