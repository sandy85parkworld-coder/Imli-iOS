import Foundation
import SwiftUI

// MARK: - Safety Grade
enum SafetyGrade: String, CaseIterable, Codable {
    case a = "A", b = "B", c = "C", d = "D", e = "E"

    var color: Color {
        switch self {
        case .a: return Color(hex: "#2E7D32")
        case .b: return Color(hex: "#558B2F")
        case .c: return Color(hex: "#E65100")
        case .d: return Color(hex: "#BF360C")
        case .e: return Color(hex: "#B71C1C")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .a: return Color(hex: "#E8F5E9")
        case .b: return Color(hex: "#F9FBE7")
        case .c: return Color(hex: "#FFF8E1")
        case .d: return Color(hex: "#FBE9E7")
        case .e: return Color(hex: "#FFEBEE")
        }
    }

    var borderColor: Color {
        switch self {
        case .a: return Color(hex: "#4CAF50")
        case .b: return Color(hex: "#CDDC39")
        case .c: return Color(hex: "#FFC107")
        case .d: return Color(hex: "#FF5722")
        case .e: return Color(hex: "#F44336")
        }
    }

    var label: String {
        switch self {
        case .a: return "Excellent"
        case .b: return "Good"
        case .c: return "Fair"
        case .d: return "Poor"
        case .e: return "Avoid"
        }
    }

