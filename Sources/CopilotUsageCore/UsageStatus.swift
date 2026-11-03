import Foundation

public enum UsageStatus: Sendable, Equatable {
    case onTrack
    /// The quota lasts, but the projection ends above 90% of it.
    case tight
    /// The quota runs out before the reset.
    case behind
    case exhausted
}

extension Usage {
    /// Nil for unlimited plans and while there is not enough data for a forecast.
    public func status(forecast: Forecast?) -> UsageStatus? {
        guard !unlimited, entitlement > 0 else { return nil }
        if remaining <= 0 { return .exhausted }
        guard let forecast else { return nil }
        if !forecast.onTrack { return .behind }
        return Double(forecast.projectedUsed) > Double(entitlement) * 0.9 ? .tight : .onTrack
    }
}
