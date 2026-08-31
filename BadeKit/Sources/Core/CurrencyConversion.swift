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
    /// Kept apart from what a bank charged rather than merged into it: the gap between the two is
    /// the markup §8 exists to report, and one book holding both could no longer tell them apart.
    /// Optional so a widget snapshot written before there were any still decodes.
    private var published: PublishedRates?

    public init() {}

    /// Every observation, so a store can persist them and hand them back later.
    public var observations: [ObservedRate] { observed.values.flatMap { $0 } }

    public mutating func record(_ rate: ObservedRate) {
        guard rate.rate > 0, rate.from != rate.to else { return }
        observed[Self.key(rate.from, rate.to), default: []].append(rate)
    }

    /// Fills the pairs no statement ever converted — which on an account that pays each currency
    /// from its own balance is every pair there is, leaving a headline total that silently omits
    /// them. A publisher quotes everything against one base, so a pair it never lists directly is
    /// still bridged through that base: both legs the same publisher on the same day.
    public mutating func record(_ rates: [OfficialRate], base: String) {
        guard !rates.isEmpty else { return }
        published = PublishedRates(base: base, rates: (published?.rates ?? []) + rates)
    }

    public mutating func record(_ conversion: CurrencyConversion, on date: Date) {
        record(
            ObservedRate(
                date: date, from: conversion.from, to: conversion.to, rate: conversion.bankRate))
    }

    /// The rate closest in time to the charge. What the bank charged is preferred over what anyone
    /// published, because it is what actually happened to this money; the published rate answers
    /// only where no statement ever converted the pair. Nothing extrapolates beyond that: a pair
    /// neither the bank nor the publisher priced stays unconvertible rather than being guessed at.
    public func rate(from: String, to: String, on date: Date) -> Decimal? {
        if from == to { return 1 }
        if let direct = nearest(Self.key(from, to), to: date) { return direct }
        if let inverse = nearest(Self.key(to, from), to: date), inverse > 0 { return 1 / inverse }
        return published?.rate(from: from, to: to, on: date)
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

/// One publisher's rates for a run of days, every one of them quoted against a single base
/// currency. That shared base is the whole point: it bridges a pair the publisher never lists,
/// without the app ever inventing a rate of its own.
///
/// A central bank publishes on working days, so the rate for a given day is the nearest one it
/// actually published — otherwise a total read on a Sunday would empty itself.
public struct PublishedRates: Equatable, Sendable, Codable {
    /// What everything is quoted in. Never appears among the rates: it is worth one of itself.
    public let base: String
    public let rates: [OfficialRate]

    public init(base: String, rates: [OfficialRate]) {
        self.base = base
        self.rates = rates
    }

    func rate(from: String, to: String, on date: Date) -> Decimal? {
        guard let source = perBase(from, on: date), let target = perBase(to, on: date), target > 0
        else { return nil }
        return source / target
    }

    private func perBase(_ code: String, on date: Date) -> Decimal? {
        guard code != base else { return 1 }
        return
            rates
            .filter { $0.currency == code }
            .min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
            .map(\.rate)
    }
}
