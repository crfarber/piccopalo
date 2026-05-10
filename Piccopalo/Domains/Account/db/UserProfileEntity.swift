import Foundation
import SwiftData

@Model
final class UserProfileEntity {
    var name: String
    var weight: Double
    var height: Double
    var activityFactor: Double

    init(name: String, weight: Double, height: Double, activityFactor: Double) {
        self.name = name
        self.weight = weight
        self.height = height
        self.activityFactor = activityFactor
    }

    convenience init(from data: AccountData) {
        self.init(
            name: data.name,
            weight: data.weight,
            height: data.height,
            activityFactor: data.activityFactor
        )
    }

    func apply(from data: AccountData) {
        name = data.name
        weight = data.weight
        height = data.height
        activityFactor = data.activityFactor
    }

    var asAccountData: AccountData {
        AccountData(name: name, weight: weight, height: height, activityFactor: activityFactor)
    }
}
