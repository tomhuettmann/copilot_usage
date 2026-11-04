import CopilotUsageCore
import Foundation
import Testing

@Suite struct MenuBarModeTests {
    private let enUS = Locale(identifier: "en_US")
    private let deDE = Locale(identifier: "de_DE")

    private func usage(
        entitlement: Int = 300, remaining: Int = 180, percentRemaining: Double = 60, unlimited: Bool = false
    ) -> Usage {
        Usage(
            entitlement: entitlement, remaining: remaining, percentRemaining: percentRemaining,
            unlimited: unlimited, resetDate: nil
        )
    }

    @Test(arguments: [
        (MenuBarMode.usedRequests, "120 / 300"),
        (.remainingRequests, "180 / 300"),
        (.usedPercentage, "40% / 300"),
        (.remainingPercentage, "60% / 300"),
    ])
    func formatsEveryMode(mode: MenuBarMode, expected: String) {
        #expect(Formatting.title(for: usage(), mode: mode, locale: enUS) == expected)
    }

    @Test func defaultsToUsedRequests() {
        #expect(MenuBarMode.default == .usedRequests)
        #expect(Formatting.title(for: usage(), locale: enUS) == "120 / 300")
    }

    @Test(arguments: MenuBarMode.allCases)
    func unlimitedAlwaysShowsInfinity(mode: MenuBarMode) {
        #expect(Formatting.title(for: usage(unlimited: true), mode: mode, locale: enUS) == "∞")
    }

    @Test func clampsNegativeRemainingRequests() {
        let overUsed = usage(remaining: -20, percentRemaining: -6.7)
        #expect(Formatting.title(for: overUsed, mode: .remainingRequests, locale: enUS) == "0 / 300")
        #expect(Formatting.title(for: overUsed, mode: .remainingPercentage, locale: enUS) == "0% / 300")
        #expect(Formatting.title(for: overUsed, mode: .usedPercentage, locale: enUS) == "100% / 300")
    }

    @Test func clampsPercentagesAbove100() {
        let odd = usage(percentRemaining: 130)
        #expect(Formatting.title(for: odd, mode: .remainingPercentage, locale: enUS) == "100% / 300")
        #expect(Formatting.title(for: odd, mode: .usedPercentage, locale: enUS) == "0% / 300")
    }

    @Test func roundsToWholePercent() {
        let value = usage(entitlement: 10000, remaining: 6259, percentRemaining: 62.6)
        #expect(Formatting.title(for: value, mode: .remainingPercentage, locale: enUS) == "63% / 10,000")
        #expect(Formatting.title(for: value, mode: .usedPercentage, locale: enUS) == "37% / 10,000")
    }

    @Test func omitsSpaceBeforePercentSignInGerman() {
        let title = Formatting.title(for: usage(), mode: .remainingPercentage, locale: deDE)
        #expect(title.hasPrefix("60%"))
        #expect(!title.contains(" %"))
    }

    @Test func rejectsUnknownRawValue() {
        #expect(MenuBarMode(rawValue: "nonsense") == nil)
        #expect(MenuBarMode(rawValue: "usedPercentage") == .usedPercentage)
    }
}
