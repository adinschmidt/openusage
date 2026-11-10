import XCTest
@testable import OpenUsage

@MainActor
final class CompactMenuBarTests: XCTestCase {
    private func account(_ id: String, usage: [Double] = [10, 40, 99]) -> DashboardAccount {
        let provider = Provider(id: id, kind: .claude)
        let titles = ["Session", "Weekly", "Sonnet"]
        return DashboardAccount(provider: provider, lines: zip(titles, usage).map { title, used in
            let data = WidgetData(title: title, kind: .percent, used: used, limit: 100, displayMode: .used)
            let descriptor = WidgetDescriptor(provider: provider, key: title, metricLabel: title, sample: data)
            return DashboardLine(descriptor: descriptor, data: data)
        })
    }

    func testHealthyAccountsStayVisibleInSavedOrderWithRemainingValuesAndNoFiveLimitCap() {
        let accounts = (1...6).map { account("claude@\($0)") }
        let content = MenuBarContentBuilder.compact(accounts: accounts, pinned: [])

        XCTAssertEqual(content.groups.map(\.provider.id), accounts.map(\.id))
        XCTAssertEqual(content.items.count, 12)
        XCTAssertEqual(content.groups.first?.items.map(\.value), ["90%", "60%"])
        XCTAssertEqual(content.overflow, 0)
    }

    func testPinsSelectLimitsPerAccountWithoutChangingOtherAccountsOrOrder() {
        let content = MenuBarContentBuilder.compact(
            accounts: [account("claude@2"), account("claude@1", usage: [100, 20, 30])],
            pinned: ["claude@2.Sonnet", "claude@2.Weekly"]
        )

        XCTAssertEqual(content.items.map(\.id), ["claude@2.Weekly", "claude@2.Sonnet", "claude@1.Session", "claude@1.Weekly"])
        XCTAssertEqual(content.items.map(\.value), ["60%", "1%", "0%", "80%"])
    }

    func testGroupedPairFitsTheMenuBarAndUsesLessWidthThanSeparateItems() throws {
        let compact = MenuBarContentBuilder.compact(accounts: [account("claude@1")], pinned: [])
        var separate = compact
        separate.groupsByAccount = false
        let groupedImage = try XCTUnwrap(MenuBarStripRenderer.image(for: compact))
        let separateImage = try XCTUnwrap(MenuBarStripRenderer.image(for: separate))

        XCTAssertLessThan(groupedImage.size.width, separateImage.size.width)
        XCTAssertLessThanOrEqual(groupedImage.size.height, 22)
        XCTAssertEqual(groupedImage.accessibilityDescription, compact.accessibilityText)
    }

    func testCompactPreferenceDefaultsOnAndCanBeDisabledAcrossRelaunches() {
        let defaults = isolatedDefaults()
        let store = WidgetDataStore.forTesting([], defaults: defaults)
        XCTAssertTrue(store.compactProviderIcons)
        store.compactProviderIcons = false
        XCTAssertFalse(WidgetDataStore.forTesting([], defaults: defaults).compactProviderIcons)
    }

    func testAnAccountWithoutReportedLimitsKeepsItsIconWithoutInventingAPercentage() {
        let provider = Provider(id: "openrouter@1", kind: .openrouter)
        let content = MenuBarContentBuilder.compact(
            accounts: [DashboardAccount(provider: provider, lines: [])], pinned: []
        )
        XCTAssertEqual(content.groups.map(\.provider.id), [provider.id])
        XCTAssertEqual(content.items.map(\.value), [WidgetData.noDataValue])
    }

    func testCompactStripOmitsVisibleLabelsButKeepsTheirAccessibleNames() throws {
        let content = MenuBarContentBuilder.compact(accounts: [account("claude@1")], pinned: [])
        let renamed = MenuBarContent(items: content.items.map {
            MenuBarContent.Item(id: $0.id, provider: $0.provider, label: $0.label,
                                shortLabel: "A much longer visible label", value: $0.value)
        }, groupsByAccount: true)
        let originalImage = try XCTUnwrap(MenuBarStripRenderer.image(for: content))
        let renamedImage = try XCTUnwrap(MenuBarStripRenderer.image(for: renamed))

        XCTAssertEqual(try XCTUnwrap(originalImage.tiffRepresentation), try XCTUnwrap(renamedImage.tiffRepresentation))
        XCTAssertTrue(originalImage.accessibilityDescription?.contains("Session 90% left") == true)
        XCTAssertTrue(originalImage.accessibilityDescription?.contains("Weekly 60% left") == true)
    }

    func testHidingOneAccountOnlyAffectsItsMenuBarAndSurvivesARelaunch() {
        let defaults = isolatedDefaults()
        let accounts = [account("claude@1"), account("claude@2")]
        let registry = WidgetRegistry(providers: accounts.map(\.provider), descriptors: accounts.flatMap { $0.lines.map(\.descriptor) })
        let layout = LayoutStore(registry: registry, defaults: defaults)
        let store = WidgetDataStore.forTesting([], registry: registry, defaults: defaults)
        XCTAssertEqual(store.menuBarAccounts(in: layout.displayGroups).map(\.id), ["claude@1", "claude@2"])
        store.menuBarHiddenAccountIDs.insert("claude@1")

        let relaunched = WidgetDataStore.forTesting([], registry: registry, defaults: defaults)
        XCTAssertEqual(relaunched.menuBarAccounts(in: layout.displayGroups).map(\.id), ["claude@2"])
        XCTAssertEqual(relaunched.accounts(in: layout.displayGroups).map(\.id), ["claude@1", "claude@2"])
        relaunched.menuBarHiddenAccountIDs.remove("claude@1")
        XCTAssertEqual(relaunched.menuBarAccounts(in: layout.displayGroups).map(\.id), ["claude@1", "claude@2"])
    }
}
