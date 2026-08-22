import Core
import DesignSystem
import Localization
import SwiftUI

public struct SubscriptionFormView: View {
    @Environment(\.badeTheme) private var theme

    @State private var model: SubscriptionFormViewModel
    /// The two free-text fields are held here as well as in the draft, which is the only way a
    /// length limit can actually stop a keystroke.
    ///
    /// A `TextField` driven by a computed `Binding` will not accept a shorter value handed back by
    /// its own setter — it keeps what was typed until something else forces a redraw, which is why
    /// bounding these in the reducer passed every test and did nothing on a phone. Writing to state
    /// the view itself owns, from `onChange`, is a separate update, and SwiftUI applies that.
    ///
    /// The reducer still truncates. That is the guarantee anything else writing a draft has to
    /// meet; this is what makes the keyboard stop.
    @State private var merchantText: String
    @State private var amountText: String

    public init(model: SubscriptionFormViewModel) {
        _model = State(initialValue: model)
        _merchantText = State(initialValue: model.state.draft.merchant)
        _amountText = State(initialValue: model.state.draft.amount)
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
            TextField(text: $merchantText, prompt: Text(.form.servicePrompt)) {
                Text(.form.service)
            }
            .font(.badeBody)
            .foregroundStyle(theme.ink)
            .badeNameEntry()
            .listRowBackground(theme.surfaceRaised)
            .onChange(of: merchantText) { _, typed in
                let limited = MerchantInput.limited(typed)
                if limited != typed { merchantText = limited }
                model.send(.merchantChanged(limited))
            }
            // Tapping a suggestion writes the draft from outside this field, so it has to come back.
            .onChange(of: model.state.draft.merchant) { _, chosen in
                if chosen != merchantText { merchantText = chosen }
            }

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
            TextField(text: $amountText) {
                Text(.form.amount)
            }
            .font(.badeAmount)
            .foregroundStyle(theme.ink)
            .badeDecimalEntry()
            .listRowBackground(theme.surfaceRaised)
            .onChange(of: amountText) { _, typed in
                let limited = DecimalInput.limited(typed)
                if limited != typed { amountText = limited }
                model.send(.amountChanged(limited))
            }

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

    /// Every control reads the draft and writes an intent, so the state stays the only place a
    /// value changes. The current one is read here, during `body`, rather than inside the getter:
    /// `@Observable` only records reads made while a body is evaluating, and a getter closure runs
    /// afterwards.
    ///
    /// Used by the pickers, the date and the toggle, which take a value handed back without
    /// argument. The two text fields cannot — see `merchantText`.
    private func field<Value>(
        _ value: KeyPath<SubscriptionDraft, Value>,
        _ intent: @escaping (Value) -> SubscriptionFormIntent
    ) -> Binding<Value> {
        let current = model.state.draft[keyPath: value]
        return Binding(get: { current }, set: { model.send(intent($0)) })
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
