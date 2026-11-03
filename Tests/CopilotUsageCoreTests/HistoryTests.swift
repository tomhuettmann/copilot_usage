import CopilotUsageCore
import Foundation
import Testing

@Suite struct HistoryTests {
    private let reset = Date(timeIntervalSince1970: 1_793_491_200)
    private let start = Date(timeIntervalSince1970: 1_792_000_000)
    private let hour: TimeInterval = 3600

    private func usage(used: Int, resetDate: Date? = nil) -> Usage {
        Usage(entitlement: 1000, remaining: 1000 - used, percentRemaining: 0, unlimited: false,
              resetDate: resetDate ?? reset)
    }

    @Test func skipsUnchangedSamplesWithinAnHour() {
        var history = History()
        history.record(usage(used: 10), at: start)
        history.record(usage(used: 10), at: start.addingTimeInterval(0.5 * hour))
        #expect(history.samples.count == 1)
        history.record(usage(used: 11), at: start.addingTimeInterval(0.6 * hour))
        history.record(usage(used: 11), at: start.addingTimeInterval(1.7 * hour))
        #expect(history.samples.count == 3)
    }

    @Test func ignoresUnlimited() {
        var history = History()
        history.record(Usage(entitlement: 0, remaining: 0, percentRemaining: 100, unlimited: true, resetDate: nil), at: start)
        #expect(history.isEmpty)
    }

    @Test func prunesOldSamples() {
        var history = History()
        history.record(usage(used: 1), at: start)
        history.record(usage(used: 2), at: start.addingTimeInterval(History.retention + hour))
        #expect(history.samples.map(\.used) == [2])
    }

    @Test func deltasStartFromZeroAfterReset() {
        let nextReset = reset.addingTimeInterval(30 * 86400)
        let history = History(samples: [
            Sample(date: start, used: 100, entitlement: 1000, resetDate: reset),
            Sample(date: start.addingTimeInterval(hour), used: 150, entitlement: 1000, resetDate: reset),
            Sample(date: start.addingTimeInterval(2 * hour), used: 20, entitlement: 1000, resetDate: nextReset),
        ])
        #expect(history.deltas.map(\.used) == [50, 20])
        #expect(history.used(from: start, to: start.addingTimeInterval(2 * hour)) == 70)
    }

    @Test func dailyFillsMissingDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day0 = calendar.startOfDay(for: start)
        let history = History(samples: [
            Sample(date: day0.addingTimeInterval(hour), used: 0, entitlement: 1000, resetDate: reset),
            Sample(date: day0.addingTimeInterval(2 * hour), used: 30, entitlement: 1000, resetDate: reset),
            Sample(date: day0.addingTimeInterval(50 * hour), used: 40, entitlement: 1000, resetDate: reset),
        ])
        let daily = history.daily(from: day0, to: day0.addingTimeInterval(52 * hour), calendar: calendar)
        #expect(daily.map(\.used) == [30, 0, 10])
        #expect(daily.first?.day == day0)
    }

    @Test func storeRoundTripAndDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let store = HistoryStore(url: directory.appending(path: "history.json"))
        let history = History(samples: [Sample(date: start, used: 5, entitlement: 1000, resetDate: reset)])

        #expect(store.load().isEmpty)
        #expect(store.save(history))
        #expect(store.load() == history)

        store.delete()
        #expect(!FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)))
    }

    @Test func corruptFileLoadsEmpty() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
        try Data("nope".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(HistoryStore(url: url).load().isEmpty)
    }
}
