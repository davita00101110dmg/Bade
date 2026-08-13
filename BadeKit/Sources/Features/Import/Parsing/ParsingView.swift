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
            .padding(.top, .xs)

            header
                .padding(.horizontal, .screenMargin)
                .padding(.top, .xxl)

            if !model.state.hasStopped {
                foundList.padding(.top, .lg)
            }

            Spacer(minLength: .zero)

            if model.state.hasStopped {
                Button { model.send(.chooseAnotherTapped) } label: { Text(.parsing.chooseAnother) }
                    .buttonStyle(.badePrimary)
                    .padding(.horizontal, .screenMargin)
            }

            Text(.parsing.processedHere)
                .font(.badeCaption)
                .foregroundStyle(theme.inkFaint)
                .padding(.top, .xl)
                .padding(.bottom, .lg)
        }
        .background(theme.surface, ignoresSafeAreaEdges: .all)
        .badeFeedback(.itemAppeared, trigger: model.state.revealedCount)
        .badeFeedback(.failure, trigger: model.state.failure)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { model.send(.closeTapped) } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel(Text(.parsing.close))
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .task { model.send(.appeared) }
        .onDisappear { model.cancel() }
    }

    private var header: some View {
        VStack(spacing: .sm) {
            Text(headline)
                .font(.badeDisplay)
                .foregroundStyle(theme.ink)
                .multilineTextAlignment(.center)

            if let explanation {
                Text(explanation)
                    .font(.badeBody)
                    .foregroundStyle(theme.inkMuted)
                    .multilineTextAlignment(.center)
            } else {
                if let caption {
                    Text(caption)
                        .font(.badeBody)
                        .foregroundStyle(theme.inkMuted)
                        .contentTransition(.numericText())
                }
                BadeProgressBar(progress: model.state.progress, pace: model.state.revealPace)
                    .padding(.top, .xxs)
            }
        }
        .badeAnimation(.badeContent, value: model.state.revealedCount)
    }

    /// Reading, unreadable, or read and empty — the last is not a failure and does not say so.
    private var headline: LocalizedStringResource {
        if model.state.failure != nil { return .parsing.failed }
        if model.state.phase == .foundNothing { return .parsing.nothingTitle }
        return .parsing.title
    }

    private var explanation: LocalizedStringResource? {
        if let failure = model.state.failure { return failure.message }
        if model.state.phase == .foundNothing { return .parsing.nothingMessage }
        return nil
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

    private func settling(at index: Int) -> Double {
        let distanceFromNewest = model.state.revealedGroups.count - 1 - index
        return max(0, 1 - Double(distanceFromNewest) / 3)
    }
}
