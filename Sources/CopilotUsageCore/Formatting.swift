import Foundation

public enum Formatting {
    public static func title(for usage: Usage, locale: Locale = .current) -> String {
        if usage.unlimited { return "∞" }
        return "\(count(usage.used, locale: locale)) / \(count(usage.entitlement, locale: locale))"
    }

    public static func count(_ value: Int, locale: Locale = .current) -> String {
        value.formatted(.number.locale(locale))
    }

    public static func percent(_ value: Double, locale: Locale = .current) -> String {
        (value / 100).formatted(.percent.precision(.fractionLength(0...1)).locale(locale))
    }

    public static func resetsIn(days: Double) -> String {
        if days < 1 {
            let hours = max(Int((days * 24).rounded(.up)), 1)
            return "resets in \(hours) \(hours == 1 ? "hour" : "hours")"
        }
        let count = Int(days.rounded(.up))
        return "resets in \(count) \(count == 1 ? "day" : "days")"
    }

    /// One sentence about where the usage stands, shown at the top of the menu.
    public static func statusLine(
        for usage: Usage, forecast: Forecast?, locale: Locale = .current, timeZone: TimeZone = .current
    ) -> String {
        if usage.unlimited { return "Unlimited premium requests" }

        switch usage.status(forecast: forecast) {
        case nil:
            return "Collecting data…"
        case .exhausted:
            guard let reset = usage.resetDate else { return "Quota used up" }
            return "Quota used up · resets \(day(reset, locale: locale, timeZone: TimeZone(identifier: "UTC")!))"
        case .behind:
            guard let forecast, let runOut = forecast.runOutDate else { return "Runs out before reset" }
            let daysEarly = max(Int((forecast.resetDate.timeIntervalSince(runOut) / 86400).rounded(.up)), 1)
            return "Runs out \(day(runOut, locale: locale, timeZone: timeZone)) · \(daysEarly) \(daysEarly == 1 ? "day" : "days") early"
        case .tight:
            let projected = Double(forecast?.projectedUsed ?? 0) / Double(usage.entitlement) * 100
            return "Tight · projected \(Int(projected.rounded()))% by reset"
        case .onTrack:
            guard let forecast else { return "On track" }
            return "On track · \(resetsIn(days: forecast.daysRemaining))"
        }
    }

    public static func day(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        var style = Date.FormatStyle(locale: locale).month(.abbreviated).day()
        style.timeZone = timeZone
        return date.formatted(style)
    }
}
