import Foundation

extension Duration {
    var seconds: Double { Double(components.seconds) + Double(components.attoseconds) / 1e18 }
}

enum ParsingTiming {
    static let perRow: Duration = .milliseconds(350)
    static let maximumReveal: Duration = .seconds(6)
    static let completionPause: Duration = .milliseconds(600)

    /// Long statements would otherwise crawl, so the pace tightens as the list grows.
    static func interval(forRows rows: Int) -> Duration {
        guard rows > 0 else { return perRow }
        let paced = perRow * rows
        return paced <= maximumReveal ? perRow : maximumReveal / rows
    }
}
