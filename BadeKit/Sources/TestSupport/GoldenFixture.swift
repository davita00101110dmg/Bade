import Core
import Foundation

/// `Tests/Fixtures/<name>.<ext>` paired with `<name>.expected.json`.
public struct GoldenFixture: Sendable {
    public let name: String
    public let statement: Data
    public let expected: [DetectedSubscription]

    public init(name: String, statementExtension: String) throws {
        let base = Self.directory.appending(path: name)
        self.name = name
        self.statement = try Data(contentsOf: base.appendingPathExtension(statementExtension))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.expected = try decoder.decode(
            [DetectedSubscription].self,
            from: Data(contentsOf: base.appendingPathExtension("expected.json"))
        )
    }

    /// Resolved from source location; fixtures are not bundled resources.
    static let directory: URL = URL(filePath: #filePath)
        .deletingLastPathComponent()  // Sources/TestSupport
        .deletingLastPathComponent()  // Sources
        .deletingLastPathComponent()  // BadeKit
        .appending(path: "Tests/Fixtures")
}
