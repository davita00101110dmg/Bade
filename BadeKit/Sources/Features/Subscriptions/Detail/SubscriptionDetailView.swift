import Core
import DesignSystem
import Localization
import SwiftUI

public struct SubscriptionDetailView: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    @State private var model: SubscriptionDetailViewModel

    public init(model: SubscriptionDetailViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        content
            .modifier(DeleteConfirmation(model: model))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { model.send(.editTapped) } label: { Text(.subscriptions.edit) }
                }
            }
            .sheet(isPresented: editBinding) { SubscriptionFormView(model: model.form()) }
            // Static, because the heading below already names the subscription and two of the
            // same name in one glance read as a mistake.
            .navigationTitle(Text(.detail.title))
            .toolbarTitleDisplayMode(.inline)
            .onAppear { model.send(.appeared) }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .xxl) {
                header
                chart
                exchange
                facts
                actions
            }
            .padding(.horizontal, .screenMargin)
            .padding(.top, .md)
            .padding(.bottom, .xxxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
    }

    private var header: some View {
        HStack(spacing: .md) {
            MerchantMonogram(letter: monogram)

            VStack(alignment: .leading, spacing: .xxs) {
                Text(verbatim: model.state.subscription.merchant)
                    .font(.badeTitle)
                    .foregroundStyle(theme.ink)
                Text(subtitle)
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
            }

            Spacer(minLength: .xs)

            VStack(alignment: .trailing, spacing: .xxs) {
                Text(model.state.displayAmount, format: .badeMoney(model.state.displayCurrency))
                    .font(.badeTitle)
                    .foregroundStyle(theme.ink)
                if model.state.showsBilledPrice {
                    Text(
                        model.state.subscription.amount,
                        format: .badeMoney(model.state.subscription.currency)
                    )
                    .font(.badeCaption)
                    .foregroundStyle(theme.inkMuted)
                }
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        BadeCard {
            VStack(alignment: .leading, spacing: .md) {
                HStack(alignment: .firstTextBaseline) {
                    Text(.detail.history).badeSectionLabel()
                    Spacer()
                    if let change = model.state.latestPriceChange {
                        Text(.detail.priceChange(monthText(change.date)))
                            .font(.badeCaption)
                            .foregroundStyle(change.to > change.from ? theme.destructive : theme.accent)
                    }
                }

                if model.state.hasHistory {
                    ChargeHistoryChart(
                        bars: model.state.history, currency: model.state.displayCurrency)
                } else {
                    Text(.detail.noHistory)
                        .font(.badeBody)
                        .foregroundStyle(theme.inkMuted)
                }
            }
        }
    }

    /// Only for a subscription whose money crossed a currency; the rest never see it.
    @ViewBuilder
    private var exchange: some View {
        if model.state.showsExchange {
            ExchangeCard(
                markup: model.state.markup,
                isPaidWithoutConversion: model.state.isPaidWithoutConversion,
                currency: model.state.subscription.currency)
        }
    }

    /// A list rather than three columns: the values are unrelated to each other and vary wildly
    /// in width, so a column layout either wraps or leaves one of them stranded.
    private var facts: some View {
        VStack(spacing: .zero) {
            fact(.detail.nextCharge, dateText(model.state.nextCharge))
            Divider().overlay(theme.border)
            fact(
                .detail.aYear,
                model.state.annualTotal.formatted(
                    .badeMoneyWhole(model.state.displayCurrency).locale(locale)))
            Divider().overlay(theme.border)
            fact(.detail.firstCharge, monthText(model.state.subscription.firstChargeDate))
        }
        .background(
            RoundedRectangle(cornerRadius: BadeRadius.xl, style: .continuous)
                .fill(theme.surfaceRaised)
        )
    }

    private func fact(_ label: LocalizedStringResource, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.badeBody)
                .foregroundStyle(theme.inkMuted)
            Spacer(minLength: .sm)
            Text(verbatim: value)
                .font(.badeAmount)
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, .lg)
        .padding(.vertical, .sm)
        .frame(minHeight: BadeLayout.minimumTapTarget)
        .accessibilityElement(children: .combine)
    }

    /// Cancelling is reversible and quiet; deleting is neither, so only one of them shouts.
    private var actions: some View {
        VStack(spacing: .xs) {
            action(
                model.state.subscription.isActive ? .subscriptions.markCancelled : .subscriptions.markActive,
                tint: theme.accent
            ) { model.send(.activeToggled) }

            action(.detail.delete, tint: theme.destructive) { model.send(.deleteRequested) }
        }
    }

    private func action(
        _ title: LocalizedStringResource, tint: Color, perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Text(title)
                .font(.badeHeadline)
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BadeButtonMetrics.secondaryVerticalPadding)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    /// Swiping the sheet away is the same as tapping Cancel in it.
    private var editBinding: Binding<Bool> {
        Binding(
            get: { model.state.isEditing },
            set: { if !$0 { model.send(.formFinished(.cancelled)) } })
    }

    private var monogram: String {
        model.state.subscription.merchant.first.map { String($0).uppercased() } ?? "?"
    }

    private var subtitle: LocalizedStringResource {
        .detail.billedIn(
            .badeLocalized(model.state.subscription.cadence.localizedName, in: locale),
            model.state.subscription.currency)
    }

    private func dateText(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).locale(locale))
    }

    private func monthText(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year().locale(locale))
    }
}

/// Deleting cannot be undone in the moment, and unlike a swipe there is no gesture here that
/// already counts as deliberate.
private struct DeleteConfirmation: ViewModifier {
    let model: SubscriptionDetailViewModel

    func body(content: Content) -> some View {
        content.alert(Text(.detail.deleteTitle), isPresented: isConfirming) {
            Button(role: .destructive) { model.send(.deleteConfirmed) } label: {
                Text(.detail.delete)
            }
            Button(role: .cancel) { model.send(.confirmationDismissed) } label: {
                Text(.detail.cancel)
            }
        } message: {
            Text(.detail.deleteMessage)
        }
    }

    private var isConfirming: Binding<Bool> {
        Binding(
            get: { model.state.isConfirmingDelete },
            set: { if !$0 { model.send(.confirmationDismissed) } })
    }
}
