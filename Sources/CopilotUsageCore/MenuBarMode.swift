import Foundation

public enum MenuBarMode: String, CaseIterable, Identifiable, Sendable {
    case usedRequests
    case remainingRequests
    case usedPercentage
    case remainingPercentage

    public static let `default` = MenuBarMode.usedRequests

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .usedRequests: "Used requests"
        case .remainingRequests: "Remaining requests"
        case .usedPercentage: "Used percentage"
        case .remainingPercentage: "Remaining percentage"
        }
    }
}
