import Foundation

public actor UsageStore {
    public let url: URL
    public private(set) var recoveredCorruptFileURL: URL?

    public static var defaultURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return support.appendingPathComponent("NetMeter/usage.json")
    }

    public init(url: URL? = nil) {
        self.url = url ?? Self.defaultURL
    }

    public func load() -> UsageLedger {
        recoveredCorruptFileURL = nil
        guard let data = try? Data(contentsOf: url) else { return UsageLedger() }
        if let ledger = try? JSONDecoder().decode(UsageLedger.self, from: data) {
            return ledger
        }
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("usage-corrupt-\(UUID().uuidString).json")
        if (try? FileManager.default.moveItem(at: url, to: backup)) != nil {
            recoveredCorruptFileURL = backup
        }
        return UsageLedger()
    }

    public func save(_ ledger: UsageLedger) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(ledger)
        try data.write(to: url, options: .atomic)
    }
}
