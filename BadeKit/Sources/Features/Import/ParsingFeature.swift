import Core
import Foundation
import SwiftUI

public struct ParsingState: Equatable {
    public enum Phase: Equatable {
        case reading
        case revealing
        case finished
        case failed(ImportError)
    }

    public let file: StatementFile
    public var phase: Phase = .reading
    public var found: [DetectedSubscription] = []
    public var revealedCount = 0
    public var transactionCount: Int?
    public var period: ClosedRange<Date>?
    public var rates = RateBook()

    public init(file: StatementFile) {
        self.file = file
    }

    public var revealed: ArraySlice<DetectedSubscription> { found.prefix(revealedCount) }
    public var revealedGroups: [FoundGroup] { revealed.foundGroups }
    public var isDetailsResolved: Bool { transactionCount != nil }

    public var failure: ImportError? {
        if case .failed(let failure) = phase { return failure }
        return nil
    }

    public var progress: Double {
        guard !found.isEmpty else { return phase == .reading ? 0 : 1 }
        return Double(revealedCount) / Double(found.count)
    }

    public var monthCount: Int? {
        guard let period else { return nil }
        let span = Calendar.current.dateComponents(
            [.month], from: period.lowerBound, to: period.upperBound)
        return (span.month ?? 0) + 1
    }

    public var currentMonth: Date? {
        guard let period, let monthCount, monthCount > 0 else { return nil }
        let step = min(Int(progress * Double(monthCount)), monthCount - 1)
        return Calendar.current.date(byAdding: .month, value: step, to: period.lowerBound)
    }

    var revealPace: Animation {
        .linear(duration: ParsingTiming.interval(forRows: found.count).seconds)
    }
}

public enum ParsingIntent: Equatable {
    case appeared
    case read(ImportResult)
    case readFailed(ImportError)
    case revealNext
    case completed
    case closeTapped
    case chooseAnotherTapped
}

public enum ParsingEffect: Equatable {
    case read(Data)
    case scheduleReveal(Duration)
    case scheduleCompletion(Duration)
    case exit(ParsingOutcome)
}

extension ParsingState {
    public mutating func apply(_ intent: ParsingIntent) -> ParsingEffect? {
        switch intent {
        case .appeared:
            return .read(file.data)

        case .read(let result):
            transactionCount = result.transactionCount
            period = result.period
            rates = result.rates
            found = result.detected
            guard !result.detected.isEmpty else {
                phase = .finished
                return .exit(.finished([], result.rates))
            }
            phase = .revealing
            return .scheduleReveal(ParsingTiming.interval(forRows: result.detected.count))

        case .revealNext:
            guard phase == .revealing else { return nil }
            revealedCount = min(revealedCount + 1, found.count)
            guard revealedCount < found.count else {
                return .scheduleCompletion(ParsingTiming.completionPause)
            }
            return .scheduleReveal(ParsingTiming.interval(forRows: found.count))

        case .completed:
            phase = .finished
            return .exit(.finished(found, rates))

        case .readFailed(let failure):
            phase = .failed(failure)
            return nil

        case .closeTapped:
            return .exit(.cancelled)

        case .chooseAnotherTapped:
            return .exit(.chooseAnother)
        }
    }
}
