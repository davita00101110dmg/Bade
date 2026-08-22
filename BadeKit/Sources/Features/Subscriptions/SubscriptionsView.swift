import Core
import DesignSystem
import Localization
import SwiftUI

public struct SubscriptionsView: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: SubscriptionsViewModel
    /// Held rather than made per render: invalidating one instance has to be the same tip the
    /// header is showing.
    private let swipeTip = SwipeARowTip()
    /// Survives the hero row being recycled by scrolling, so §14.7's arrival happens once.
    @State private var hasArrived = false
    @State private var rapidTaps = 0
    @State private var lastTap = Date.distantPast
    @State private var isRaining = false
    /// Whether the hero is still on screen. The number the app exists to show should not leave it.
    @State private var isShowingHero = true
    /// How far the list has been dragged past its own top. Nothing refreshes; the net stretches.
    @State private var pull: CGFloat = 0
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
                // Only once the hero has gone: two copies of the same figure on one screen is one
                // too many, and the point is that it never leaves rather than that it is repeated.
                ToolbarItem(placement: .principal) {
                    // Always present, faded rather than added and removed: a toolbar does not
                    // reliably rebuild itself when its content appears out of a condition.
                    Text(model.state.monthlyTotal, format: .badeMoney(model.state.currency))
                        .font(.badeHeadline)
                        .foregroundStyle(theme.accent)
                        .opacity(isShowingHero ? 0 : 1)
                        .accessibilityHidden(isShowingHero)
                }
                ToolbarItem(placement: .primaryAction) { sortMenu }
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
            // The screen has no title of its own, but putting the total in the bar gives it title
            // content — and without this the bar lays itself out for a large one, which is the gap
            // that appeared above the hero.
            .toolbarTitleDisplayMode(.inline)
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
        .badeTipStyle()
        // A grouped list reserves space above its first section for a header it does not have.
        // Zeroed here so the gap above the total is only the padding the header itself asks for.
        .contentMargins(.top, .zero, for: .scrollContent)
        .contentMargins(.bottom, .xxl, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeAnimation(.badeContent, value: model.state.rows)
        .badeFeedback(.selection, trigger: model.state.sort)
        // Read off the scroll itself rather than from the hero's own visibility: inside a `List`
        // that never reported, and an offset is a number this can reason about anyway.
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            // Dragged past the top, the offset goes negative; that distance is the pull.
            pull = max(0, -offset)

            let isShowing = offset < SubscriptionsMetrics.heroLeavesAt
            guard isShowing != isShowingHero else { return }
            withBadeAnimation(.badeContent, reduceMotion: reduceMotion) { isShowingHero = isShowing }
        }
        .overlay(alignment: .top) { BadePullNet(pull: pull) }
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

    /// Gone entirely when nothing is live, heading included: a heading over no rows is worse than
    /// no section. The sort control is in the toolbar now and stays there, which is fine — sorting
    /// an empty list changes nothing rather than being impossible.
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
                    .swipeActions(edge: .trailing) { swipeDeleteAction(row.subscription) }
                    .contextMenu {
                        editAction(row.subscription)
                        activeAction(row.subscription)
                        deleteAction(row.subscription)
                    }
                    // On the row itself, so the arrow points at the thing to swipe. The first one,
                    // because the tip is about all of them and the first is the one already read.
                    //
                    // Held back until the total has landed. The hero counts up for
                    // `BadeMotion.totalReveal` and writes `hasArrived` back to this screen when it
                    // finishes, which re-renders the list and dismisses any popover anchored inside
                    // it — so the tip appeared on arrival and vanished a second later, but only on
                    // the first visit, because `.task(id: total)` never runs again. Waiting also
                    // keeps it off §14.7's arrival moment, which is the one thing on this screen
                    // worth not interrupting.
                    .popoverTip(hasArrived && row.id == model.state.rows.first?.id ? swipeTip : nil)
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
                    .swipeActions(edge: .trailing) { swipeDeleteAction(row.subscription) }
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
        Button { performed(.activeToggled(subscription)) } label: {
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
        Button { performed(.editTapped(subscription)) } label: {
            Label { Text(.subscriptions.edit) } icon: { Image(systemName: "pencil") }
        }
        .tint(theme.inkMuted)
    }

    /// Offered on both a swipe and a long press, because neither is discoverable on its own.
    /// Red from the palette rather than from `role: .destructive`, and deliberately.
    ///
    /// A destructive role inside `swipeActions` makes SwiftUI perform its own removal: the row
    /// collapses the instant the button is tapped, before anything has been asked. With a
    /// confirmation in front of it the row then sprang back when the alert appeared, so a delete
    /// looked like it had happened and been undone. Tinting instead leaves the list alone until the
    /// answer comes back.
    private func swipeDeleteAction(_ subscription: Subscription) -> some View {
        Button { performed(.deleteTapped(subscription)) } label: {
            Label { Text(.subscriptions.delete) } icon: { Image(systemName: "trash") }
        }
        .tint(theme.destructive)
    }

    /// A context menu has no row animation to trigger, so the role is safe there and gives the
    /// system's own destructive styling.
    private func deleteAction(_ subscription: Subscription) -> some View {
        Button(role: .destructive) { performed(.deleteTapped(subscription)) } label: {
            Label { Text(.subscriptions.delete) } icon: { Image(systemName: "trash") }
        }
    }

    /// The three actions a row hides. Reaching any of them — by swipe or by long press — is proof
    /// the gesture has been found, so the tip that says so has done its job and goes.
    private func performed(_ intent: SubscriptionsIntent) {
        swipeTip.invalidate(reason: .actionPerformed)
        model.send(intent)
    }

    private var sectionHeader: some View {
        Text(.subscriptions.all).badeSectionLabel()
    }

    /// In the toolbar rather than in the section header, where it used to live and clip for a beat
    /// whenever the sort changed. The cause was the `List` remeasuring its own header during the
    /// same animated batch update that reorders the rows — so nothing inside the list could be
    /// safe, and `fixedSize`, a nil transaction and an identity content transition all failed
    /// because none of them reach it. Out here the list cannot touch it.
    ///
    /// The current order is no longer legible at a glance; the tick inside the menu says it
    /// instead. That is the trade, and it is where iOS keeps sort anyway.
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
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel(Text(.subscriptions.sortLabel))
        .accessibilityValue(Text(model.state.sort.title))
    }

    private var sortBinding: Binding<SubscriptionSort> {
        // The animation goes on the change, not on the List. Keying `.animation` to the rows array
        // asks SwiftUI to animate a structural change from outside the list, which fights the
        // list's own update: it took sometimes, and when it did not, a row was left clipped until
        // the next relayout repaired it. Wrapping the mutation lets the list perform the move.
        Binding(
            get: { model.state.sort },
            set: { sort in
                withBadeAnimation(.badeReorder, reduceMotion: reduceMotion) {
                    model.send(.sortChanged(sort))
                }
            })
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
            // Named rather than generic: the alert has to say which subscription, because a swipe
            // lands on whichever row the thumb was over.
            .alert(
                Text(.detail.deleteTitle), isPresented: isConfirmingDelete,
                presenting: model.state.pendingDelete
            ) { subscription in
                Button(role: .destructive) { model.send(.deleteConfirmed) } label: {
                    Text(.subscriptions.delete)
                }
                Button(role: .cancel) { model.send(.confirmationDismissed) } label: {
                    Text(.subscriptions.cancel)
                }
            } message: { subscription in
                Text(.detail.deleteMessage)
            }
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

    private var isConfirmingDelete: Binding<Bool> {
        let pending = model.state.pendingDelete != nil
        return Binding(
            get: { pending },
            set: { if !$0 { model.send(.confirmationDismissed) } })
    }

    private var isConfirmingDeleteAll: Binding<Bool> {
        Binding(
            get: { model.state.isConfirmingDeleteAll },
            set: { if !$0 { model.send(.confirmationDismissed) } })
    }
}
