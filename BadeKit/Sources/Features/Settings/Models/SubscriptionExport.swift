import Core
import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// What a share sheet carries out of Bade. Built from what is already loaded rather than read
/// again, because `ShareLink` needs its payload before the sheet opens, not after.
struct SubscriptionExport: Transferable {
    enum Format {
        case json
        case csv

        var type: UTType { self == .json ? .json : .commaSeparatedText }
        var fileExtension: String { self == .json ? "json" : "csv" }
    }

    let subscriptions: [Subscription]
    let format: Format
    let name: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in try export.data() }
            .suggestedFileName { "\($0.name).json" }
        DataRepresentation(exportedContentType: .commaSeparatedText) { export in try export.data() }
            .suggestedFileName { "\($0.name).csv" }
    }

    private func data() throws -> Data {
        switch format {
        case .json: try SubscriptionJSON.data(for: subscriptions)
        case .csv: Data(SubscriptionCSV.text(for: subscriptions).utf8)
        }
    }
}
