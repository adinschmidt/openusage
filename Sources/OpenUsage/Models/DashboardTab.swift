import Foundation

enum DashboardTab: String, Hashable, Sendable, CaseIterable {
    /// Retained for reading preferences written by upstream versions.
    static let defaultKey = "defaultDashboardTab"

    case priority
    case allUsage

    static func preferred(in defaults: UserDefaults = .standard) -> Self {
        .allUsage
    }

    var label: String {
        switch self {
        case .priority: "Priority"
        case .allUsage: "All Usage"
        }
    }
}
