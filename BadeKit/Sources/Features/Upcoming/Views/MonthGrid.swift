import DesignSystem
import Foundation
import SwiftUI

/// The month at a glance. A day that costs something is a filled tile, so a heavy week reads as a
/// block of them before any number is read; today is the one tile in the accent colour.
struct MonthGrid: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    /// A fixed square stops being tall enough for its own number at accessibility sizes, and the
    /// dot underneath then collides with the row below.
    @ScaledMetric private var cellHeight = UpcomingMetrics.cellHeight

    let cells: [UpcomingCell]
    let onSelect: (Date) -> Void

    private static let columns = Array(
        repeating: GridItem(.flexible(), spacing: BadeSpacing.xxs), count: 7)

    var body: some View {
        VStack(spacing: .xs) {
            LazyVGrid(columns: Self.columns, spacing: .zero) {
                // Indexed, not by value: in English two days are "T" and two are "S", and
                // identifying a column by its letter collapses them into one.
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(verbatim: weekdaySymbols[index])
                        .font(.badeLabel)
                        .foregroundStyle(theme.inkFaint)
                }
            }

            LazyVGrid(columns: Self.columns, spacing: .xxs) {
                ForEach(cells) { cell in
                    day(cell)
                }
            }
        }
    }

    @ViewBuilder
    private func day(_ cell: UpcomingCell) -> some View {
        if let date = cell.date {
            Button { onSelect(date) } label: { tile(cell, date: date) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
        } else {
            Color.clear.frame(height: cellHeight)
        }
    }

    private func tile(_ cell: UpcomingCell, date: Date) -> some View {
        VStack(spacing: .xxs) {
            Text(date, format: .dateTime.day().locale(locale))
                .font(.badeCaption)
                .fontWeight(cell.isToday ? .semibold : .regular)
                .foregroundStyle(ink(cell))
            dots(cell)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellHeight)
        .background(
            RoundedRectangle(cornerRadius: UpcomingMetrics.tileRadius, style: .continuous)
                .fill(fill(cell))
        )
        .overlay(
            RoundedRectangle(cornerRadius: UpcomingMetrics.tileRadius, style: .continuous)
                .strokeBorder(
                    cell.isSelected ? selection(cell) : .clear,
                    lineWidth: UpcomingMetrics.selectionWidth)
        )
        .contentShape(.rect)
    }

    /// Three dots and then a plus: past three the count stops meaning anything at this size.
    private func dots(_ cell: UpcomingCell) -> some View {
        HStack(spacing: .xxs) {
            ForEach(0..<min(cell.charges, UpcomingMetrics.visibleDots), id: \.self) { _ in
                Circle()
                    .fill(mark(cell))
                    .frame(width: UpcomingMetrics.dotSize, height: UpcomingMetrics.dotSize)
            }
            if cell.charges > UpcomingMetrics.visibleDots {
                Image(systemName: "plus")
                    .font(.badeLabel)
                    .foregroundStyle(mark(cell))
            }
        }
        .frame(height: UpcomingMetrics.dotSize)
    }

    private func fill(_ cell: UpcomingCell) -> Color {
        if cell.isToday { return theme.accent }
        return cell.charges > 0 ? theme.surfaceRaised : .clear
    }

    private func ink(_ cell: UpcomingCell) -> Color {
        if cell.isToday { return theme.surface }
        return theme.ink.opacity(cell.charges > 0 ? 1 : UpcomingMetrics.emptyDay)
    }

    private func mark(_ cell: UpcomingCell) -> Color {
        cell.isToday ? theme.surface : theme.accent
    }

    /// The accent already fills today, so its selection ring has to be drawn in something else.
    private func selection(_ cell: UpcomingCell) -> Color {
        cell.isToday ? theme.ink : theme.accent
    }

    /// Rotated to the locale's first weekday: a week starts on Monday in Georgia and on Sunday in
    /// the United States, and the columns have to agree with the grid underneath them.
    private var weekdaySymbols: [String] {
        var localised = calendar
        localised.locale = locale
        let symbols = localised.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}
