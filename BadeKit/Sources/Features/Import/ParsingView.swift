import Core
import DesignSystem
import Localization
import SwiftUI

public struct ParsingView: View {
    @Environment(\.badeTheme) private var theme

    @State private var model: ParsingViewModel

    public init(model: ParsingViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: .zero) {
            StatementFileCard(
                file: model.state.file,
                monthCount: model.state.monthCount,
                transactionCount: model.state.transactionCount
            )
            .padding(.horizontal, .screenMargin)
            .padding(.top, .sm)

            header
                .padding(.horizontal, .screenMargin)
                .padding(.top, .xxl)

            foundList
                .padding(.top, .lg)

            Spacer(minLength: .zero)

            Text(.parsing.processedHere)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)
                .padding(.top, .xl)
                .padding(.bottom, .lg)
        }
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeFeedback(.itemAppeared, trigger: model.state.revealedCount)
        .task { model.send(.appeared) }
        .onDisappear { model.cancel() }
    }

    private var header: some View {
        VStack(spacing: .sm) {
            Text(model.state.failure == nil ? .parsing.title : .parsing.failed)
                .font(.badeDisplay)
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.center)

            if let failure = model.state.failure {
                Text(failure.message)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
                    .multilineTextAlignment(.center)
            } else if let caption {
                Text(caption)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
                    .contentTransition(.numericText())
            }

            BadeProgressBar(progress: model.state.progress, pace: model.state.revealPace)
                .padding(.top, .xxs)
        }
        .badeAnimation(.badeContent, value: model.state.revealedCount)
    }

    private var caption: LocalizedStringResource? {
        guard let month = model.state.currentMonth else { return nil }
        return .parsing.progress(
            month.formatted(.dateTime.month(.wide).year()),
            model.state.progress.formatted(.percent.precision(.fractionLength(0))))
    }

    private var foundList: some View {
        VStack(alignment: .leading, spacing: .xs) {
            HStack {
                Text(.parsing.found).badeSectionLabel()
                Spacer()
                Text(model.state.revealedCount, format: .number)
                    .font(.badeHeadline)
                    .foregroundStyle(theme.accent)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, .screenMargin)

            ScrollView {
                VStack(spacing: .xs) {
                    ForEach(Array(model.state.revealedGroups.enumerated()), id: \.element.id) {
                        index, group in
                        FoundSubscriptionRow(group: group, settling: settling(at: index))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, .screenMargin)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .badeAnimation(.badeContent, value: model.state.revealedCount)
    }

    /// The newest rows are dimmest, easing to solid a few rows back.
    private func settling(at index: Int) -> Double {
        let distanceFromNewest = model.state.revealedGroups.count - 1 - index
        return max(0, 1 - Double(distanceFromNewest) / 3)
    }
}
