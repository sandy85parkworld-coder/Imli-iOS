import XCTest
@testable import Imli

final class ModelTests: XCTestCase {

    // MARK: - SafetyGrade

    func testSafetyGradeRawValues() {
        XCTAssertEqual(SafetyGrade.a.rawValue, "A")
        XCTAssertEqual(SafetyGrade.b.rawValue, "B")
        XCTAssertEqual(SafetyGrade.c.rawValue, "C")
        XCTAssertEqual(SafetyGrade.d.rawValue, "D")
        XCTAssertEqual(SafetyGrade.e.rawValue, "E")
    }

    func testSafetyGradeLabels() {
        XCTAssertEqual(SafetyGrade.a.label, "Excellent")
        XCTAssertEqual(SafetyGrade.b.label, "Good")
        XCTAssertEqual(SafetyGrade.c.label, "Fair")
        XCTAssertEqual(SafetyGrade.d.label, "Poor")
        XCTAssertEqual(SafetyGrade.e.label, "Avoid")
    }

    func testSafetyGradeSystemIcons() {
        XCTAssertEqual(SafetyGrade.a.systemIcon, "checkmark.seal.fill")
        XCTAssertEqual(SafetyGrade.b.systemIcon, "checkmark.circle.fill")
        XCTAssertEqual(SafetyGrade.c.systemIcon, "exclamationmark.circle.fill")
        XCTAssertEqual(SafetyGrade.d.systemIcon, "xmark.circle.fill")
        XCTAssertEqual(SafetyGrade.e.systemIcon, "xmark.octagon.fill")
    }

    func testSafetyGradeAllCasesCount() {
        XCTAssertEqual(SafetyGrade.allCases.count, 5)
    }

    func testSafetyGradeCodable() throws {
        let encoded = try JSONEncoder().encode(SafetyGrade.a)
        let decoded = try JSONDecoder().decode(SafetyGrade.self, from: encoded)
        XCTAssertEqual(decoded, .a)
    }

    // MARK: - VegStatus

    func testVegStatusRawValues() {
        XCTAssertEqual(VegStatus.veg.rawValue, "Vegetarian")
        XCTAssertEqual(VegStatus.nonVeg.rawValue, "Non-Vegetarian")
        XCTAssertEqual(VegStatus.vegan.rawValue, "Vegan")
        XCTAssertEqual(VegStatus.jain.rawValue, "Jain")
    }

    func testVegStatusIcons() {
        XCTAssertEqual(VegStatus.veg.icon, "circle.fill")
        XCTAssertEqual(VegStatus.nonVeg.icon, "circle.fill")
        XCTAssertEqual(VegStatus.vegan.icon, "leaf.fill")
        XCTAssertEqual(VegStatus.jain.icon, "circle.fill")
    }

    func testVegStatusCodable() throws {
        let encoded = try JSONEncoder().encode(VegStatus.vegan)
        let decoded = try JSONDecoder().decode(VegStatus.self, from: encoded)
        XCTAssertEqual(decoded, .vegan)
    }

    // MARK: - FlagSeverity

