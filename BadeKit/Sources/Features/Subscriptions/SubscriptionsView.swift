import Core
import DesignSystem
import Localization
import SwiftUI

public struct SubscriptionsView: View {
    @Environment(\.badeTheme) private var theme

    @State private var model: SubscriptionsViewModel

    public init(model: SubscriptionsViewModel) {
        _model = State(initialValue: model)
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
            }
            .modifier(DeletionConfirmations(model: model))
            .task { model.send(.appeared) }
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
                unconvertibleCount: model.state.unconvertibleCount
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
                        SubscriptionDetailView(model: model.detail(for: row.subscription))
                    } label: {
                        SubscriptionListRow(row: row, currency: model.state.currency)
                    }
                    .listRowBackground(theme.surfaceRaised)
                    .swipeActions(edge: .leading) { activeAction(row.subscription) }
                    .swipeActions(edge: .trailing) { deleteAction(row.subscription) }
                    .contextMenu {
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
                        SubscriptionDetailView(model: model.detail(for: row.subscription))
                    } label: {
                        SubscriptionListRow(row: row, currency: model.state.currency)
                            .opacity(SubscriptionsMetrics.cancelledRow)
                    }
                    .listRowBackground(theme.surfaceRaised)
                    .swipeActions(edge: .leading) { activeAction(row.subscription) }
                    .swipeActions(edge: .trailing) { deleteAction(row.subscription) }
                    .contextMenu {
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
