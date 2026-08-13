public enum Cadence: String, Equatable, Sendable, Codable, CaseIterable {
    case weekly, monthly, quarterly, semiannual, annual

    /// Day-delta window the detection engine votes a cadence into (spec §7.3).
    public var approximateDays: ClosedRange<Int> {
        switch self {
        case .weekly: 6...8
        case .monthly: 28...31
        case .quarterly: 88...95
        case .semiannual: 178...186
        case .annual: 360...370
        }
    }
}
