import Foundation

/// Stores the usage history as JSON in `~/Library/Application Support/CopilotUsage`.
public struct HistoryStore: Sendable {
    public let url: URL

    public init(url: URL = HistoryStore.defaultURL) {
        self.url = url
    }

    public static var defaultURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "CopilotUsage", directoryHint: .isDirectory)
            .appending(path: "history.json")
    }

    public func load() -> History {
        guard let data = try? Data(contentsOf: url),
              let history = try? JSONDecoder.history.decode(History.self, from: data)
        else { return History() }
        return history
    }

    @discardableResult
    public func save(_ history: History) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder.history.encode(history).write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Removes the history file and its directory if it is empty afterwards.
    public func delete() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: url)
        let directory = url.deletingLastPathComponent()
        if (try? fileManager.contentsOfDirectory(atPath: directory.path(percentEncoded: false)))?.isEmpty == true {
            try? fileManager.removeItem(at: directory)
        }
    }
}

extension JSONEncoder {
    static var history: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var history: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
