import Core
import DesignSystem
import Localization
import SwiftUI

public struct SettingsView: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase

    @State private var model: SettingsViewModel
    /// Watched rather than owned. Whole sections appear and disappear with it, and this screen is
    /// built once — so without this an entitlement that arrives, or goes, never reaches it.
    private let isPro: Bool

    public init(model: SettingsViewModel, isPro: Bool) {
        _model = State(initialValue: model)
        self.isPro = isPro
    }

    public var body: some View {
        list
            .navigationTitle(Text(.settings.title))
            .toolbarTitleDisplayMode(.inline)
            .modifier(DeletionConfirmation(model: model))
            // Reloaded on every appearance: an import in another tab changes what an export holds.
            .onAppear { model.send(.appeared) }
            .task(id: isPro) { model.send(.proChecked(isPro)) }
            // And on coming back: notification permission can be changed in iOS Settings, or by
            // the system prompt this screen just triggered, neither of which is an appearance.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { model.send(.appeared) }
            }
    }

    /// Split from `body` deliberately: the whole screen in one chain takes the type checker past
    /// its limit on iOS, and it reports the failure as a missing modifier rather than a timeout.
    private var list: some View {
        // Grouped by what each preference affects rather than by what kind of control it is.
        // Deleting everything sits alone at the foot, away from the two share actions it used to
        // share a header with.
        List {
            proSection
            moneySection
            appearanceSection
            remindersSection
            dataSection
            aboutSection
            deleteSection
        }
        .badeGroupedList()
        // A grouped list reserves space above its first section for a header it does not have.
        .contentMargins(.top, .zero, for: .scrollContent)
        .contentMargins(.bottom, .xxl, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
    }

    /// Both rows decide what the money on screen means: one what it is counted in, the other where
    /// the rate to count it with may come from. The footer is the app's one network promise, and
    /// this is where somebody reading about money will meet it.
    private var moneySection: some View {
        Section {
            // Absent when there is nothing to choose between, which is the common case in a country
            // whose statements are all in one currency. Every other row here offers a real choice;
            // a row leading to a screen with one ticked line on it reads as something broken.
            if model.state.canChooseCurrency { currencyRow }

            Toggle(isOn: rateFetchingBinding) { label(.settings.rates) }
                .tint(theme.accent)
                .listRowBackground(theme.surfaceRaised)
        } header: {
            Text(.currency.title).badeSectionLabel()
        } footer: {
            Text(.settings.ratesFooter)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)
        }
    }

    /// Week start belongs here rather than with reminders: it decides which column the calendar
    /// grid begins on, which is how the month looks rather than when anything happens.
    private var appearanceSection: some View {
        Section {
            picker(.settings.language, BadeLanguage.allCases, languageBinding, \.name)
            picker(.settings.appearance, BadeAppearance.allCases, appearanceBinding, \.name)
            TextSizeSlider(size: textSizeBinding)
                .listRowBackground(theme.surfaceRaised)
            picker(.settings.weekStart, BadeWeekStart.allCases, weekStartBinding, \.name)
        } header: {
            Text(.settings.display).badeSectionLabel()
        }
    }

    /// The one preference whose options are not a fixed set: what can be totalled in depends on
    /// which rates the statements actually carried.
    private var currencyRow: some View {
        NavigationLink {
            CurrencyPicker(only: model.state.displayCurrencies, selected: model.state.currency) {
                model.send(.currencyChanged($0))
            }
        } label: {
            LabeledContent {
                Text(verbatim: model.state.currency)
                    .font(.badeAmount)
                    .foregroundStyle(theme.ink)
            } label: {
                VStack(alignment: .leading, spacing: .xxs) {
                    label(.currency.title)
                    if model.state.isCurrencyInferred {
                        Text(.settings.defaultBadge)
                            .font(.badeLabel)
                            .foregroundStyle(theme.inkFaint)
                    }
                }
            }
        }
        .listRowBackground(theme.surfaceRaised)
    }

    /// One row shape for every preference: a label, the current value, and the whole set behind it.
    private func picker<Option: Identifiable & Hashable>(
        _ title: LocalizedStringResource,
        _ options: [Option],
        _ selection: Binding<Option>,
        _ name: KeyPath<Option, LocalizedStringResource>
    ) -> some View {
        Picker(selection: selection) {
            ForEach(options, id: \.self) { option in
                Text(option[keyPath: name]).tag(option)
            }
        } label: {
            label(title)
        }
        .listRowBackground(theme.surfaceRaised)
    }

    /// Sparkles say there is something to buy; a tick says it is already yours. Without the
    /// difference an owner had no way of knowing from this screen and had to tap through to find
    /// out — which the page then answers in a sentence.
    private var proSection: some View {
        Section {
            NavigationLink { ProView(model: model.pro()) } label: {
                LabeledContent {
                    Image(systemName: model.state.isPro ? "checkmark" : "sparkles")
                        .foregroundStyle(theme.accent)
                        .accessibilityLabel(Text(.pro.owned))
                        .accessibilityHidden(!model.state.isPro)
                } label: {
                    Text(.pro.title).font(.badeBody).foregroundStyle(theme.ink)
                }
            }
            .listRowBackground(theme.surfaceRaised)
        }
    }

    /// Gone entirely without Pro, rather than shown as a row that leads to a shop. What it offers a
    /// Pro user is real: how many days ahead, and at what time. The time is only offered once there
    /// is something to time — "Off at 09:00" is not a setting.
    @ViewBuilder
    private var remindersSection: some View {
        if model.state.isPro {
            Section {
                picker(
                    .settings.remindMe, ReminderLead.allCases, reminderLeadBinding, \.localizedName)

                if model.state.reminder.isOn {
                    DatePicker(
                        selection: reminderTimeBinding, displayedComponents: .hourAndMinute
                    ) {
                        label(.settings.reminderTime)
                    }
                    .tint(theme.accent)
                    .listRowBackground(theme.surfaceRaised)
                }
            } header: {
                Text(.settings.reminders).badeSectionLabel()
            } footer: {
                Text(remindersFooter)
                    .font(.badeCaption)
                    .foregroundStyle(isReminderDenied ? theme.warning : theme.inkFaint)
            }
        }
    }

    /// No branch for being without Pro: the whole section is absent then, so the line saying
    /// reminders are part of Pro could never be reached.
    private var remindersFooter: LocalizedStringResource {
        isReminderDenied ? .settings.remindersDenied : .settings.remindersFooter
    }

    /// Only worth saying when reminders are meant to be arriving.
    private var isReminderDenied: Bool {
        model.state.isReminderDenied && model.state.reminder.isOn
    }

    /// Export is offered only when there is something to export; a share sheet over an empty file
    /// is a dead end. Part of Pro, and simply absent without it rather than shown behind a badge:
    /// a row that exists only to say you cannot have it is an advert, not a setting.
    ///
    /// The whole section goes with it. Without Pro this header sat over nothing but the delete
    /// button, which made "Data" read as the name for destroying it.
    @ViewBuilder
    private var dataSection: some View {
        if model.state.hasData && model.state.isPro {
            Section {
                shareLink(.json, title: .settings.exportJSON, icon: "curlybraces")
                shareLink(.csv, title: .settings.exportCSV, icon: "tablecells")
            } header: {
                Text(.settings.data).badeSectionLabel()
            }
        }
    }

    /// Alone at the foot, under no heading and beside nothing. It was grouped with the two share
    /// actions, which put the one irreversible thing on this screen under the same word as the two
    /// that hand you a copy. Never gated — this one belongs to whoever's data it is.
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) { model.send(.deleteAllRequested) } label: {
                Text(.subscriptions.deleteAll)
                    .font(.badeBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowBackground(theme.surfaceRaised)
        }
    }

    private func shareLink(
        _ format: SubscriptionExport.Format, title: LocalizedStringResource, icon: String
    ) -> some View {
        ShareLink(
            item: SubscriptionExport(
                subscriptions: model.state.subscriptions, format: format, name: exportName),
            preview: SharePreview(Text(title))
        ) {
            Label { Text(title).font(.badeBody) } icon: { Image(systemName: icon) }
        }
        .tint(theme.ink)
        .listRowBackground(theme.surfaceRaised)
    }

    private var aboutSection: some View {
        Section {
            Text(.settings.version(Self.version))
                .font(.badeBody)
                .foregroundStyle(theme.ink)
                .listRowBackground(theme.surfaceRaised)
        } header: {
            Text(.settings.about).badeSectionLabel()
        } footer: {
            VStack(alignment: .leading, spacing: .xxs) {
                Text(.welcome.privacyLine1)
                Text(.welcome.privacyLine2)
            }
            .font(.badeCaption)
            .foregroundStyle(theme.inkFaint)
            .accessibilityElement(children: .combine)
        }
    }

    /// Full ink, like the value beside it. A muted label under a full-strength value inverted the
    /// hierarchy: the setting read quieter than the answer to it.
    private func label(_ title: LocalizedStringResource) -> some View {
        Text(title).font(.badeBody).foregroundStyle(theme.ink)
    }

    private var languageBinding: Binding<BadeLanguage> {
        Binding(get: { model.state.language }, set: { model.send(.languageChanged($0)) })
    }

    private var appearanceBinding: Binding<BadeAppearance> {
        Binding(get: { model.state.appearance }, set: { model.send(.appearanceChanged($0)) })
    }

    private var textSizeBinding: Binding<BadeTextSize> {
        Binding(get: { model.state.textSize }, set: { model.send(.textSizeChanged($0)) })
    }

    private var rateFetchingBinding: Binding<Bool> {
        Binding(get: { model.state.fetchesRates }, set: { model.send(.rateFetchingChanged($0)) })
    }

    private var reminderLeadBinding: Binding<ReminderLead> {
        Binding(get: { model.state.reminder.lead }, set: { model.send(.reminderLeadChanged($0)) })
    }

    /// `DatePicker` deals in dates; the preference keeps minutes after midnight, which cannot hold
    /// an hour without a minute or a time without a day.
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                calendar.date(
                    bySettingHour: model.state.reminder.hour,
                    minute: model.state.reminder.minute, second: 0, of: .now) ?? .now
            },
            set: { chosen in
                let parts = calendar.dateComponents([.hour, .minute], from: chosen)
                model.send(
                    .reminderTimeChanged((parts.hour ?? 0) * 60 + (parts.minute ?? 0)))
            })
    }

    private var weekStartBinding: Binding<BadeWeekStart> {
        Binding(get: { model.state.weekStart }, set: { model.send(.weekStartChanged($0)) })
    }

    private var exportName: String { .badeLocalized(.settings.exportName, in: locale) }

    private static let version =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
}

/// Clearing everything is the one action worth interrupting for: a deleted row comes back by
/// re-importing, an emptied store does not.
private struct DeletionConfirmation: ViewModifier {
    let model: SettingsViewModel

    func body(content: Content) -> some View {
        content.alert(Text(.subscriptions.deleteAllTitle), isPresented: isConfirming) {
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

    private var isConfirming: Binding<Bool> {
        Binding(
            get: { model.state.isConfirmingDeleteAll },
            set: { if !$0 { model.send(.confirmationDismissed) } })
    }
}
