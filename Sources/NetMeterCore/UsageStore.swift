import Foundation

public actor UsageStore {
    public let url: URL

    public init(url: URL? = nil) {
        if let url {
            self.url = url
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
            self.url = support.appendingPathComponent("NetMeter/usage.json")
        }
    }

    public func load() -> UsageLedger {
        guard let data = try? Data(contentsOf: url),
              let ledger = try? JSONDecoder().decode(UsageLedger.self, from: data)
        else { return UsageLedger() }
        return ledger
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
