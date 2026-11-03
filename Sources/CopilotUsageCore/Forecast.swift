import Foundation

public struct Forecast: Sendable, Equatable {
    public let periodStart: Date
    public let resetDate: Date
    /// Share of the period that has passed, from 0 to 1.
    public let elapsedFraction: Double
    public let daysRemaining: Double
    /// Recent requests per day, based on the last 7 days of history or the period average.
    public let averagePerDay: Double
    public let projectedUsed: Int
    public let dailyBudget: Int
    /// When the quota runs out at the current pace, or nil if it lasts until the reset.
    public let runOutDate: Date?

    public var onTrack: Bool { runOutDate == nil }

    public static func make(usage: Usage, history: History = History(), now: Date = .now) -> Forecast? {
        guard !usage.unlimited, usage.entitlement > 0,
              let reset = usage.resetDate,
              let periodStart = Self.utc.date(byAdding: .month, value: -1, to: reset)
        else { return nil }

        let elapsed = now.timeIntervalSince(periodStart)
        guard elapsed >= 2 * 3600 else { return nil }

        let daysRemaining = max(reset.timeIntervalSince(now), 0) / 86400
        let rate = history.recentRate(at: now) ?? Double(usage.used) / (elapsed / 86400)

        let runOutDate: Date?
        if usage.remaining <= 0 {
            runOutDate = now
        } else if rate > 0, Double(usage.remaining) / rate < daysRemaining {
            runOutDate = now.addingTimeInterval(Double(usage.remaining) / rate * 86400)
        } else {
            runOutDate = nil
        }

        let total = reset.timeIntervalSince(periodStart)

        return Forecast(
            periodStart: periodStart,
            resetDate: reset,
            elapsedFraction: total > 0 ? min(max(elapsed / total, 0), 1) : 1,
            daysRemaining: daysRemaining,
            averagePerDay: rate,
            projectedUsed: usage.used + Int((rate * daysRemaining).rounded()),
            dailyBudget: max(usage.remaining, 0) / max(Int(daysRemaining.rounded(.up)), 1),
            runOutDate: runOutDate
        )
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
