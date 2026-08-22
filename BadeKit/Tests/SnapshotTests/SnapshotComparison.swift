#if os(iOS)
    import Foundation
    import Testing
    import UIKit

    /// Compares a rendered screen against a reference committed to the repository, so a layout that
    /// breaks fails a test instead of waiting to be noticed on somebody's phone.
    ///
    /// Rendered at scale 1 deliberately. At the simulator's native scale a reference is three times
    /// the pixels and three times the file, and nothing about a layout regression needs that
    /// resolution to be visible.
    enum SnapshotComparison {
        /// Committed, so the comparison means something on a machine that has never run this before.
        static let references: URL = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/Snapshots")

        /// Where a mismatch is written, for a person to open beside the reference. Temporary: a
        /// failure is something to look at now, not something to keep.
        static let failures: URL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "bade-snapshot-failures")

        /// `BADE_RECORD_SNAPSHOTS=1` rewrites every reference instead of comparing. Needed after a
        /// deliberate design change, and never on by accident.
        static var isRecording: Bool {
            ProcessInfo.processInfo.environment["BADE_RECORD_SNAPSHOTS"] == "1"
        }

        /// How much of a screen may differ before it counts as a change.
        ///
        /// Measured rather than guessed. Across repeated runs with no code change, forty of the
        /// forty-two screens are pixel-identical, so they are held to a tight bound — anything that
        /// moves a row or resizes text is thousands of pixels and trips it easily.
        ///
        /// Subscriptions is the exception, and it is named rather than buried in a loose global
        /// bound that would blind the other forty-one.
        ///
        /// Its hero total is drawn by `BadeMoneyText(shimmers: true)` — a *repeating* animation, so
        /// that screen never settles and no amount of waiting makes it repeatable. Suppressing the
        /// transaction does not reach it either. Measured drift between identical runs: 0.29% to
        /// 1.34%, so it is bounded at 2%.
        ///
        /// The cost is stated rather than hidden: a regression on that one screen smaller than 2%
        /// of its pixels goes uncaught. Buying it back means making the shimmer stoppable from a
        /// test — changing shipping code for a test's benefit — which is not obviously the trade.
        static func tolerance(for name: String) -> Double {
            name.hasPrefix("subscriptions") ? 0.02 : 0.001
        }

        /// Per-channel difference that counts as a changed pixel at all.
        private static let channelThreshold = 16

        static func verify(_ image: UIImage, named name: String) throws {
            try FileManager.default.createDirectory(
                at: references, withIntermediateDirectories: true)
            let reference = references.appending(path: "\(name).png")
            let png = try #require(image.pngData(), "\(name) produced no image data")

            guard !isRecording, let existing = try? Data(contentsOf: reference) else {
                try png.write(to: reference)
                return
            }

            let difference = try fraction(between: image, and: #require(UIImage(data: existing)))
            guard difference > Self.tolerance(for: name) else { return }

            try FileManager.default.createDirectory(
                at: failures, withIntermediateDirectories: true)
            let actual = failures.appending(path: "\(name).png")
            try png.write(to: actual)

            Issue.record(
                """
                \(name) differs from its reference by \(percent(difference)) of pixels.
                  reference: \(reference.path)
                  rendered:  \(actual.path)
                If the change was deliberate: BADE_RECORD_SNAPSHOTS=1 and run again.
                """)
        }

        /// The share of pixels that differ, rather than whether any do. One antialiased edge is not
        /// a regression; a row that moved is thousands of pixels.
        private static func fraction(between rendered: UIImage, and reference: UIImage) throws
            -> Double
        {
            let a = try #require(pixels(of: rendered), "could not read the rendered image")
            let b = try #require(pixels(of: reference), "could not read the reference")
            guard a.width == b.width, a.height == b.height else { return 1 }

            var changed = 0
            for index in stride(from: 0, to: a.bytes.count, by: 4) where
                abs(Int(a.bytes[index]) - Int(b.bytes[index])) > channelThreshold
                || abs(Int(a.bytes[index + 1]) - Int(b.bytes[index + 1])) > channelThreshold
                || abs(Int(a.bytes[index + 2]) - Int(b.bytes[index + 2])) > channelThreshold
            {
                changed += 1
            }
            return Double(changed) / Double(a.width * a.height)
        }

        private static func pixels(of image: UIImage)
            -> (bytes: [UInt8], width: Int, height: Int)?
        {
            guard let cgImage = image.cgImage else { return nil }
            let width = cgImage.width
            let height = cgImage.height
            var bytes = [UInt8](repeating: 0, count: width * height * 4)

            // Redrawn into a known layout rather than trusting whatever the PNG decoded into:
            // two images of the same screen can differ in byte order alone.
            guard
                let context = CGContext(
                    data: &bytes, width: width, height: height, bitsPerComponent: 8,
                    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return (bytes, width, height)
        }

        private static func percent(_ value: Double) -> String {
            String(format: "%.2f%%", value * 100)
        }
    }
#endif
