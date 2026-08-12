import Core
import Foundation

public struct SubscriptionDetailState: Equatable {
    public private(set) var subscription: Subscription
    public let currency: String
    public let rates: RateBook
    public private(set) var isConfirmingDelete = false
    public private(set) var isEditing = false
    /// Only ever fetched when the statement printed no rate to compare against.
    public private(set) var officialRates: [OfficialRate] = []

    public init(subscription: Subscription, currency: String, rates: RateBook) {
        self.subscription = subscription
        self.currency = currency
        self.rates = rates
    }

    /// The charge in the display currency, or `nil` when no rate covers it — the same honesty the
    /// list applies, so a row and its detail never disagree.
    public var converted: Decimal? {
        rates.convert(
            subscription.amount, from: subscription.currency, to: currency,
            on: subscription.lastChargeDate)
    }

    public var displayAmount: Decimal { converted ?? subscription.amount }
    public var displayCurrency: String { converted == nil ? subscription.currency : currency }
    public var showsBilledPrice: Bool { subscription.currency != currency && converted != nil }

    public var annualTotal: Decimal {
        rates.convert(
            subscription.monthlyAmount * 12, from: subscription.currency, to: currency,
            on: subscription.lastChargeDate) ?? subscription.monthlyAmount * 12
    }

    /// Twelve months ending on the last charge, so a subscription that stopped still shows the
    /// history it had rather than a year of blanks.
    public var history: [ChargeBar] {
        let months = Self.calendar.months(endingAt: subscription.lastChargeDate, count: 12)
        let totals = months.map { month in totalCharged(in: month) }
        let tallest = totals.max() ?? 0
        var changes: [Date: PriceChange] = [:]
        for change in subscription.priceChanges {
            changes[Self.calendar.startOfMonth(for: change.date)] = change
        }

        return zip(months, totals).map { month, total in
            ChargeBar(
                month: month, amount: total,
                fraction: tallest > 0 ? Self.ratio(of: total, to: tallest) : 0,
                priceChange: changes[month])
        }
    }

    public var hasHistory: Bool { !subscription.charges.isEmpty }

    /// What the bank's rate cost on the most recent converted charge, if anything converted and
    /// there is a rate to judge it by.
    public var markup: FXMarkup? { subscription.markup(against: officialRates) }

    /// A foreign charge that never touched a rate, which is worth saying rather than hiding.
    public var isPaidWithoutConversion: Bool { subscription.isPaidWithoutConversion }

    /// The section has something to say whenever money crossed a currency at all.
    public var showsExchange: Bool {
        markup != nil || isPaidWithoutConversion || subscription.lastConvertedCharge != nil
    }

    /// The statement printed a rate of its own, so nothing needs fetching.
    var needsOfficialRates: Bool {
        guard let conversion = subscription.lastConvertedCharge?.conversion else { return false }
        return conversion.schemeRate == nil && markup == nil
    }

    public var latestPriceChange: PriceChange? {
        subscription.priceChanges.max { $0.date < $1.date }
    }

    private func totalCharged(in month: Date) -> Decimal {
        subscription.charges
            .filter { Self.calendar.startOfMonth(for: $0.date) == month }
            .reduce(Decimal(0)) { running, charge in
                let value =
                    rates.convert(charge.amount, from: charge.currency, to: displayCurrency,
                        on: charge.date) ?? charge.amount
                return running + value
            }
    }

    /// Bar heights are a proportion, not an amount; the money either side stays `Decimal`.
    private static func ratio(of value: Decimal, to tallest: Decimal) -> Double {
        Double(truncating: (value / tallest) as NSDecimalNumber)
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}

extension Calendar {
    fileprivate func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }

    fileprivate func months(endingAt date: Date, count: Int) -> [Date] {
        let last = startOfMonth(for: date)
        return (0..<count).reversed().compactMap {
            self.date(byAdding: .month, value: -$0, to: last)
        }
    }
}

public enum SubscriptionDetailIntent: Equatable {
    case appeared
    case officialRatesLoaded([OfficialRate])
    case activeToggled
    case editTapped
    case formFinished(FormOutcome)
    case deleteRequested
    case deleteConfirmed
    case confirmationDismissed
    case saved(Subscription)
    case deletionFinished
}

public enum SubscriptionDetailEffect: Equatable {
    case loadOfficialRates(currency: String, date: Date)
    case save(Subscription)
    case delete(UUID)
    case exit(DetailOutcome)
}

extension SubscriptionDetailState {
    public mutating func apply(_ intent: SubscriptionDetailIntent) -> SubscriptionDetailEffect? {
        switch intent {
        // Nothing is fetched for a charge whose statement already carried a rate.
        case .appeared:
            guard needsOfficialRates,
                let charge = subscription.lastConvertedCharge,
                let conversion = charge.conversion
            else { return nil }
            return .loadOfficialRates(currency: conversion.from, date: charge.date)

        case .officialRatesLoaded(let rates):
            officialRates = rates
            return nil

        case .activeToggled:
            var updated = subscription
            updated.isActive.toggle()
            return .save(updated)

        case .saved(let updated):
            subscription = updated
            return .exit(.changed)

        case .editTapped:
            isEditing = true
            return nil

        // The form wrote it already; this screen only has to show what it wrote.
        case .formFinished(let outcome):
            isEditing = false
            guard case .saved(let updated) = outcome else { return nil }
            subscription = updated
            return .exit(.changed)

        case .deleteRequested:
            isConfirmingDelete = true
            return nil

        case .confirmationDismissed:
            isConfirmingDelete = false
            return nil

        case .deleteConfirmed:
            isConfirmingDelete = false
            return .delete(subscription.id)

        case .deletionFinished:
            return .exit(.deleted)
        }
    }
}