    var systemIcon: String {
        switch self {
        case .a: return "checkmark.seal.fill"
        case .b: return "checkmark.circle.fill"
        case .c: return "exclamationmark.circle.fill"
        case .d: return "xmark.circle.fill"
        case .e: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Veg Status
enum VegStatus: String, Codable {
    case veg    = "Vegetarian"
    case nonVeg = "Non-Vegetarian"
    case vegan  = "Vegan"
    case jain   = "Jain"

    var color: Color {
        switch self {
        case .veg, .vegan, .jain: return Color(hex: "#2E7D32")
        case .nonVeg:              return Color(hex: "#C62828")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .veg, .vegan, .jain: return Color(hex: "#E8F5E9")
        case .nonVeg:              return Color(hex: "#FFEBEE")
        }
    }

    var borderColor: Color {
        switch self {
        case .veg, .vegan, .jain: return Color(hex: "#A5D6A7")
        case .nonVeg:              return Color(hex: "#EF9A9A")
        }
    }

    var dotColor: Color { color }
    var icon: String {
        switch self {
        case .veg:    return "circle.fill"
        case .nonVeg: return "circle.fill"
        case .vegan:  return "leaf.fill"
        case .jain:   return "circle.fill"
        }
    }
}

// MARK: - Ingredient Flag
enum FlagSeverity: String, Codable {
    case danger, warning, info, ok

    var color: Color {
        switch self {
        case .danger:  return Color(hex: "#B71C1C")
        case .warning: return Color(hex: "#E65100")
        case .info:    return Color(hex: "#1565C0")
        case .ok:      return Color(hex: "#1B5E20")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .danger:  return Color(hex: "#FFEBEE")
        case .warning: return Color(hex: "#FFF8E1")
        case .info:    return Color(hex: "#E3F2FD")
        case .ok:      return Color(hex: "#E8F5E9")
        }
    }

    var dotColor: Color {
        switch self {
        case .danger:  return Color(hex: "#F44336")
        case .warning: return Color(hex: "#FF9800")
        case .info:    return Color(hex: "#2196F3")
        case .ok:      return Color(hex: "#4CAF50")
        }
    }

    var icon: String {
        switch self {
        case .danger:  return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info:    return "info.circle.fill"
        case .ok:      return "checkmark.circle.fill"
        }
    }
}

struct IngredientFlag: Identifiable, Codable {
    let id: UUID
    let name: String
    let detail: String
    let severity: FlagSeverity
    let badge: String?

    init(id: UUID = UUID(), name: String, detail: String, severity: FlagSeverity, badge: String? = nil) {
        self.id = id; self.name = name; self.detail = detail
        self.severity = severity; self.badge = badge
    }
}

// MARK: - Nutrition Info
struct NutritionInfo: Codable {
    var energy:       Double  // kcal per 100g
    var protein:      Double  // g
    var carbs:        Double  // g
    var totalSugars:  Double  // g
    var addedSugars:  Double? // g
    var totalFat:     Double  // g
    var saturatedFat: Double  // g
    var transFat:     Double  // g
    var sodium:       Double  // mg
    var fiber:        Double? // g
    var servingSize:  String
}

// MARK: - Product
struct Product: Identifiable, Codable {
    let id: UUID
    let barcode: String
    let name: String
    let brand: String
    let category: String
    let imageEmoji: String      // placeholder until real image
    let vegStatus: VegStatus
    let grade: SafetyGrade
    let flags: [IngredientFlag]
    let nutrition: NutritionInfo
    let ingredients: String
    let alternatives: [AlternativeProduct]
    let fssaiApproved: Bool
    let kidSafe: Bool
    let kidSafeNote: String?
    let scannedAt: Date

    init(
        id: UUID = UUID(),
        barcode: String, name: String, brand: String, category: String,
        imageEmoji: String, vegStatus: VegStatus, grade: SafetyGrade,
        flags: [IngredientFlag], nutrition: NutritionInfo,
        ingredients: String, alternatives: [AlternativeProduct] = [],
        fssaiApproved: Bool = true, kidSafe: Bool, kidSafeNote: String? = nil,
        scannedAt: Date = Date()
    ) {
        self.id = id; self.barcode = barcode; self.name = name
        self.brand = brand; self.category = category; self.imageEmoji = imageEmoji
        self.vegStatus = vegStatus; self.grade = grade; self.flags = flags
        self.nutrition = nutrition; self.ingredients = ingredients
        self.alternatives = alternatives; self.fssaiApproved = fssaiApproved
        self.kidSafe = kidSafe; self.kidSafeNote = kidSafeNote; self.scannedAt = scannedAt
    }
}

// MARK: - Alternative Product
struct AlternativeProduct: Identifiable, Codable {
    let id: UUID
    let name: String
    let brand: String
    let grade: SafetyGrade
    let imageEmoji: String

    init(id: UUID = UUID(), name: String, brand: String, grade: SafetyGrade, imageEmoji: String) {
        self.id = id; self.name = name; self.brand = brand
        self.grade = grade; self.imageEmoji = imageEmoji
    }
}

// MARK: - Family Member
struct FamilyMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var ageGroup: AgeGroup
    var emoji: String

    enum AgeGroup: String, CaseIterable, Codable {
        case toddler  = "Toddler (0–2 yrs)"
        case child    = "Child (3–12 yrs)"
        case teen     = "Teen (13–17 yrs)"
        case adult    = "Adult (18+ yrs)"
        case senior   = "Senior (60+ yrs)"
    }

    init(id: UUID = UUID(), name: String, ageGroup: AgeGroup, emoji: String) {
        self.id = id; self.name = name; self.ageGroup = ageGroup; self.emoji = emoji
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var name: String
    var dietPreferences: Set<DietPreference>
    var familyMembers: [FamilyMember]
    var totalScans: Int
    var safePercentage: Double

    enum DietPreference: String, CaseIterable, Codable {
        case pureVeg    = "Pure Veg"
        case noPalmOil  = "No Palm Oil"
        case lowSugar   = "Low Sugar"
        case diabetic   = "Diabetic Safe"
        case jain       = "Jain"
        case vegan      = "Vegan"
        case glutenFree = "Gluten Free"
    }
}

// MARK: - Mock Data
extension Product {
    static let mockBourbonBiscuit = Product(
        barcode: "8901063025059",
        name: "Bourbon Biscuits Original",
        brand: "Britannia Industries",
        category: "Biscuits & Cookies",
        imageEmoji: "🍪",
        vegStatus: .veg,
        grade: .d,
        flags: [
            IngredientFlag(name: "Partially Hydrogenated Vegetable Oil", detail: "Contains trans fat (vanaspati). Linked to heart disease.", severity: .danger, badge: "Vanaspati"),
            IngredientFlag(name: "Sunset Yellow FCF (E110)", detail: "Artificial colour. Banned in some EU countries. ICMR concern.", severity: .danger, badge: "Artificial Colour"),
            IngredientFlag(name: "Total Sugar", detail: "28g per 100g — very high sugar content.", severity: .warning, badge: "28g/100g"),
            IngredientFlag(name: "Refined Palm Oil", detail: "RBD Palm Oil present. High in saturated fat.", severity: .warning, badge: "Palm Oil"),
            IngredientFlag(name: "Sodium", detail: "Moderate sodium level at 180mg per 100g.", severity: .warning, badge: "180mg"),
            IngredientFlag(name: "No MSG / E621", detail: "Monosodium glutamate not detected.", severity: .ok)
        ],
        nutrition: NutritionInfo(energy: 480, protein: 5.5, carbs: 65, totalSugars: 28, addedSugars: 26, totalFat: 22, saturatedFat: 10, transFat: 1.8, sodium: 180, fiber: 1.2, servingSize: "50g (3 biscuits)"),
        ingredients: "Refined Wheat Flour (Maida), Sugar, Partially Hydrogenated Vegetable Fat (Vanaspati), Cocoa Powder, Invert Syrup, Raising Agents (503, 500), Salt, Dough Conditioner (E472e), Artificial Colour (E110).",
        alternatives: [
            AlternativeProduct(name: "Nutri-Choice Hi-Fibre Dark", brand: "Britannia", grade: .b, imageEmoji: "🌾"),
            AlternativeProduct(name: "Digestive Biscuits", brand: "McVitie's India", grade: .b, imageEmoji: "🍘"),
            AlternativeProduct(name: "Ragi Cookies", brand: "Millet Amma", grade: .a, imageEmoji: "🌱")
        ],
        fssaiApproved: true,
        kidSafe: false,
        kidSafeNote: "Not recommended for children. Contains trans fat and artificial colours."
    )

    static let mockAashirvaadAtta = Product(
        barcode: "8901030832109",
        name: "Aashirvaad Multigrain Atta",
        brand: "ITC Limited",
        category: "Flour & Grains",
        imageEmoji: "🌾",
        vegStatus: .veg,
        grade: .a,
        flags: [
            IngredientFlag(name: "No Palm Oil", detail: "Free from refined palm oil.", severity: .ok),
            IngredientFlag(name: "No Artificial Colours", detail: "Only natural colour from whole grains.", severity: .ok),
            IngredientFlag(name: "Zero Trans Fat", detail: "No vanaspati or partially hydrogenated oil.", severity: .ok),
            IngredientFlag(name: "No Added Sugar", detail: "Contains only natural sugars from grains.", severity: .ok),
            IngredientFlag(name: "Sodium", detail: "Moderate sodium at 160mg per 100g.", severity: .warning, badge: "160mg")
        ],
        nutrition: NutritionInfo(energy: 346, protein: 12, carbs: 65, totalSugars: 2, addedSugars: 0, totalFat: 3.5, saturatedFat: 0.5, transFat: 0, sodium: 160, fiber: 7.2, servingSize: "30g (2 rotis)"),
        ingredients: "Whole Wheat Flour, Soya Flour, Oat Flour, Psyllium Husk, Maize Flour. Contains Gluten.",
        alternatives: [],
        fssaiApproved: true,
        kidSafe: true,
        kidSafeNote: "Suitable for children above 2 years. Rich in fibre and protein."
    )

    static let mockMaggiChicken = Product(
        barcode: "8901058005016",
        name: "Maggi Chicken Noodles",
        brand: "Nestlé India",
        category: "Instant Noodles",
        imageEmoji: "🍜",
        vegStatus: .nonVeg,
        grade: .c,
        flags: [
            IngredientFlag(name: "Chicken Extract", detail: "Animal-derived ingredient. Not suitable for vegetarians.", severity: .danger, badge: "Non-Veg"),
            IngredientFlag(name: "Hydrolysed Animal Protein", detail: "Derived from animal sources. Hidden non-veg ingredient.", severity: .danger, badge: "Non-Veg"),
            IngredientFlag(name: "MSG (E621)", detail: "Monosodium glutamate. Avoid for children under 5.", severity: .warning, badge: "MSG"),
            IngredientFlag(name: "Sodium", detail: "Very high sodium at 810mg per 100g.", severity: .warning, badge: "810mg/100g"),
            IngredientFlag(name: "Palm Oil (RBD)", detail: "Refined palm oil used for frying noodles.", severity: .warning, badge: "Palm Oil")
        ],
        nutrition: NutritionInfo(energy: 390, protein: 8.8, carbs: 58, totalSugars: 3.2, addedSugars: 1, totalFat: 14, saturatedFat: 6.5, transFat: 0.1, sodium: 810, fiber: 1.8, servingSize: "70g (1 pack)"),
        ingredients: "Wheat Flour, Palm Oil, Salt, Sugar, Chicken Extract (0.5%), Hydrolysed Vegetable Protein, Monosodium Glutamate (E621), Onion Powder, Turmeric.",
        alternatives: [
            AlternativeProduct(name: "Maggi Masala Noodles (Veg)", brand: "Nestlé India", grade: .c, imageEmoji: "🍜"),
            AlternativeProduct(name: "YiPPee! Magic Masala", brand: "ITC", grade: .c, imageEmoji: "🍥"),
            AlternativeProduct(name: "Whole Wheat Noodles", brand: "Patanjali", grade: .b, imageEmoji: "🌾")
        ],
        fssaiApproved: true,
        kidSafe: false,
        kidSafeNote: "Not recommended for children. Contains MSG and very high sodium."
    )
}

extension UserProfile {
    static let empty = UserProfile(
        name: "",
        dietPreferences: [],
        familyMembers: [],
        totalScans: 0,
        safePercentage: 0
    )

    static let mock = UserProfile(
        name: "Ramesh Kumar",
        dietPreferences: [.pureVeg, .noPalmOil, .lowSugar],
        familyMembers: [
            FamilyMember(name: "Baby Priya", ageGroup: .toddler, emoji: "👶"),
            FamilyMember(name: "Arjun", ageGroup: .child, emoji: "🧒")
        ],
        totalScans: 248,
        safePercentage: 61.0
    )
}
