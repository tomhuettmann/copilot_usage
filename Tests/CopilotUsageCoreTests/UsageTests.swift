import CopilotUsageCore
import Foundation
import Testing

@Suite struct UsageTests {
    private let enUS = Locale(identifier: "en_US")

    @Test func decodesPremiumInteractions() throws {
        let json = """
        {
          "copilot_plan": "enterprise",
          "quota_reset_date_utc": "2026-11-01T00:00:00.000Z",
          "quota_snapshots": {
            "chat": { "unlimited": true, "remaining": 0, "entitlement": 0 },
            "premium_interactions": {
              "entitlement": 10000, "remaining": 6259, "percent_remaining": 62.6,
              "quota_remaining": 6259.4, "unlimited": false
            }
          }
        }
        """
        let usage = try Usage.decode(from: Data(json.utf8))

        #expect(usage.entitlement == 10000)
        #expect(usage.remaining == 6259)
        #expect(usage.used == 3741)
        #expect(usage.percentRemaining == 62.6)
        #expect(!usage.unlimited)
        #expect(usage.resetDate == Date(timeIntervalSince1970: 1_793_491_200))
    }

    @Test func decodesUnlimited() throws {
        let json = #"{ "quota_snapshots": { "premium_interactions": { "unlimited": true } } }"#
        let usage = try Usage.decode(from: Data(json.utf8))
        #expect(usage.unlimited)
        #expect(Formatting.title(for: usage) == "∞")
    }

    @Test func missingQuotaThrows() {
        #expect(throws: UsageError.noQuota) {
            try Usage.decode(from: Data(#"{ "quota_snapshots": {} }"#.utf8))
        }
    }

    @Test func invalidJSONThrows() {
        #expect(throws: UsageError.unexpectedResponse) {
            try Usage.decode(from: Data("<html>".utf8))
        }
    }

    @Test func formatsTitle() {
        let usage = Usage(entitlement: 10000, remaining: 6259, percentRemaining: 62.6, unlimited: false, resetDate: nil)
        #expect(Formatting.title(for: usage, locale: enUS) == "3,741 / 10,000")
        #expect(Formatting.title(for: usage, locale: Locale(identifier: "de_DE")) == "3.741 / 10.000")
    }

    @Test func formatsPercent() {
        #expect(Formatting.percent(62.6, locale: enUS) == "62.6%")
        #expect(Formatting.percent(100, locale: enUS) == "100%")
    }

    @Test func formatsResetDateInUTC() {
        let date = Date(timeIntervalSince1970: 1_793_491_200) // 2026-11-01T00:00:00Z
        #expect(Formatting.resetDate(date, locale: enUS) == "Nov 1, 2026")
    }
}
