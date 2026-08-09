import Core
import Foundation
import Observation

@MainActor
@Observable
public final class ParsingViewModel {
    public private(set) var state: ParsingState

    private let importer: any StatementImporting
    private let onOutcome: (ParsingOutcome) -> Void
    private var work: Task<Void, Never>?

    public init(
        file: StatementFile,
        importer: any StatementImporting,
        onOutcome: @escaping (ParsingOutcome) -> Void
    ) {
        state = ParsingState(file: file)
        self.importer = importer
        self.onOutcome = onOutcome
    }

    public func send(_ intent: ParsingIntent) {
        guard let effect = state.apply(intent) else { return }
        work = Task { [weak self] in await self?.run(effect) }
    }

    /// Dismissing mid-reveal must stop the chain, or rows keep arriving into a screen nobody sees.
    public func cancel() {
        work?.cancel()
        work = nil
    }

    private func run(_ effect: ParsingEffect) async {
        switch effect {
        case .read(let data):
            do {
                send(.read(try await importer.detectSubscriptions(in: data)))
            } catch {
                send(.readFailed(error as? ImportError ?? .unreadableFile))
            }

        case .scheduleReveal(let delay):
            guard await sleep(delay) else { return }
            send(.revealNext)

        case .scheduleCompletion(let delay):
            guard await sleep(delay) else { return }
            send(.completed)

        case .exit(let outcome):
            onOutcome(outcome)
        }
    }

    private func sleep(_ delay: Duration) async -> Bool {
        (try? await Task.sleep(for: delay)) != nil && !Task.isCancelled
    }
}
