import Core
import DesignSystem
import Localization
import SwiftUI

public struct ParsingView: View {
    @Environment(\.badeTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            VStack(spacing: .xxs) {
                Text(.parsing.betaNote)
                    .multilineTextAlignment(.center)
                Text(.parsing.processedHere)
            }
            .font(.badeCaption)
            .foregroundStyle(theme.inkFaint)
            .padding(.horizontal, .screenMargin)
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
            // The BETA badge that used to sit here is gone: guideline 2.2 keeps betas off the App
            // Store, and the word was doing no work the note below does not do better. Two banks
            // are understood and either could change its export without telling anyone — saying so
            // on the screen where it would break is still cheaper than a one-star review.
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
        // Reading a year of PDF takes a second or two before the first month can be named, and an
        // empty bar under a headline reads as a hang rather than as work.
        if model.state.phase == .reading { return .parsing.reading }
        guard let month = model.state.currentMonth, let progress = model.state.progress else {
            return nil
        }
        return .parsing.progress(
            month.formatted(.dateTime.month(.wide).year()),
            progress.formatted(.percent.precision(.fractionLength(0))))
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

            // Fills from the top and only starts following once there are more rows than fit.
            // Anchoring the scroll view to its bottom did follow them, but it also pinned a short
            // list to the foot of the space, so the first few rows arrived from underneath.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: .xs) {
                        ForEach(Array(model.state.revealedGroups.enumerated()), id: \.element.id) {
                            index, group in
                            FoundSubscriptionRow(group: group, settling: settling(at: index))
                                .id(group.id)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, .screenMargin)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: model.state.revealedCount) {
                    guard let last = model.state.revealedGroups.last else { return }
                    withBadeAnimation(.badeContent, reduceMotion: reduceMotion) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .badeAnimation(.badeCatch, value: model.state.revealedCount)
    }

    private func settling(at index: Int) -> Double {
        let distanceFromNewest = model.state.revealedGroups.count - 1 - index
        return max(0, 1 - Double(distanceFromNewest) / 3)
    }
}
