import Foundation

@testable import StatementCore

/// `Tests/Fixtures/<name>.txt` — a statement as text extraction delivers it — paired with
/// `<name>.expected.json`, written by hand. Every fixture is invented; none comes from a real account.
struct StatementFixture {
    let name: String
    let text: String
    let expected: FixtureExpectation

    init(_ name: String) throws {
        self.name = name
        let base = Self.directory.appending(path: name)
        text = try String(contentsOf: base.appendingPathExtension("txt"), encoding: .utf8)
        expected = try JSONDecoder().decode(
            FixtureExpectation.self,
            from: Data(contentsOf: base.appendingPathExtension("expected.json")))
    }

    /// Resolved from source location; fixtures are not bundled resources.
    static let directory = URL(filePath: #filePath)
        .deletingLastPathComponent()  // Tests/FixtureTests
        .deletingLastPathComponent()  // Tests
        .appending(path: "Fixtures")

    static var names: [String] { files(endingIn: ".txt") }

    static func files(endingIn suffix: String) -> [String] {
        let all = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return all.filter { $0.hasSuffix(suffix) }.map { String($0.dropLast(suffix.count)) }.sorted()
    }

    /// `bog-en`, `bog-ka`, `tbc` or `misc`: everything before the fixture's number.
    var format: String { Self.format(of: name) }

    static func format(of name: String) -> String {
        name.split(separator: "-").prefix { Int($0) == nil }.joined(separator: "-")
    }
}

/// What a fixture must produce. Amounts are strings so they reach `Decimal` without a `Double`.
struct FixtureExpectation: Decodable {
    let parser: String?
    let error: ImportError?
    let covers: [String]
    let transactions: [Transaction]
    let rates: [Rate]
    let subscriptions: [Subscription]
    let candidates: [Candidate]

    struct Transaction: Decodable {
        let date: String
        let description: String
        let amount: String
        let currency: String
        let mcc: String?
        let merchant: String
        let conversion: Conversion?
    }

    struct Conversion: Decodable {
        let from: String
        let to: String
        let bankRate: String
        let schemeRate: String?
    }

    struct Rate: Decodable {
        let date: String
        let from: String
        let to: String
        let rate: String
    }

    struct Subscription: Decodable {
        let merchant: String
        let currency: String
        let cadence: Cadence
        let amount: String
        let charges: Int
        let confidence: Confidence
        let variable: Bool
        let ended: Bool
        let next: String
        let priceChanges: [PriceChange]

        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            merchant = try values.decode(String.self, forKey: .merchant)
            currency = try values.decode(String.self, forKey: .currency)
            cadence = try values.decode(Cadence.self, forKey: .cadence)
            amount = try values.decode(String.self, forKey: .amount)
            charges = try values.decode(Int.self, forKey: .charges)
            confidence = try values.decode(Confidence.self, forKey: .confidence)
            variable = try values.decodeIfPresent(Bool.self, forKey: .variable) ?? false
            ended = try values.decodeIfPresent(Bool.self, forKey: .ended) ?? false
            next = try values.decode(String.self, forKey: .next)
            priceChanges = try values.decodeIfPresent([PriceChange].self, forKey: .priceChanges) ?? []
        }

        private enum CodingKeys: String, CodingKey {
            case merchant, currency, cadence, amount, charges, confidence, variable, ended, next
            case priceChanges
        }
    }

    struct PriceChange: Decodable {
        let date: String
        let from: String
        let to: String
    }

    struct Candidate: Decodable {
        let merchant: String
        let currency: String
        let amount: String
        let charges: Int
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        parser = try values.decodeIfPresent(String.self, forKey: .parser)
        error = try values.decodeIfPresent(String.self, forKey: .error).map(ImportError.init)
        covers = try values.decodeIfPresent([String].self, forKey: .covers) ?? []
        transactions = try values.decodeIfPresent([Transaction].self, forKey: .transactions) ?? []
        rates = try values.decodeIfPresent([Rate].self, forKey: .rates) ?? []
        subscriptions =
            try values.decodeIfPresent([Subscription].self, forKey: .subscriptions) ?? []
        candidates = try values.decodeIfPresent([Candidate].self, forKey: .candidates) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case parser, error, covers, transactions, rates, subscriptions, candidates
    }
}

extension ImportError {
    fileprivate init(_ name: String) throws {
        switch name {
        case "unreadableFile": self = .unreadableFile
        case "unrecognisedFormat": self = .unrecognisedFormat
        case "tooFewTransactions": self = .tooFewTransactions
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: name))
        }
    }
}
