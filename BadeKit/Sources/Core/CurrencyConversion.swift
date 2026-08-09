import Foundation

/// What the bank did to a foreign charge. The gap between the scheme's rate and the bank's own
/// rate is the markup §8 reports.
public struct CurrencyConversion: Equatable, Sendable, Codable {
    public let from: String
    public let to: String
    /// The rate the bank actually charged.
    public let bankRate: Decimal
    /// The card scheme's reference rate, when the statement prints it.
    public let schemeRate: Decimal?

    public init(from: String, to: String, bankRate: Decimal, schemeRate: Decimal? = nil) {
        self.from = from
        self.to = to
        self.bankRate = bankRate
        self.schemeRate = schemeRate
    }

    public var markupFraction: Decimal? {
        guard let schemeRate, schemeRate > 0 else { return nil }
        return (bankRate - schemeRate) / schemeRate
    }
}

/// Rates observed in a statement, so totals can span currencies using what the bank really
/// charged rather than a published rate. §10's FX module adds published NBG rates alongside these.
///
/// Dated, because one rate cannot describe a long statement: across eighteen months a lari rate
/// drifts several percent, and a charge should be converted at a rate from around when it landed.
public struct RateBook: Equatable, Sendable, Codable {
    private var observed: [String: [ObservedRate]] = [:]

    public init() {}

    /// Every observation, so a store can persist them and hand them back later.
    public var observations: [ObservedRate] { observed.values.flatMap { $0 } }

    public mutating func record(_ rate: ObservedRate) {
        guard rate.rate > 0, rate.from != rate.to else { return }
        observed[Self.key(rate.from, rate.to), default: []].append(rate)
    }

    public mutating func record(_ conversion: CurrencyConversion, on date: Date) {
        record(
            ObservedRate(
                date: date, from: conversion.from, to: conversion.to, rate: conversion.bankRate))
    }

    /// The rate closest in time to the charge. Nothing extrapolates: a pair never seen stays
    /// unconvertible rather than being guessed at.
    public func rate(from: String, to: String, on date: Date) -> Decimal? {
        if from == to { return 1 }
        if let direct = nearest(Self.key(from, to), to: date) { return direct }
        if let inverse = nearest(Self.key(to, from), to: date), inverse > 0 { return 1 / inverse }
        return nil
    }

    public func convert(_ amount: Decimal, from: String, to: String, on date: Date) -> Decimal? {
        rate(from: from, to: to, on: date).map { amount * $0 }
    }

    private func nearest(_ key: String, to date: Date) -> Decimal? {
        observed[key]?
            .min {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            }?
            .rate
    }

    private static func key(_ from: String, _ to: String) -> String { "\(from)|\(to)" }
}
