import Foundation

enum ProteinSourceUnit: String, Codable {
    case grams = "g"
    case milliliters = "ml"

    var symbol: String {
        rawValue
    }
}

struct ProteinSource: Identifiable {
    let id = UUID()
    let name: String
    let unit: ProteinSourceUnit
    let proteinPer100g: Double

    init(name: String, proteinPer100g: Double, unit: ProteinSourceUnit = .grams) {
        self.name = name
        self.proteinPer100g = proteinPer100g
        self.unit = unit
    }
}

let defaultProteinSources: [ProteinSource] = [
    // Poultry
    ProteinSource(name: "Chicken Breast", proteinPer100g: 31),
    ProteinSource(name: "Chicken Thigh", proteinPer100g: 26),
    ProteinSource(name: "Turkey Breast", proteinPer100g: 29),
    ProteinSource(name: "Duck", proteinPer100g: 29),

    // Beef & Pork
    ProteinSource(name: "Beef", proteinPer100g: 26),
    ProteinSource(name: "Pork", proteinPer100g: 27),
    ProteinSource(name: "Lamb", proteinPer100g: 25),
    ProteinSource(name: "Veal", proteinPer100g: 29),
    ProteinSource(name: "Ham", proteinPer100g: 27),
    ProteinSource(name: "Bacon", proteinPer100g: 37),
    ProteinSource(name: "Sausage", proteinPer100g: 11),
    ProteinSource(name: "Beef Jerky", proteinPer100g: 33),

    // Fish & Seafood
    ProteinSource(name: "Salmon", proteinPer100g: 25),
    ProteinSource(name: "Tuna (Canned)", proteinPer100g: 20),
    ProteinSource(name: "Tuna (Fresh)", proteinPer100g: 29),
    ProteinSource(name: "Cod", proteinPer100g: 18),
    ProteinSource(name: "Tilapia", proteinPer100g: 26),
    ProteinSource(name: "Trout", proteinPer100g: 26),
    ProteinSource(name: "Mackerel", proteinPer100g: 27),
    ProteinSource(name: "Halibut", proteinPer100g: 26),
    ProteinSource(name: "Shrimp", proteinPer100g: 24),
    ProteinSource(name: "Sardines (Canned)", proteinPer100g: 25),

    // Eggs & Dairy
    ProteinSource(name: "Egg (Whole)", proteinPer100g: 13),
    ProteinSource(name: "Egg White", proteinPer100g: 11),
    ProteinSource(name: "Milk", proteinPer100g: 3.2, unit: .milliliters),
    ProteinSource(name: "Greek Yogurt", proteinPer100g: 10),
    ProteinSource(name: "Yogurt (Plain)", proteinPer100g: 3.5),
    ProteinSource(name: "Cottage Cheese", proteinPer100g: 11),

    // Cheese
    ProteinSource(name: "Cheddar Cheese", proteinPer100g: 25),
    ProteinSource(name: "Mozzarella", proteinPer100g: 28),
    ProteinSource(name: "Feta Cheese", proteinPer100g: 21),
    ProteinSource(name: "Parmesan Cheese", proteinPer100g: 38),

    // Legumes
    ProteinSource(name: "Lentils", proteinPer100g: 9),
    ProteinSource(name: "Chickpeas", proteinPer100g: 8),
    ProteinSource(name: "Black Beans", proteinPer100g: 9),
    ProteinSource(name: "Kidney Beans", proteinPer100g: 8),

    // Soy Products
    ProteinSource(name: "Tofu", proteinPer100g: 15),
    ProteinSource(name: "Tempeh", proteinPer100g: 19),
    ProteinSource(name: "Edamame", proteinPer100g: 11),

    // Nuts & Seeds
    ProteinSource(name: "Peanuts", proteinPer100g: 26),
    ProteinSource(name: "Almonds", proteinPer100g: 21),
    ProteinSource(name: "Peanut Butter", proteinPer100g: 8),
    ProteinSource(name: "Hemp Seeds", proteinPer100g: 10),
    ProteinSource(name: "Chia Seeds", proteinPer100g: 12),
    ProteinSource(name: "Pumpkin Seeds", proteinPer100g: 9),
    ProteinSource(name: "Sunflower Seeds", proteinPer100g: 8),

    // Grains & Other
    ProteinSource(name: "Oats", proteinPer100g: 17),
    ProteinSource(name: "Quinoa", proteinPer100g: 8),
    ProteinSource(name: "Brown Rice", proteinPer100g: 3),
    ProteinSource(name: "Pasta (Cooked)", proteinPer100g: 5),
    ProteinSource(name: "Whole Wheat Bread", proteinPer100g: 9),

    // Protein Powders
    ProteinSource(name: "Whey Protein Powder", proteinPer100g: 90),
    ProteinSource(name: "Casein Protein Powder", proteinPer100g: 80),
    ProteinSource(name: "Plant-Based Protein Powder", proteinPer100g: 75),
]
