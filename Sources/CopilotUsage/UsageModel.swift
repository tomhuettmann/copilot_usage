import AppKit
import CopilotUsageCore
import Observation

@MainActor
@Observable
final class UsageModel {
    private(set) var usage: Usage?
    private(set) var error: UsageError?
    private(set) var lastUpdated: Date?
    private(set) var hasToken = false

    private let client = UsageClient(userAgent: "CopilotUsage/\(appVersion)")
    private let store = TokenStore()
    private var token: String?
    private var isRefreshing = false

    init() {
        token = store.read()
        hasToken = token != nil
        startRefreshLoop()
        refreshOnWake()
    }

    var title: String {
        if let usage { return Formatting.title(for: usage) }
        if !hasToken { return "Copilot: set token" }
        return error == nil ? "Copilot …" : "Copilot ⚠︎"
    }

    func refresh() async {
        guard let token, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetched = try await client.fetch(token: token)
            guard token == self.token else { return }
            usage = fetched
            error = nil
            lastUpdated = .now
        } catch {
            guard token == self.token else { return }
            self.error = error
            if error == .unauthorized { usage = nil }
            FileHandle.standardError.write(Data("CopilotUsage: \(error.message)\n".utf8))
        }
    }

    /// Validates the token against the API and only stores it if it works.
    func setToken(_ newToken: String) async throws(UsageError) {
        let trimmed = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let fetched = try await client.fetch(token: trimmed)
        guard store.save(trimmed) else { throw .keychain }
        token = trimmed
        hasToken = true
        usage = fetched
        error = nil
        lastUpdated = .now
    }

    func removeToken() {
        store.delete()
        token = nil
        hasToken = false
        usage = nil
        error = nil
        lastUpdated = nil
    }

    private func startRefreshLoop() {
        Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(300))
            }
        }
    }

    private func refreshOnWake() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(5))
                await self?.refresh()
            }
        }
    }
}
