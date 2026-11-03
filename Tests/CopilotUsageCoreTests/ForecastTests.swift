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

@Suite struct StatusTests {
    private let reset = Date(timeIntervalSince1970: 1_793_491_200)
    private let periodStart = Date(timeIntervalSince1970: 1_790_812_800)
    private let day: TimeInterval = 86400
    private let enUS = Locale(identifier: "en_US")
    private let utc = TimeZone(identifier: "UTC")!

    private func usage(used: Int) -> Usage {
        Usage(entitlement: 1000, remaining: 1000 - used, percentRemaining: 0, unlimited: false, resetDate: reset)
    }

    private func status(used: Int, daysIn: Double = 10) -> UsageStatus? {
        let usage = usage(used: used)
        let forecast = Forecast.make(usage: usage, now: periodStart.addingTimeInterval(daysIn * day))
        return usage.status(forecast: forecast)
    }

    private func line(used: Int, daysIn: Double = 10) -> String {
        let usage = usage(used: used)
        let forecast = Forecast.make(usage: usage, now: periodStart.addingTimeInterval(daysIn * day))
        return Formatting.statusLine(for: usage, forecast: forecast, locale: enUS, timeZone: utc)
    }

    @Test func elapsedFraction() throws {
        let forecast = try #require(Forecast.make(usage: usage(used: 100), now: periodStart.addingTimeInterval(10 * day)))
        #expect(forecast.elapsedFraction == 10.0 / 31.0)
        #expect(forecast.resetDate == reset)

        let late = try #require(Forecast.make(usage: usage(used: 100), now: reset.addingTimeInterval(day)))
        #expect(late.elapsedFraction == 1)
    }

    @Test func statusLevels() {
        #expect(status(used: 200) == .onTrack)
        #expect(status(used: 300) == .tight)
        #expect(status(used: 500) == .behind)
        #expect(status(used: 1000) == .exhausted)
        #expect(status(used: 1200) == .exhausted)
    }

    @Test func noStatusWithoutDataOrForUnlimited() {
        #expect(status(used: 0, daysIn: 0.05) == nil)
        let unlimited = Usage(entitlement: 0, remaining: 0, percentRemaining: 100, unlimited: true, resetDate: reset)
        #expect(unlimited.status(forecast: nil) == nil)
    }

    @Test func exhaustedWinsOverMissingForecast() {
        let usage = usage(used: 1000)
        #expect(usage.status(forecast: nil) == .exhausted)
    }

    @Test func statusLines() {
        #expect(line(used: 200) == "On track · resets in 21 days")
        #expect(line(used: 300) == "Tight · projected 93% by reset")
        #expect(line(used: 500) == "Runs out Oct 21 · 11 days early")
        #expect(line(used: 1000) == "Quota used up · resets Nov 1")
        #expect(line(used: 0, daysIn: 0.05) == "Collecting data…")
    }

    @Test func unlimitedLine() {
        let unlimited = Usage(entitlement: 0, remaining: 0, percentRemaining: 100, unlimited: true, resetDate: reset)
        #expect(Formatting.statusLine(for: unlimited, forecast: nil) == "Unlimited premium requests")
    }

    @Test func resetsInFormatting() {
        #expect(Formatting.resetsIn(days: 21) == "resets in 21 days")
        #expect(Formatting.resetsIn(days: 1) == "resets in 1 day")
        #expect(Formatting.resetsIn(days: 1.2) == "resets in 2 days")
        #expect(Formatting.resetsIn(days: 0.5) == "resets in 12 hours")
        #expect(Formatting.resetsIn(days: 0.01) == "resets in 1 hour")
    }
}
