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

    /// The reset date is a UTC midnight, so it is formatted in UTC to show the intended day everywhere.
    public static func resetDate(_ date: Date, locale: Locale = .current) -> String {
        var style = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale)
        style.timeZone = TimeZone(identifier: "UTC")!
        return date.formatted(style)
    }
}
