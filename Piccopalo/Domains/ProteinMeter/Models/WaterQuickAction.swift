import Foundation

enum WaterQuickAction: Equatable {
    case fixed(milliliters: Int)
    case custom

    var label: String {
        switch self {
        case .fixed(let ml):
            return "+\(ml)ml"
        case .custom:
            return "+ Zelf"
        }
    }
}
