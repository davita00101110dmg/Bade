import Core
import DesignSystem
import Localization
import SwiftUI

/// Generic over what a row opens: Detail lives in another feature module, so the composition root
/// supplies it. Upcoming knows only that a charge leads somewhere.
public struct UpcomingView<Destination: View>: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .largeTitle) private var monthTotalSize = BadeTypography.displaySize

    @State private var model: UpcomingViewModel
    private let destination: (Subscription) -> Destination

    public init(
        model: UpcomingViewModel,
        @ViewBuilder destination: @escaping (Subscription) -> Destination
    ) {
        _model = State(initialValue: model)
        self.destination = destination
    }

    public var body: some View {
        list
            .navigationTitle(Text(.upcoming.title))
            // Inline: a large title spends most of the screen's top on a word the tab bar already
            // says, and the calendar is what the screen is for.
            .toolbarTitleDisplayMode(.inline)
            // Reloaded on every appearance, not once: an edit made in another tab has to show.
            .onAppear { model.send(.appeared) }
    }

    /// Split from `body` deliberately: the whole screen in one chain takes the type checker past
    /// its limit on iOS, and it reports the failure as a missing modifier rather than a timeout.
    private var list: some View {
        List {
            calendarSection
            selectionSection
            daySections
            emptySection
            failureSection
        }
        .badeGroupedList()
        .contentMargins(.top, .zero, for: .scrollContent)
        .contentMargins(.bottom, .xxl, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeAnimation(.badeContent, value: model.state.month)
        .badeAnimation(.badeContent, value: model.state.selectedDay)
        .badeFeedback(.selection, trigger: model.state.month)
        .badeFeedback(.selection, trigger: model.state.selectedDay)
    }

    private var calendarSection: some View {
        Section {
            VStack(spacing: .md) {
                monthHeader
                MonthGrid(cells: model.state.cells) { model.send(.daySelected($0)) }
                if !model.state.isEmpty { total }
            }
            .padding(.vertical, .md)
            .contentShape(.rect)
            .gesture(pageGesture)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { model.send(.previousMonth) } label: { chevron("chevron.left") }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.upcoming.previous))

            Spacer()

            // Never disabled on the current month: a disabled plain button dims its own label, so
            // the month you are on read greyer than the ones you are not. Returning to a month you
            // are already in changes nothing, which is the whole cost of leaving it tappable.
            Button { model.send(.thisMonth) } label: {
                Text(monthName)
                    .font(.badeTitle)
                    .foregroundStyle(theme.ink)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(.upcoming.thisMonth))

            Spacer()

            Button { model.send(.nextMonth) } label: { chevron("chevron.right") }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.upcoming.next))
        }
        .font(.badeHeadline)
        .foregroundStyle(theme.accent)
    }

    /// A chevron is a small glyph; the tap target around it is not.
    private func chevron(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .frame(width: BadeLayout.minimumTapTarget, height: BadeLayout.minimumTapTarget)
            .contentShape(.rect)
    }

    /// Swiping the calendar turns the month, which is what a month grid invites you to try.
    private var pageGesture: some Gesture {
        DragGesture(minimumDistance: UpcomingMetrics.pageThreshold)
            .onEnded { drag in
                guard abs(drag.translation.width) > abs(drag.translation.height) else { return }
                model.send(drag.translation.width < 0 ? .nextMonth : .previousMonth)
            }
    }

    private var total: some View {
        VStack(spacing: .xxs) {
            Text(.upcoming.total).badeSectionLabel()
            BadeMoneyText(
                model.state.monthTotal, currency: model.state.currency, size: monthTotalSize
            )
            .foregroundStyle(theme.ink)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            if model.state.unconvertibleCount > 0 {
                Text(.subscriptions.unconvertible(model.state.unconvertibleCount))
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var daySections: some View {
        ForEach(model.state.listedDays) { day in
            Section {
                ForEach(day.charges) { charge in
                    NavigationLink {
                        destination(charge.subscription)
                    } label: {
                        UpcomingChargeRow(
                            merchant: charge.subscription.merchant,
                            amount: model.state.amount(of: charge),
                            currency: model.state.currencyCode(of: charge),
                            isCancelled: !charge.subscription.isActive)
                    }
                    .badeListRow()
                    .listRowBackground(theme.surfaceRaised)
                }
            } header: {
                dayHeader(day)
            }
        }
    }

    private func dayHeader(_ day: UpcomingDay) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: dayName(day.date)).badeSectionLabel(tint: day.isToday ? theme.accent : nil)
            Spacer()
            Text(day.total, format: .badeMoney(model.state.currency))
                .font(.badeCaption)
                .foregroundStyle(theme.inkMuted)
        }
    }

    /// A selected day narrows the list, so the way back to the whole month has to be on screen.
    @ViewBuilder
    private var selectionSection: some View {
        if model.state.selectedDay != nil {
            Section {
                Button { model.send(.selectionCleared) } label: {
                    Text(.upcoming.showMonth)
                        .font(.badeBody)
                        .foregroundStyle(theme.accent)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .listRowBackground(theme.surfaceRaised)
            } footer: {
                if model.state.isSelectionEmpty {
                    Text(.upcoming.nothingThatDay)
                        .font(.badeCaption)
                        .foregroundStyle(theme.inkMuted)
                }
            }
        }
    }

    /// A month with nothing in it still says so; the grid alone would look like a loading state.
    @ViewBuilder
    private var emptySection: some View {
        if model.state.phase == .ready && model.state.isEmpty && model.state.selectedDay == nil {
            Section {
                BadeEmptyNet {
                    Text(
                        model.state.subscriptions.isEmpty
                            ? .upcoming.nothingEver : .upcoming.nothing
                    )
                    .font(.badeTitle)
                    .foregroundStyle(theme.inkMuted)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    @ViewBuilder
    private var failureSection: some View {
        if model.state.phase == .failed {
            Section {
                Text(.upcoming.loadFailed)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
                    .listRowBackground(Color.clear)
            }
        }
    }

    private var monthName: String {
        model.state.month.formatted(.dateTime.month(.wide).year().locale(locale))
    }

    private func dayName(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.wide).locale(locale))
    }
}
