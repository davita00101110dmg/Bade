import Testing

@testable import Core

/// The clustering windows in spec §7.3, field for field.
@Test(arguments: [
    (Cadence.weekly, 6...8),
    (.monthly, 28...31),
    (.quarterly, 88...95),
    (.semiannual, 178...186),
    (.annual, 360...370),
])
func approximateDaysMatchesSpec(cadence: Cadence, expected: ClosedRange<Int>) {
    #expect(cadence.approximateDays == expected)
}

@Test func cadenceWindowsDoNotOverlap() {
    let windows = Cadence.allCases.map(\.approximateDays).sorted { $0.lowerBound < $1.lowerBound }
    for (earlier, later) in zip(windows, windows.dropFirst()) {
        #expect(earlier.upperBound < later.lowerBound)
    }
}