    func testFlagSeverityIcons() {
        XCTAssertEqual(FlagSeverity.danger.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(FlagSeverity.warning.icon, "exclamationmark.circle.fill")
        XCTAssertEqual(FlagSeverity.info.icon, "info.circle.fill")
        XCTAssertEqual(FlagSeverity.ok.icon, "checkmark.circle.fill")
    }

    func testFlagSeverityCodable() throws {
        for severity in [FlagSeverity.danger, .warning, .info, .ok] {
            let encoded = try JSONEncoder().encode(severity)
            let decoded = try JSONDecoder().decode(FlagSeverity.self, from: encoded)
            XCTAssertEqual(decoded, severity)
        }
    }

    // MARK: - IngredientFlag

    func testIngredientFlagInitializationWithBadge() {
        let flag = IngredientFlag(name: "Palm Oil", detail: "High saturated fat", severity: .warning, badge: "High")
        XCTAssertFalse(flag.id.uuidString.isEmpty)
        XCTAssertEqual(flag.name, "Palm Oil")
        XCTAssertEqual(flag.detail, "High saturated fat")
        XCTAssertEqual(flag.severity, .warning)
        XCTAssertEqual(flag.badge, "High")
    }

    func testIngredientFlagInitializationWithoutBadge() {
        let flag = IngredientFlag(name: "No MSG", detail: "Not detected", severity: .ok)
        XCTAssertNil(flag.badge)
    }

    func testIngredientFlagUniqueIDs() {
        let f1 = IngredientFlag(name: "A", detail: "", severity: .ok)
        let f2 = IngredientFlag(name: "A", detail: "", severity: .ok)
        XCTAssertNotEqual(f1.id, f2.id)
    }

    func testIngredientFlagCodable() throws {
        let flag = IngredientFlag(name: "Sugar", detail: "High sugar", severity: .warning, badge: "28g")
        let encoded = try JSONEncoder().encode(flag)
        let decoded = try JSONDecoder().decode(IngredientFlag.self, from: encoded)
        XCTAssertEqual(decoded.id, flag.id)
        XCTAssertEqual(decoded.name, flag.name)
        XCTAssertEqual(decoded.severity, flag.severity)
        XCTAssertEqual(decoded.badge, flag.badge)
    }

    // MARK: - NutritionInfo

    func testNutritionInfoWithAllFields() {
        let n = NutritionInfo(
            energy: 400, protein: 10, carbs: 50,
            totalSugars: 20, addedSugars: 15,
            totalFat: 18, saturatedFat: 8, transFat: 0.5,
            sodium: 200, fiber: 3, servingSize: "100g"
        )
        XCTAssertEqual(n.energy, 400)
        XCTAssertEqual(n.protein, 10)
        XCTAssertEqual(n.totalSugars, 20)
        XCTAssertEqual(n.addedSugars, 15)
        XCTAssertEqual(n.transFat, 0.5)
        XCTAssertEqual(n.fiber, 3)
        XCTAssertEqual(n.servingSize, "100g")
    }

    func testNutritionInfoOptionalFieldsNil() {
        let n = NutritionInfo(
            energy: 346, protein: 12, carbs: 65,
            totalSugars: 2, addedSugars: nil,
            totalFat: 3.5, saturatedFat: 0.5, transFat: 0,
            sodium: 160, fiber: nil, servingSize: "30g"
        )
        XCTAssertNil(n.fiber)
        XCTAssertNil(n.addedSugars)
    }

    func testNutritionInfoCodable() throws {
        let n = NutritionInfo(
            energy: 480, protein: 5.5, carbs: 65,
            totalSugars: 28, addedSugars: 26,
            totalFat: 22, saturatedFat: 10, transFat: 1.8,
            sodium: 180, fiber: 1.2, servingSize: "50g"
        )
        let encoded = try JSONEncoder().encode(n)
        let decoded = try JSONDecoder().decode(NutritionInfo.self, from: encoded)
        XCTAssertEqual(decoded.energy, n.energy)
        XCTAssertEqual(decoded.sodium, n.sodium)
        XCTAssertEqual(decoded.fiber, n.fiber)
    }

    // MARK: - Product mock data

    func testMockBourbonBiscuit() {
        let p = Product.mockBourbonBiscuit
        XCTAssertEqual(p.barcode, "8901063025059")
        XCTAssertEqual(p.name, "Bourbon Biscuits Original")
        XCTAssertEqual(p.brand, "Britannia Industries")
        XCTAssertEqual(p.vegStatus, .veg)
        XCTAssertEqual(p.grade, .d)
        XCTAssertFalse(p.kidSafe)
        XCTAssertNotNil(p.kidSafeNote)
        XCTAssertTrue(p.fssaiApproved)
        XCTAssertFalse(p.flags.isEmpty)
        XCTAssertFalse(p.alternatives.isEmpty)
    }

    func testMockBourbonBiscuitHasDangerFlags() {
        let dangerFlags = Product.mockBourbonBiscuit.flags.filter { $0.severity == .danger }
        XCTAssertFalse(dangerFlags.isEmpty, "Bourbon biscuit should have at least one danger flag")
    }

    func testMockAashirvaadAtta() {
        let p = Product.mockAashirvaadAtta
        XCTAssertEqual(p.barcode, "8901030832109")
        XCTAssertEqual(p.grade, .a)
        XCTAssertTrue(p.kidSafe)
        XCTAssertNotNil(p.kidSafeNote)
        XCTAssertTrue(p.alternatives.isEmpty)
        XCTAssertEqual(p.vegStatus, .veg)
    }

    func testMockAashirvaadAttaHasNoTransFat() {
        let p = Product.mockAashirvaadAtta
        XCTAssertEqual(p.nutrition.transFat, 0)
    }

    func testMockMaggiChicken() {
        let p = Product.mockMaggiChicken
        XCTAssertEqual(p.barcode, "8901058005016")
        XCTAssertEqual(p.vegStatus, .nonVeg)
        XCTAssertEqual(p.grade, .c)
        XCTAssertFalse(p.kidSafe)
        XCTAssertFalse(p.alternatives.isEmpty)
    }

    func testMockMaggiChickenHighSodium() {
        XCTAssertGreaterThan(Product.mockMaggiChicken.nutrition.sodium, 500)
    }

    func testAllMocksHaveUniqueIDs() {
        let ids = [Product.mockBourbonBiscuit.id, Product.mockAashirvaadAtta.id, Product.mockMaggiChicken.id]
        XCTAssertEqual(Set(ids).count, ids.count, "Mock products should have unique IDs")
    }

    func testAllMocksHaveUniqueUUIDs() {
        let p1 = Product.mockBourbonBiscuit
        let p2 = Product.mockBourbonBiscuit
        XCTAssertNotEqual(p1.id, p2.id, "Each mock call should produce a new UUID")
    }

    func testProductCodable() throws {
        let product = Product.mockBourbonBiscuit
        let encoded = try JSONEncoder().encode(product)
        let decoded = try JSONDecoder().decode(Product.self, from: encoded)
        XCTAssertEqual(decoded.id, product.id)
        XCTAssertEqual(decoded.barcode, product.barcode)
        XCTAssertEqual(decoded.grade, product.grade)
        XCTAssertEqual(decoded.vegStatus, product.vegStatus)
        XCTAssertEqual(decoded.flags.count, product.flags.count)
    }

    // MARK: - AlternativeProduct

    func testAlternativeProductInitialization() {
        let alt = AlternativeProduct(name: "Ragi Cookies", brand: "Millet Amma", grade: .a, imageEmoji: "🌱")
        XCTAssertFalse(alt.id.uuidString.isEmpty)
        XCTAssertEqual(alt.name, "Ragi Cookies")
        XCTAssertEqual(alt.brand, "Millet Amma")
        XCTAssertEqual(alt.grade, .a)
        XCTAssertEqual(alt.imageEmoji, "🌱")
    }

    // MARK: - FamilyMember

    func testFamilyMemberAgeGroupAllCases() {
        XCTAssertEqual(FamilyMember.AgeGroup.allCases.count, 5)
    }

    func testFamilyMemberAgeGroupRawValues() {
        XCTAssertEqual(FamilyMember.AgeGroup.toddler.rawValue, "Toddler (0–2 yrs)")
        XCTAssertEqual(FamilyMember.AgeGroup.child.rawValue, "Child (3–12 yrs)")
        XCTAssertEqual(FamilyMember.AgeGroup.teen.rawValue, "Teen (13–17 yrs)")
        XCTAssertEqual(FamilyMember.AgeGroup.adult.rawValue, "Adult (18+ yrs)")
        XCTAssertEqual(FamilyMember.AgeGroup.senior.rawValue, "Senior (60+ yrs)")
    }

    func testFamilyMemberInitialization() {
        let member = FamilyMember(name: "Arjun", ageGroup: .child, emoji: "🧒")
        XCTAssertFalse(member.id.uuidString.isEmpty)
        XCTAssertEqual(member.name, "Arjun")
        XCTAssertEqual(member.ageGroup, .child)
        XCTAssertEqual(member.emoji, "🧒")
    }

    // MARK: - UserProfile

    func testUserProfileDietPreferenceAllCases() {
        XCTAssertEqual(UserProfile.DietPreference.allCases.count, 7)
    }

    func testUserProfileDietPreferenceRawValues() {
        XCTAssertEqual(UserProfile.DietPreference.pureVeg.rawValue, "Pure Veg")
        XCTAssertEqual(UserProfile.DietPreference.noPalmOil.rawValue, "No Palm Oil")
        XCTAssertEqual(UserProfile.DietPreference.lowSugar.rawValue, "Low Sugar")
        XCTAssertEqual(UserProfile.DietPreference.diabetic.rawValue, "Diabetic Safe")
        XCTAssertEqual(UserProfile.DietPreference.jain.rawValue, "Jain")
        XCTAssertEqual(UserProfile.DietPreference.vegan.rawValue, "Vegan")
        XCTAssertEqual(UserProfile.DietPreference.glutenFree.rawValue, "Gluten Free")
    }

    func testMockUserProfile() {
        let profile = UserProfile.mock
        XCTAssertEqual(profile.name, "Ramesh Kumar")
        XCTAssertEqual(profile.familyMembers.count, 2)
        XCTAssertEqual(profile.familyMembers[0].ageGroup, .toddler)
        XCTAssertEqual(profile.familyMembers[1].ageGroup, .child)
        XCTAssertTrue(profile.dietPreferences.contains(.pureVeg))
        XCTAssertTrue(profile.dietPreferences.contains(.noPalmOil))
        XCTAssertTrue(profile.dietPreferences.contains(.lowSugar))
        XCTAssertGreaterThan(profile.totalScans, 0)
        XCTAssertGreaterThanOrEqual(profile.safePercentage, 0)
        XCTAssertLessThanOrEqual(profile.safePercentage, 100)
    }
}
