import CopilotUsageCore
import Foundation
import Testing

@Suite struct ForecastTests {
    // 2026-11-01T00:00:00Z, period starts 2026-10-01T00:00:00Z
    private let reset = Date(timeIntervalSince1970: 1_793_491_200)
    private let periodStart = Date(timeIntervalSince1970: 1_790_812_800)
    private let day: TimeInterval = 86400

    private func usage(used: Int, entitlement: Int = 1000) -> Usage {
        Usage(entitlement: entitlement, remaining: entitlement - used,
              percentRemaining: Double(entitlement - used) / Double(entitlement) * 100,
              unlimited: false, resetDate: reset)
    }

    @Test func lastsUntilReset() throws {
        let now = periodStart.addingTimeInterval(10 * day)
        let forecast = try #require(Forecast.make(usage: usage(used: 200), now: now))
        #expect(forecast.periodStart == periodStart)
        #expect(forecast.averagePerDay == 20)
        #expect(forecast.daysRemaining == 21)
        #expect(forecast.projectedUsed == 620)
        #expect(forecast.dailyBudget == 800 / 21)
        #expect(forecast.onTrack)
    }

    @Test func runsOutBeforeReset() throws {
        let now = periodStart.addingTimeInterval(10 * day)
        let forecast = try #require(Forecast.make(usage: usage(used: 500), now: now))
        #expect(forecast.averagePerDay == 50)
        #expect(forecast.runOutDate == now.addingTimeInterval(10 * day))
        #expect(!forecast.onTrack)
    }

    @Test func exhaustedQuotaRunsOutNow() throws {
        let now = periodStart.addingTimeInterval(10 * day)
        let forecast = try #require(Forecast.make(usage: usage(used: 1000), now: now))
        #expect(forecast.runOutDate == now)
        #expect(forecast.dailyBudget == 0)
    }

    @Test func usesRecentRateFromHistory() throws {
        let now = periodStart.addingTimeInterval(20 * day)
        let history = History(samples: [
            Sample(date: now.addingTimeInterval(-7 * day), used: 150, entitlement: 1000, resetDate: reset),
            Sample(date: now, used: 500, entitlement: 1000, resetDate: reset),
        ])
        let forecast = try #require(Forecast.make(usage: usage(used: 500), history: history, now: now))
        #expect(forecast.averagePerDay == 50)
        #expect(!forecast.onTrack)
    }

    @Test func ignoresShortHistory() throws {
        let now = periodStart.addingTimeInterval(10 * day)
        let history = History(samples: [
            Sample(date: now.addingTimeInterval(-day), used: 100, entitlement: 1000, resetDate: reset),
            Sample(date: now, used: 200, entitlement: 1000, resetDate: reset),
        ])
        let forecast = try #require(Forecast.make(usage: usage(used: 200), history: history, now: now))
        #expect(forecast.averagePerDay == 20)
    }

    @Test func noForecastRightAfterPeriodStart() {
        #expect(Forecast.make(usage: usage(used: 0), now: periodStart.addingTimeInterval(3600)) == nil)
    }

    @Test func noForecastWithoutResetDateOrWhenUnlimited() {
        let noReset = Usage(entitlement: 1000, remaining: 500, percentRemaining: 50, unlimited: false, resetDate: nil)
        let unlimited = Usage(entitlement: 0, remaining: 0, percentRemaining: 100, unlimited: true, resetDate: reset)
        #expect(Forecast.make(usage: noReset) == nil)
        #expect(Forecast.make(usage: unlimited) == nil)
    }

    @Test func periodStartHandlesShortMonths() throws {
        // Reset 2027-03-01T00:00:00Z, period is February
        let marchReset = Date(timeIntervalSince1970: 1_803_859_200)
        let usage = Usage(entitlement: 1000, remaining: 1000, percentRemaining: 100, unlimited: false, resetDate: marchReset)
        let forecast = try #require(Forecast.make(usage: usage, now: marchReset.addingTimeInterval(-day)))
        #expect(forecast.periodStart == Date(timeIntervalSince1970: 1_801_440_000)) // 2027-02-01
    }
}
