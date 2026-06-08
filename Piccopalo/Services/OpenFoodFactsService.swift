import Foundation

enum OpenFoodFactsError: LocalizedError, Equatable {
    case invalidBarcode
    case productNotFound
    case missingProteinData
    case requestTimeout
    case network

    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return "Barcode niet herkend. Probeer opnieuw of voer het eiwit handmatig in."
        case .productNotFound, .missingProteinData:
            return "Product niet gevonden. Je kunt het eiwit zelf invullen."
        case .requestTimeout:
            return "Zoeken duurde te lang. Probeer opnieuw."
        case .network:
            return "Geen verbinding. Controleer je internet en probeer opnieuw."
        }
    }
}

struct FoodProduct {
    let name: String
    let proteinPer100g: Double
    let servingSizeGrams: Double?
    let carbsPer100g: Double?
    let fiberPer100g: Double?
    let fatPer100g: Double?
    let glycemicIndex: Int?

    init(
        name: String,
        proteinPer100g: Double,
        servingSizeGrams: Double?,
        carbsPer100g: Double? = nil,
        fiberPer100g: Double? = nil,
        fatPer100g: Double? = nil,
        glycemicIndex: Int? = nil
    ) {
        self.name = name
        self.proteinPer100g = proteinPer100g
        self.servingSizeGrams = servingSizeGrams
        self.carbsPer100g = carbsPer100g
        self.fiberPer100g = fiberPer100g
        self.fatPer100g = fatPer100g
        self.glycemicIndex = glycemicIndex
    }

    var glycemicCategory: GICategory {
        GICategory(glycemicIndex: glycemicIndex)
    }

    /// Glycemische lading voor een gegeven portie (gram).
    func glycemicLoad(forPortionGrams grams: Double) -> Double? {
        guard let gi = glycemicIndex, let carbsPer100 = carbsPer100g, grams > 0 else { return nil }
        let carbsForPortion = (grams / 100) * carbsPer100
        return (Double(gi) * carbsForPortion) / 100.0
    }
}

struct OpenFoodFactsService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 8
        self.session = URLSession(configuration: config)
    }

    func fetchProduct(barcode: String) async throws -> FoodProduct {
        guard barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw OpenFoodFactsError.invalidBarcode
        }

        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode)?fields=product_name,nutriments,serving_size") else {
            throw OpenFoodFactsError.invalidBarcode
        }
        // nutriments bevat alle voedingswaarden (incl. carbohydrates_100g,
        // fiber_100g, fat_100g en het zeldzame glycemic_index_100g).

        let request = URLRequest(url: url)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  200..<300 ~= http.statusCode else {
                throw OpenFoodFactsError.network
            }

            let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            guard decoded.status == 1, let product = decoded.product else {
                throw OpenFoodFactsError.productNotFound
            }

            let protein = product.nutriments?.proteins100g ?? 0
            guard protein > 0 else {
                throw OpenFoodFactsError.missingProteinData
            }

            let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackName = "Onbekend product"
            let nutriments = product.nutriments
            return FoodProduct(
                name: (name?.isEmpty == false ? name! : fallbackName),
                proteinPer100g: protein,
                servingSizeGrams: Self.parseServingSizeGrams(product.servingSize),
                carbsPer100g: nutriments?.carbohydrates100g,
                fiberPer100g: nutriments?.fiber100g,
                fatPer100g: nutriments?.fat100g,
                glycemicIndex: nutriments?.glycemicIndex100g.map { Int($0.rounded()) }
            )
        } catch let error as OpenFoodFactsError {
            throw error
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain,
               nsError.code == NSURLErrorTimedOut {
                throw OpenFoodFactsError.requestTimeout
            }
            throw OpenFoodFactsError.network
        }
    }

    private static func parseServingSizeGrams(_ raw: String?) -> Double? {
        guard let raw, raw.isEmpty == false else { return nil }

        let lower = raw.lowercased()
        guard lower.contains("g") else { return nil }

        let normalized = lower.replacingOccurrences(of: ",", with: ".")
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*g"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              let range = Range(match.range(at: 1), in: normalized) else {
            return nil
        }

        return Double(String(normalized[range]))
    }
}

private struct OpenFoodFactsResponse: Decodable {
    let status: Int?
    let product: OpenFoodFactsProduct?
}

private struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let nutriments: OpenFoodFactsNutriments?
    let servingSize: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case servingSize = "serving_size"
    }
}

private struct OpenFoodFactsNutriments: Decodable {
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fiber100g: Double?
    let fat100g: Double?
    let glycemicIndex100g: Double?

    enum CodingKeys: String, CodingKey {
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fiber100g = "fiber_100g"
        case fat100g = "fat_100g"
        case glycemicIndex100g = "glycemic_index_100g"
    }
}
