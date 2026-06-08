import Foundation

/// Lokaal berekende, feitelijke observaties over de afgelopen week.
/// Bevat geen adviezen of klinische interpretatie.
struct WeeklyInsight {
    let avgDailyBS: Double?
    let minBS: Double?
    let maxBS: Double?
    let bsDataPoints: Int

    let avgBSChangeAfterHighGI: Double?
    let highGIDataPoints: Int
    let avgBSChangeAfterLowGI: Double?
    let lowGIDataPoints: Int

    let avgBSHighActivity: Double?
    let avgBSLowActivity: Double?
    let activityDataAvailable: Bool

    let avgDailyCarbs: Double?

    /// Minimaal aantal bloedsuikermetingen voordat inzichten getoond worden.
    static let minimumReadings = 5

    /// Minimaal aantal datapunten per GI-categorie voordat die vergelijking getoond wordt.
    static let minimumPerCategory = 3

    var hasEnoughData: Bool {
        bsDataPoints >= Self.minimumReadings
    }

    var showsGIComparison: Bool {
        highGIDataPoints >= Self.minimumPerCategory && lowGIDataPoints >= Self.minimumPerCategory
    }

    static let empty = WeeklyInsight(
        avgDailyBS: nil,
        minBS: nil,
        maxBS: nil,
        bsDataPoints: 0,
        avgBSChangeAfterHighGI: nil,
        highGIDataPoints: 0,
        avgBSChangeAfterLowGI: nil,
        lowGIDataPoints: 0,
        avgBSHighActivity: nil,
        avgBSLowActivity: nil,
        activityDataAvailable: false,
        avgDailyCarbs: nil
    )
}

extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
