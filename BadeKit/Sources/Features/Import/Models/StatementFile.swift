import Foundation

public struct StatementFile: Equatable, Sendable, Identifiable {
    public let name: String
    public let byteCount: Int
    public let data: Data

    public var id: String { name }

    public init(name: String, byteCount: Int, data: Data) {
        self.name = name
        self.byteCount = byteCount
        self.data = data
    }

    /// Read into memory and the security scope released immediately; nothing is copied to disk (§10).
    public init?(contentsOf url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(name: url.lastPathComponent, byteCount: data.count, data: data)
    }
}
