import AppKit
import SwiftUI
import XCTest
@testable import OpenUsage

@MainActor
final class PersonalDashboardTests: QuietWindowTestCase {
    override func setUp() {
        super.setUp()
        NSApplication.shared.setValue(true, forKey: "accessibilityEnhancedUserInterface")
    }

    override func tearDown() {
        NSApplication.shared.setValue(false, forKey: "accessibilityEnhancedUserInterface")
        super.tearDown()
    }

    func testAnOldPrioritySelectionStillShowsHealthyLimitsWithoutATabSelector() async throws {
        let defaults = isolatedDefaults()
        let accounts = AccountStore(defaults: defaults, vault: InMemoryCredentialVault())
        let account = accounts.add(kind: .claude, label: "Personal", credential: .apiKey("key"))
        let container = AppContainer.forTesting(accounts: accounts, defaults: defaults)
        container.popover.dashboardTab = .priority
        container.dataStore.snapshots[account.cardID] = ProviderSnapshot(
            providerID: account.cardID, displayName: "Claude", lines: [.percent("Session", 10), .percent("Weekly", 20)]
        )
        let view = VStack(spacing: 0) {
            PopoverTopBar(screen: .dashboard)
            DashboardContentView(reorderSpaceName: "test", reorderLift: .constant(nil),
                                 scrollPosition: .constant(ScrollPosition(edge: .top)))
        }
        .environment(container)
        .environment(container.layout)
        .environment(container.popover)
        .environment(container.dataStore)
        .environment(container.renaming)
        .environment(UpdaterController())
        let (window, host) = show(view, size: CGSize(width: PanelMetrics.width, height: 450))
        defer { window.close() }
        try await waitUntil { Self.strings(in: host).joined(separator: " ").contains("Weekly") }
        let text = Self.strings(in: host).joined(separator: " ")
        XCTAssertTrue(text.contains("Session"), text)
        XCTAssertTrue(text.contains("All Usage"), text)
        XCTAssertFalse(text.contains("Priority"), text)
        XCTAssertFalse(text.contains("All Clear"), text)
    }

    private static func strings(in element: Any) -> [String] {
        guard let node = element as? NSObject else { return [] }
        let text = node.value(forKey: "accessibilityValue") as? String
        let label = node.value(forKey: "accessibilityLabel") as? String
        return [text, label].compactMap { $0 }
            + (node.value(forKey: "accessibilityChildren") as? [Any] ?? []).flatMap(strings(in:))
    }
}
