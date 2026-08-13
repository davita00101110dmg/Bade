import Core
import Foundation
import SwiftUI
import WidgetKit

#if DEBUG
    private let sample = WidgetSnapshot(
        monthTotal: 287, remaining: 124, currency: "GEL",
        upcoming: [
            .init(merchant: "Netflix", amount: 39, currency: "GEL", date: .now),
            .init(
                merchant: "Spotify", amount: Decimal(string: "24.90") ?? 0, currency: "GEL",
                date: .now.addingTimeInterval(86_400 * 3)),
            .init(
                merchant: "MAGTICOM", amount: 35, currency: "GEL",
                date: .now.addingTimeInterval(86_400 * 9)),
        ],
        isPro: true)

    private let allCharged = WidgetSnapshot(
        monthTotal: 287, remaining: 0, currency: "GEL", upcoming: [], isPro: true)

    #Preview("Small", as: .systemSmall) {
        BadeWidget()
    } timeline: {
        WidgetEntry(date: .now, snapshot: sample)
    }

    #Preview("Medium", as: .systemMedium) {
        BadeWidget()
    } timeline: {
        WidgetEntry(date: .now, snapshot: sample)
    }

    #Preview("All charged", as: .systemSmall) {
        BadeWidget()
    } timeline: {
        WidgetEntry(date: .now, snapshot: allCharged)
    }

    #Preview("Locked", as: .systemSmall) {
        BadeWidget()
    } timeline: {
        WidgetEntry(date: .now, snapshot: .empty)
    }
#endif
