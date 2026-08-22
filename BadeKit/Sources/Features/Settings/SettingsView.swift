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
        List {
            proSection
            displaySection
            remindersSection
            ratesSection
            dataSection
            aboutSection
        }
        .badeGroupedList()
        // A grouped list reserves space above its first section for a header it does not have.
        .contentMargins(.top, .zero, for: .scrollContent)
        .contentMargins(.bottom, .xxl, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(theme.surface, ignoresSafeAreaEdges: .all)
    }

    private var displaySection: some View {
        Section {
            NavigationLink {
                CurrencyPicker(known: model.state.knownCurrencies, selected: model.state.currency) {
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

            picker(.settings.language, BadeLanguage.allCases, languageBinding, \.name)
            picker(.settings.appearance, BadeAppearance.allCases, appearanceBinding, \.name)
            TextSizeSlider(size: textSizeBinding)
                .listRowBackground(theme.surfaceRaised)
            picker(.settings.weekStart, BadeWeekStart.allCases, weekStartBinding, \.name)
        } header: {
            Text(.settings.display).badeSectionLabel()
        } footer: {
            Text(.settings.defaultFooter)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)
        }
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

    private var proSection: some View {
        Section {
            NavigationLink { ProView(model: model.pro()) } label: {
                LabeledContent {
                    Image(systemName: "sparkles")
                        .foregroundStyle(theme.accent)
                        .accessibilityHidden(true)
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

    private var remindersFooter: LocalizedStringResource {
        guard model.state.isPro else { return .settings.remindersPro }
        return isReminderDenied ? .settings.remindersDenied : .settings.remindersFooter
    }

    /// Only worth saying when reminders are meant to be arriving.
    private var isReminderDenied: Bool {
        model.state.isReminderDenied && model.state.reminder.isOn
    }

    private var ratesSection: some View {
        Section {
            Toggle(isOn: rateFetchingBinding) { label(.settings.rates) }
                .tint(theme.accent)
                .listRowBackground(theme.surfaceRaised)
        } footer: {
            Text(.settings.ratesFooter)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)
        }
    }

    /// Export is offered only when there is something to export; a share sheet over an empty file
    /// is a dead end.
    private var dataSection: some View {
        Section {
            // Part of Pro, and simply absent without it rather than shown behind a badge: a row
            // that exists only to say you cannot have it is an advert, not a setting. Deleting
            // everything is never gated — that one belongs to whoever's data it is.
            if model.state.hasData && model.state.isPro {
                shareLink(.json, title: .settings.exportJSON, icon: "curlybraces")
                shareLink(.csv, title: .settings.exportCSV, icon: "tablecells")
            }

            Button(role: .destructive) { model.send(.deleteAllRequested) } label: {
                Text(.subscriptions.deleteAll)
                    .font(.badeBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowBackground(theme.surfaceRaised)
        } header: {
            Text(.settings.data).badeSectionLabel()
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
