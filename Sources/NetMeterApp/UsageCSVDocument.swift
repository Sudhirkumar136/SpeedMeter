import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct UsageCSVDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.commaSeparatedText]

    let contents: String

    init(contents: String) {
        self.contents = contents
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let contents = String(data: data, encoding: .utf8)
        else { throw CocoaError(.fileReadCorruptFile) }
        self.contents = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(contents.utf8))
    }
}
