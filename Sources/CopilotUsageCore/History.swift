import Foundation

public struct Sample: Codable, Sendable, Equatable {
    public let date: Date
    public let used: Int
    public let entitlement: Int
    public let resetDate: Date?

    public init(date: Date, used: Int, entitlement: Int, resetDate: Date?) {
        self.date = date
        self.used = used
        self.entitlement = entitlement
        self.resetDate = resetDate
    }
}

public struct History: Codable, Sendable, Equatable {
    public static let retention: TimeInterval = 100 * 86400
    static let minimumInterval: TimeInterval = 3600

    public private(set) var samples: [Sample]

    public init(samples: [Sample] = []) {
        self.samples = samples.sorted { $0.date < $1.date }
    }

    public var isEmpty: Bool { samples.isEmpty }

    /// Stores a sample if the usage changed or the last sample is older than an hour, and drops old samples.
    public mutating func record(_ usage: Usage, at date: Date = .now) {
        guard !usage.unlimited else { return }
        if let last = samples.last,
           last.used == usage.used, last.resetDate == usage.resetDate,
           date.timeIntervalSince(last.date) < Self.minimumInterval {
            return
        }
        samples.append(Sample(date: date, used: usage.used, entitlement: usage.entitlement, resetDate: usage.resetDate))
        samples.removeAll { date.timeIntervalSince($0.date) > Self.retention }
    }

    /// Requests used between consecutive samples, attributed to the later sample.
    /// A drop or a new reset date marks a new period, which starts from zero.
    public var deltas: [(date: Date, used: Int)] {
        zip(samples, samples.dropFirst()).map { previous, current in
            let samePeriod = previous.resetDate == current.resetDate && current.used >= previous.used
            return (current.date, samePeriod ? current.used - previous.used : current.used)
        }
    }

    public func used(from start: Date, to end: Date = .now) -> Int {
        deltas.filter { $0.date > start && $0.date <= end }.reduce(0) { $0 + $1.used }
    }

    /// Requests used per calendar day for the `days` days ending with the day of `end`, oldest first.
    public func daily(days: Int, endingAt end: Date = .now, calendar: Calendar = .current) -> [(day: Date, used: Int)] {
        let lastDay = calendar.startOfDay(for: end)
        let days = (0..<days).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: lastDay) }
        return daily(for: days, calendar: calendar)
    }

    /// Requests used per calendar day between `start` and `end`, oldest first.
    public func daily(from start: Date, to end: Date, calendar: Calendar = .current) -> [(day: Date, used: Int)] {
        var days: [Date] = []
        var day = calendar.startOfDay(for: start)
        while day < end {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return daily(for: days, calendar: calendar)
    }

    private func daily(for days: [Date], calendar: Calendar) -> [(day: Date, used: Int)] {
        let totals = Dictionary(grouping: deltas) { calendar.startOfDay(for: $0.date) }
            .mapValues { $0.reduce(0) { $0 + $1.used } }
        return days.map { ($0, totals[$0] ?? 0) }
    }

    /// Average requests per day over the last `window`, or nil if the history covers less than `minimumCoverage`.
    public func recentRate(
        at now: Date = .now,
        window: TimeInterval = 7 * 86400,
        minimumCoverage: TimeInterval = 3 * 86400
    ) -> Double? {
        guard let first = samples.first else { return nil }
        let coverage = min(now.timeIntervalSince(first.date), window)
        guard coverage >= minimumCoverage else { return nil }
        return Double(used(from: now.addingTimeInterval(-coverage), to: now)) / (coverage / 86400)
    }
}
