import Core
import DesignSystem
import Localization
import SwiftUI

public struct ReviewView: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.locale) private var locale

    @State private var model: ReviewViewModel

    public init(model: ReviewViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: .zero) {
            header
                .padding(.horizontal, .screenMargin)
                .padding(.bottom, .md)

            list

            footer
        }
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeFeedback(.selection, trigger: model.state.selectedCount)
        .badeFeedback(.failure, trigger: model.state.didFailToSave)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { model.send(.closeTapped) } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel(Text(.review.close))
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .badeHidesBackButton()
    }

    /// What is being added, not what was found: the figure here is the one the home screen shows
    /// once this is confirmed, and it moves with every tick.
    private var header: some View {
        VStack(alignment: .leading, spacing: .xs) {
            Text(.review.title)
                .font(.badeTitle)
                .foregroundStyle(theme.ink)
            Text(.review.summary(model.state.selectedCount, monthlyTotal))
                .font(.badeBody)
                .foregroundStyle(theme.inkMuted)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .badeAnimation(.badeSelection, value: model.state.selectedCount)
    }

    private var monthlyTotal: String {
        model.state.monthlyTotal.formatted(
            .badeMoney(model.state.currency).locale(locale))
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: .lg) {
                ForEach(model.state.sections) { section in
                    ReviewSectionView(
                        section: section, currency: model.state.currency,
                        send: { model.send($0) })
                }
            }
            .padding(.horizontal, .screenMargin)
            .padding(.bottom, .md)
        }
        .scrollBounceBehavior(.basedOnSize)
        .badeAnimation(.badeContent, value: model.state.sections)
    }

    private var footer: some View {
        VStack(spacing: .xs) {
            if model.state.didFailToSave {
                Text(.review.saveFailed)
                    .font(.badeCaption)
                    .foregroundStyle(theme.warning)
            }
            Button { model.send(.confirmTapped) } label: {
                Text(.review.confirm(model.state.selectedCount))
                    .contentTransition(.numericText())
            }
            .buttonStyle(.badePrimary)
            .disabled(!model.state.canConfirm)
        }
        .padding(.horizontal, .screenMargin)
        .padding(.top, .sm)
        .padding(.bottom, .xs)
        .background(theme.surface)
        .badeAnimation(.badeContent, value: model.state.didFailToSave)
    }
}
