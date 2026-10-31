import Foundation

public struct Usage: Sendable, Equatable {
    public let entitlement: Int
    public let remaining: Int
    public let percentRemaining: Double
    public let unlimited: Bool
    public let resetDate: Date?

    public var used: Int { max(entitlement - remaining, 0) }

    public init(entitlement: Int, remaining: Int, percentRemaining: Double, unlimited: Bool, resetDate: Date?) {
        self.entitlement = entitlement
        self.remaining = remaining
        self.percentRemaining = percentRemaining
        self.unlimited = unlimited
        self.resetDate = resetDate
    }
}

extension Usage {
    /// Decodes the response of `GET /copilot_internal/user`. The endpoint is undocumented,
    /// so only the fields we need are decoded and all of them are optional.
    public static func decode(from data: Data) throws(UsageError) -> Usage {
        let response: Response
        do {
            response = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw .unexpectedResponse
        }

        guard let quota = response.quota_snapshots?.premium_interactions else {
            throw .noQuota
        }

        let resetDate = response.quota_reset_date_utc.flatMap {
            try? Date($0, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true))
        }

        if quota.unlimited == true {
            return Usage(entitlement: 0, remaining: 0, percentRemaining: 100, unlimited: true, resetDate: resetDate)
        }

        guard let entitlement = quota.entitlement, let remaining = quota.remaining else {
            throw .noQuota
        }

        return Usage(
            entitlement: Int(entitlement),
            remaining: Int(remaining),
            percentRemaining: quota.percent_remaining ?? (entitlement > 0 ? remaining / entitlement * 100 : 0),
            unlimited: false,
            resetDate: resetDate
        )
    }

    private struct Response: Decodable {
        let quota_snapshots: Snapshots?
        let quota_reset_date_utc: String?
    }

    private struct Snapshots: Decodable {
        let premium_interactions: Quota?
    }

    private struct Quota: Decodable {
        let entitlement: Double?
        let remaining: Double?
        let percent_remaining: Double?
        let unlimited: Bool?
    }
}
