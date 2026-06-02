import Foundation

// MARK: - Open Food Facts decodable models

private struct OFFResponse: Decodable {
    let status: String
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let productName: String?
    let brands: String?
    let categories: String?
    let ingredientsText: String?
    let servingSize: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case productName    = "product_name"
        case brands, categories
        case ingredientsText = "ingredients_text"
        case servingSize    = "serving_size"
        case nutriments
    }
}

private struct OFFNutriments: Decodable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let sugars: Double?
    let fat: Double?
    let saturatedFat: Double?
    let transFat: Double?
    let sodiumG: Double?   // OFN stores sodium in grams per 100g
    let fiber: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal    = "energy-kcal_100g"
        case proteins      = "proteins_100g"
        case carbohydrates = "carbohydrates_100g"
        case sugars        = "sugars_100g"
        case fat           = "fat_100g"
        case saturatedFat  = "saturated-fat_100g"
        case transFat      = "trans-fat_100g"
        case sodiumG       = "sodium_100g"
        case fiber         = "fiber_100g"
    }
}

// MARK: - Service

final class ProductAPIService {
    static let shared = ProductAPIService()
    private init() {}

    private let baseURL = "https://world.openfoodfacts.org/api/v3/product"

    func fetchProduct(barcode: String) async throws -> Product? {
        guard let url = URL(string: "\(baseURL)/\(barcode)") else { return nil }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("ImliApp/1.0 (iOS; food-safety-scanner)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

        let offResponse = try JSONDecoder().decode(OFFResponse.self, from: data)
        guard offResponse.status == "product_found", let off = offResponse.product else { return nil }

        return map(off, barcode: barcode)
    }

    // MARK: - Mapping

    private func map(_ off: OFFProduct, barcode: String) -> Product {
        let n = off.nutriments
        let sodiumMg = (n?.sodiumG ?? 0) * 1000
        let ingredients = off.ingredientsText ?? ""

        let nutrition = NutritionInfo(
            energy:       n?.energyKcal    ?? 0,
            protein:      n?.proteins      ?? 0,
            carbs:        n?.carbohydrates ?? 0,
            totalSugars:  n?.sugars        ?? 0,
            addedSugars:  nil,
            totalFat:     n?.fat           ?? 0,
            saturatedFat: n?.saturatedFat  ?? 0,
            transFat:     n?.transFat      ?? 0,
            sodium:       sodiumMg,
            fiber:        n?.fiber,
            servingSize:  off.servingSize  ?? "100g"
        )

        let flags       = extractFlags(nutrition: nutrition, ingredients: ingredients)
        let grade       = calculateGrade(nutrition: nutrition, flags: flags)
        let vegStatus   = detectVegStatus(ingredients)

        return Product(
            barcode:      barcode,
            name:         off.productName?.trimmingCharacters(in: .whitespaces) ?? "Unknown Product",
            brand:        off.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "Unknown Brand",
            category:     off.categories?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "Food",
            imageEmoji:   emojiForCategory(off.categories ?? ""),
            vegStatus:    vegStatus,
            grade:        grade,
            flags:        flags,
            nutrition:    nutrition,
            ingredients:  ingredients.isEmpty ? "Not available" : ingredients,
            alternatives: [],
            fssaiApproved: true,
            kidSafe:      grade == .a || grade == .b,
            kidSafeNote:  grade == .a || grade == .b ? nil : "Check ingredients before giving to children.",
            scannedAt:    Date()
        )
    }

    // MARK: - Grade Calculation

    private func calculateGrade(nutrition n: NutritionInfo, flags: [IngredientFlag]) -> SafetyGrade {
        var score = 0

        // Trans fat (highest risk)
        if n.transFat > 0.2 { score += 4 } else if n.transFat > 0 { score += 2 }

        // Sugars per 100g
        if n.totalSugars > 30 { score += 3 } else if n.totalSugars > 20 { score += 2 } else if n.totalSugars > 10 { score += 1 }

        // Sodium (mg per 100g)
        if n.sodium > 800 { score += 3 } else if n.sodium > 500 { score += 2 } else if n.sodium > 300 { score += 1 }

        // Saturated fat
        if n.saturatedFat > 10 { score += 2 } else if n.saturatedFat > 6 { score += 1 }

        // Fibre bonus
        if let fiber = n.fiber { if fiber > 5 { score -= 1 } }

        // Danger-flag penalty
        let dangerCount = flags.filter { $0.severity == .danger }.count
        score += dangerCount

        switch score {
        case ..<3:  return .a
        case 3..<5: return .b
        case 5..<8: return .c
        case 8..<11:return .d
        default:    return .e
        }
    }

    // MARK: - Veg Status Detection

    private func detectVegStatus(_ ingredients: String) -> VegStatus {
        let lower = ingredients.lowercased()
        let nonVegTerms = ["chicken", "mutton", "beef", "pork", "fish", "prawn", "shrimp",
                           "anchov", "gelatin", "rennet", "lard", "tallow", "egg", "albumin",
                           "hydrolysed animal", "animal fat", "suet"]
        if nonVegTerms.contains(where: { lower.contains($0) }) { return .nonVeg }

        let veganTerms = ["vegan", "plant-based"]
        if veganTerms.contains(where: { lower.contains($0) }) { return .vegan }

        return .veg
    }

    // MARK: - Ingredient Flags

    private func extractFlags(nutrition n: NutritionInfo, ingredients: String) -> [IngredientFlag] {
        var flags: [IngredientFlag] = []
        let lower = ingredients.lowercased()

        // Trans fat
        if n.transFat > 0.2 {
            flags.append(.init(name: "Trans Fat Detected", detail: "Contains \(String(format: "%.1f", n.transFat))g trans fat per 100g. Linked to heart disease.", severity: .danger, badge: "Trans Fat"))
        } else if lower.contains("vanaspati") || lower.contains("hydrogenated") {
            flags.append(.init(name: "Partially Hydrogenated Oil", detail: "May contain trans fats. Linked to heart disease — avoid for children.", severity: .danger, badge: "Trans Fat Risk"))
        }

        // High sugar
        if n.totalSugars > 30 {
            flags.append(.init(name: "Very High Sugar", detail: "\(Int(n.totalSugars))g sugar per 100g — well above recommended levels.", severity: .danger, badge: "\(Int(n.totalSugars))g/100g"))
        } else if n.totalSugars > 20 {
            flags.append(.init(name: "High Sugar Content", detail: "\(Int(n.totalSugars))g sugar per 100g.", severity: .warning, badge: "\(Int(n.totalSugars))g"))
        }

        // High sodium
        if n.sodium > 800 {
            flags.append(.init(name: "Very High Sodium", detail: "\(Int(n.sodium))mg sodium per 100g — far above daily limits for children.", severity: .danger, badge: "\(Int(n.sodium))mg"))
        } else if n.sodium > 400 {
            flags.append(.init(name: "High Sodium", detail: "\(Int(n.sodium))mg sodium per 100g. Monitor intake.", severity: .warning, badge: "\(Int(n.sodium))mg"))
        }

        // Palm oil
        if lower.contains("palm oil") || lower.contains("palmolein") || lower.contains("palm olein") {
            flags.append(.init(name: "Refined Palm Oil", detail: "High in saturated fats. Environmental concerns.", severity: .warning, badge: "Palm Oil"))
        }

        // Artificial colours
        let artificialColours = ["e102", "e104", "e110", "e122", "e124", "e129", "e131", "e133"]
        if artificialColours.contains(where: { lower.contains($0) }) {
            flags.append(.init(name: "Artificial Colours", detail: "Contains synthetic food dyes. Some banned in EU countries.", severity: .danger, badge: "Artificial Colour"))
        }

        // MSG
        if lower.contains("e621") || lower.contains("monosodium glutamate") || lower.contains(" msg") {
            flags.append(.init(name: "MSG (E621)", detail: "Monosodium glutamate. Avoid for children under 5.", severity: .warning, badge: "MSG"))
        }

        // Maida / refined flour
        if lower.contains("maida") || lower.contains("refined wheat flour") {
            flags.append(.init(name: "Refined Wheat Flour (Maida)", detail: "Low nutritional value. Prefer whole-grain alternatives.", severity: .info))
        }

        // All clear flag if no issues
        if flags.isEmpty {
            flags.append(.init(name: "No Major Concerns", detail: "No high-risk additives detected in ingredient list.", severity: .ok))
        }

        return flags
    }

    // MARK: - Category Emoji

    private func emojiForCategory(_ categories: String) -> String {
        let lower = categories.lowercased()
        if lower.contains("biscuit") || lower.contains("cookie")   { return "🍪" }
        if lower.contains("chocolate")                              { return "🍫" }
        if lower.contains("noodle") || lower.contains("pasta")     { return "🍜" }
        if lower.contains("chip") || lower.contains("snack")       { return "🥨" }
        if lower.contains("beverage") || lower.contains("drink")   { return "🧃" }
        if lower.contains("dairy") || lower.contains("milk")       { return "🥛" }
        if lower.contains("bread") || lower.contains("bakery")     { return "🍞" }
        if lower.contains("cereal") || lower.contains("grain")     { return "🌾" }
        if lower.contains("fruit")                                  { return "🍎" }
        if lower.contains("vegetable")                              { return "🥦" }
        if lower.contains("sauce") || lower.contains("condiment")  { return "🫙" }
        if lower.contains("oil")                                    { return "🫒" }
        if lower.contains("spice") || lower.contains("masala")     { return "🌶️" }
        return "🛒"
    }
}
