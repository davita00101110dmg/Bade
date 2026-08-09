import Core
import Testing

/// Asserts output is exactly the fixture's expected subscription set.
public func expectGolden(
    _ actual: [DetectedSubscription],
    matches fixture: GoldenFixture,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    let comparison = compareGolden(actual: actual, expected: fixture.expected)
    if let message = comparison.failureMessage {
        Issue.record(
            Comment(rawValue: "golden fixture '\(fixture.name)' did not match:\n\(message)"),
            sourceLocation: sourceLocation
        )
    }
}
