import Core
import DesignSystem
import Localization
import SwiftUI

public struct SubscriptionFormView: View {
    @Environment(\.badeTheme) private var theme

    @State private var model: SubscriptionFormViewModel

    public init(model: SubscriptionFormViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        NavigationStack {
            fields
                .navigationTitle(Text(model.state.isNew ? .form.newTitle : .form.editTitle))
                .toolbarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .modifier(DiscardConfirmation(model: model))
        }
        // Swiping a half-filled form away is an accident far more often than a decision.
        .interactiveDismissDisabled(model.state.hasChanges)
    }

    /// Split from `body` deliberately: the whole screen in one chain takes the type checker past
    /// its limit on iOS, and it reports the failure as a missing modifier rather than a timeout.
    private var fields: some View {
        List {
            serviceSection
            priceSection
            billingSection
        }
        .badeGroupedList()
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeAnimation(.badeContent, value: model.state.suggestions)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { model.send(.cancelTapped) } label: { Text(.form.cancel) }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button { model.send(.saveTapped) } label: { Text(.form.save) }
                .disabled(!model.state.canSave)
        }
    }

    private var serviceSection: some View {
        Section {
            TextField(
                text: field(\.merchant, SubscriptionFormIntent.merchantChanged),
                prompt: Text(.form.servicePrompt)
            ) {
                Text(.form.service)
            }
            .font(.badeBody)
            .foregroundStyle(theme.ink)
            .badeNameEntry()
            .listRowBackground(theme.surfaceRaised)

            if !model.state.suggestions.isEmpty {
                MerchantSuggestionRow(names: model.state.suggestions) {
                    model.send(.suggestionTapped($0))
                }
                .listRowBackground(theme.surfaceRaised)
            }
        } header: {
            Text(.form.service).badeSectionLabel()
        }
    }

    private var priceSection: some View {
        Section {
            // Its own row rather than a labelled one: the label would repeat the placeholder.
            TextField(text: field(\.amount, SubscriptionFormIntent.amountChanged)) {
                Text(.form.amount)
            }
            .font(.badeAmount)
            .foregroundStyle(theme.ink)
            .badeDecimalEntry()
            .listRowBackground(theme.surfaceRaised)

            NavigationLink {
                CurrencyPicker(
                    known: model.state.knownCurrencies, selected: model.state.draft.currency
                ) { model.send(.currencyChanged($0)) }
            } label: {
                LabeledContent {
                    Text(verbatim: model.state.draft.currency)
                        .font(.badeAmount)
                        .foregroundStyle(theme.ink)
                } label: {
                    label(.currency.title)
                }
            }
            .listRowBackground(theme.surfaceRaised)
        } header: {
            Text(.form.price).badeSectionLabel()
        }
    }

    private var billingSection: some View {
        Section {
            Picker(selection: field(\.cadence, SubscriptionFormIntent.cadenceChanged)) {
                ForEach(Cadence.allCases, id: \.self) { cadence in
                    Text(cadence.localizedName).tag(cadence)
                }
            } label: {
                label(.form.cadence)
            }
            .listRowBackground(theme.surfaceRaised)

            DatePicker(
                selection: field(\.nextChargeDate, SubscriptionFormIntent.nextChargeDateChanged),
                displayedComponents: .date
            ) {
                label(.detail.nextCharge)
            }
            .listRowBackground(theme.surfaceRaised)

            Toggle(isOn: field(\.isActive, SubscriptionFormIntent.activeChanged)) {
                label(.form.active)
            }
            .tint(theme.accent)
            .listRowBackground(theme.surfaceRaised)
        } header: {
            Text(.form.billing).badeSectionLabel()
        } footer: {
            Text(.form.activeFooter)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)
        }
    }

    private func label(_ title: LocalizedStringResource) -> some View {
        Text(title).font(.badeBody).foregroundStyle(theme.inkMuted)
    }

    /// Every field reads the draft and writes an intent; the state stays the only place a value
    /// changes, and no control owns a copy of it.
    private func field<Value>(
        _ value: KeyPath<SubscriptionDraft, Value>,
        _ intent: @escaping (Value) -> SubscriptionFormIntent
    ) -> Binding<Value> {
        Binding(
            get: { model.state.draft[keyPath: value] },
            set: { model.send(intent($0)) })
    }
}

/// Only asked when there is something to lose. An alert rather than a confirmation dialog: a
/// dialog anchors itself to whatever triggered it, and a toolbar button is not where the question
/// belongs.
private struct DiscardConfirmation: ViewModifier {
    let model: SubscriptionFormViewModel

    func body(content: Content) -> some View {
        content.alert(Text(.form.discardTitle), isPresented: isConfirming) {
            Button(role: .destructive) { model.send(.discardConfirmed) } label: {
                Text(.form.discard)
            }
            Button(role: .cancel) { model.send(.discardDismissed) } label: {
                Text(.form.keepEditing)
            }
        } message: {
            Text(.form.discardMessage)
        }
    }

    private var isConfirming: Binding<Bool> {
        Binding(
            get: { model.state.isConfirmingDiscard },
            set: { if !$0 { model.send(.discardDismissed) } })
    }
}
