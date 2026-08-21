import Core
import DesignSystem
import Localization
import SwiftUI

public struct SubscriptionsView: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: SubscriptionsViewModel
    /// Survives the hero row being recycled by scrolling, so §14.7's arrival happens once.
    @State private var hasArrived = false
    @State private var rapidTaps = 0
    @State private var lastTap = Date.distantPast
    @State private var isRaining = false
    /// Watched rather than owned: Settings can change it while this screen is on screen.
    private let currency: String
    /// Only forwarded: this screen locks nothing itself, but the detail behind a row does.
    private let isPro: Bool
    private let onUnlock: () -> Void

    public init(
        model: SubscriptionsViewModel, currency: String, isPro: Bool,
        onUnlock: @escaping () -> Void
    ) {
        _model = State(initialValue: model)
        self.currency = currency
        self.isPro = isPro
        self.onUnlock = onUnlock
    }

    public var body: some View {
        list
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { model.send(.importTapped) } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel(Text(.subscriptions.importStatement))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { model.send(.addTapped) } label: { Image(systemName: "plus") }
                        .accessibilityLabel(Text(.subscriptions.add))
                }
            }
            .sheet(item: editBinding) { edit in
                SubscriptionFormView(model: model.form(for: edit))
            }
            .modifier(DeletionConfirmations(model: model))
            .overlay {
                if isRaining {
                    BadeMoneyRain(symbol: .badeCurrencySymbol(model.state.currency, in: locale))
                        .transition(.opacity)
                }
            }
            // Clears itself once every note has finished its fall, through the transition rather
            // than by cutting: without an animation around it the whole rain blinked out at once.
            .task(id: isRaining) {
                guard isRaining else { return }
                try? await Task.sleep(for: BadeMoneyRainMetrics.lifetime)
                withBadeAnimation(.badeNet, reduceMotion: reduceMotion) { isRaining = false }
            }
            // Reloaded on every appearance, not once: an edit made in another tab has to show.
            .onAppear { model.send(.appeared) }
            .task(id: currency) { model.send(.currencyChanged(currency)) }
    }

    /// Five quick taps on the total and it rains. Kept in the view rather than the reducer:
    /// it changes nothing about the subscriptions, so that state is nobody else's business.
    private func countTap() {
        let now = Date.now
        rapidTaps =
            now.timeIntervalSince(lastTap) < SubscriptionsMetrics.rainTapWindow ? rapidTaps + 1 : 1
        lastTap = now
        guard rapidTaps >= SubscriptionsMetrics.tapsForRain else { return }
        rapidTaps = 0
        withBadeAnimation(.badeNet, reduceMotion: reduceMotion) { isRaining = true }
    }

    /// Split from `body` deliberately: the whole screen in one chain takes the type checker past
    /// its limit on iOS, and it reports the failure as a missing modifier rather than a timeout.
    private var list: some View {
        List {
            heroSection
            subscriptionsSection
            cancelledSection
            failureSection
            clearEverythingSection
        }
        .badeGroupedList()
        // A grouped list reserves space above its first section for a header it does not have.
        // Zeroed here so the gap above the total is only the padding the header itself asks for.
        .contentMargins(.top, .zero, for: .scrollContent)
        .contentMargins(.bottom, .xxl, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeAnimation(.badeContent, value: model.state.rows)
        .badeFeedback(.selection, trigger: model.state.sort)
    }

    private var heroSection: some View {
        Section {
            MonthlyTotalHeader(
                total: model.state.monthlyTotal,
                annual: model.state.annualTotal,
                currency: model.state.currency,
                count: model.state.count,
                unconvertibleCount: model.state.unconvertibleCount,
                hasArrived: $hasArrived,
                onTotalTapped: countTap
            )
            .padding(.bottom, .lg)
            // Zeroed so the only space above the total is the one chosen here, not the list's.
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    /// Gone entirely when nothing is live, header and sort control included: a section offering
    /// to sort nothing is worse than no section.
    @ViewBuilder
    private var subscriptionsSection: some View {
        if !model.state.rows.isEmpty {
            Section {
                ForEach(model.state.rows) { row in
                    NavigationLink {
                        SubscriptionDetailView(
                            model: model.detail(for: row.subscription), isPro: isPro,
                            onUnlock: onUnlock)
                    } label: {
                        SubscriptionListRow(row: row, currency: model.state.currency)
                    }
                    .badeListRow()
                    .listRowBackground(theme.surfaceRaised)
                    .swipeActions(edge: .leading) {
                        activeAction(row.subscription)
                        editAction(row.subscription)
                    }
                    .swipeActions(edge: .trailing) { deleteAction(row.subscription) }
                    .contextMenu {
                        editAction(row.subscription)
                        activeAction(row.subscription)
                        deleteAction(row.subscription)
                    }
                }
            } header: {
                sectionHeader
            }
        }
    }

    /// Dimmed and set apart rather than hidden: cancelling is a state, not a disappearance.
    @ViewBuilder
    private var cancelledSection: some View {
        if !model.state.cancelledRows.isEmpty {
            Section {
                ForEach(model.state.cancelledRows) { row in
                    NavigationLink {
                        SubscriptionDetailView(
                            model: model.detail(for: row.subscription), isPro: isPro,
                            onUnlock: onUnlock)
                    } label: {
                        SubscriptionListRow(row: row, currency: model.state.currency)
                            .opacity(BadeListRowMetrics.cancelledOpacity)
                    }
                    .badeListRow()
                    .listRowBackground(theme.surfaceRaised)
                    .swipeActions(edge: .leading) {
                        activeAction(row.subscription)
                        editAction(row.subscription)
                    }
                    .swipeActions(edge: .trailing) { deleteAction(row.subscription) }
                    .contextMenu {
                        editAction(row.subscription)
                        activeAction(row.subscription)
                        deleteAction(row.subscription)
                    }
                }
            } header: {
                Text(.subscriptions.noLongerCharged).badeSectionLabel()
            }
        }
    }

    @ViewBuilder
    private var failureSection: some View {
        if model.state.phase == .failed {
            Section {
                Text(.subscriptions.loadFailed)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
                    .listRowBackground(Color.clear)
            }
        }
    }

    private var clearEverythingSection: some View {
        Section {
            Button(role: .destructive) { model.send(.deleteAllRequested) } label: {
                Text(.subscriptions.deleteAll)
                    .font(.badeBody)
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(theme.surfaceRaised)
        }
    }

    /// Leading edge, away from delete: cancelling is reversible and must not sit under the same
    /// thumb as the action that is not.
    private func activeAction(_ subscription: Subscription) -> some View {
        Button { model.send(.activeToggled(subscription)) } label: {
            Label {
                Text(subscription.isActive ? .subscriptions.markCancelled : .subscriptions.markActive)
            } icon: {
                Image(systemName: subscription.isActive ? "pause.circle" : "arrow.clockwise.circle")
            }
        }
        .tint(theme.accent)
    }

    /// Behind cancel on the swipe, so a full swipe still means what it meant before Edit existed.
    private func editAction(_ subscription: Subscription) -> some View {
        Button { model.send(.editTapped(subscription)) } label: {
            Label { Text(.subscriptions.edit) } icon: { Image(systemName: "pencil") }
        }
        .tint(theme.inkMuted)
    }

    /// Offered on both a swipe and a long press, because neither is discoverable on its own.
    private func deleteAction(_ subscription: Subscription) -> some View {
        Button(role: .destructive) { model.send(.deleteTapped(subscription)) } label: {
            Label { Text(.subscriptions.delete) } icon: { Image(systemName: "trash") }
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(.subscriptions.all).badeSectionLabel()
            Spacer()
            sortMenu
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker(selection: sortBinding) {
                ForEach(SubscriptionSort.allCases) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(.subscriptions.sortLabel)
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: .xxs) {
                Text(model.state.sort.title)
                Image(systemName: "chevron.down")
            }
            .font(.badeCaption)
            .foregroundStyle(theme.accent)
            .textCase(nil)
            .contentShape(.rect)
        }
        .accessibilityLabel(Text(.subscriptions.sortLabel))
    }

    private var sortBinding: Binding<SubscriptionSort> {
        Binding(get: { model.state.sort }, set: { model.send(.sortChanged($0)) })
    }

    /// Swiping the sheet away is the same as tapping Cancel in it.
    private var editBinding: Binding<SubscriptionEdit?> {
        Binding(
            get: { model.state.edit },
            set: { if $0 == nil { model.send(.formFinished(.cancelled)) } })
    }
}

/// Clearing everything is the one action worth interrupting for: a deleted row comes back by
/// re-importing, an emptied store does not.
///
/// An alert rather than a confirmation dialog, because a dialog anchors itself to whatever
/// triggered it and lands somewhere unrelated when that was a swipe or a context menu.
private struct DeletionConfirmations: ViewModifier {
    let model: SubscriptionsViewModel

    func body(content: Content) -> some View {
        content
            .alert(Text(.subscriptions.deleteAllTitle), isPresented: isConfirmingDeleteAll) {
                Button(role: .destructive) { model.send(.deleteAllConfirmed) } label: {
                    Text(.subscriptions.deleteAll)
                }
                Button(role: .cancel) { model.send(.confirmationDismissed) } label: {
                    Text(.subscriptions.cancel)
                }
            } message: {
                Text(.subscriptions.deleteAllMessage)
            }
    }

    private var isConfirmingDeleteAll: Binding<Bool> {
        Binding(
            get: { model.state.isConfirmingDeleteAll },
            set: { if !$0 { model.send(.confirmationDismissed) } })
    }
}
