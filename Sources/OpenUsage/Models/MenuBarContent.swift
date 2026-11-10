import Foundation

struct MenuBarContent: Equatable {
    struct Item: Equatable, Identifiable {
        let id: String
        let provider: Provider
        let label: String
        let shortLabel: String
        let value: String
    }

    let items: [Item]
    var overflow = 0
    var updateAvailable = false
    var groupsByAccount = false

    struct Group: Identifiable {
        let provider: Provider
        var items: [Item]
        var id: String { items[0].id }
    }

    var groups: [Group] {
        var result: [Group] = []
        for item in items {
            if groupsByAccount, let index = result.firstIndex(where: { $0.provider.id == item.provider.id }) {
                result[index].items.append(item)
            } else {
                result.append(Group(provider: item.provider, items: [item]))
            }
        }
        return result
    }

    var isEmpty: Bool { items.isEmpty }

    var accessibilityText: String {
        let shown = items.map { "\($0.provider.fullName) \($0.label) \($0.value)\(groupsByAccount ? " left" : "")" }
        let more = overflow > 0 ? ["\(overflow) more"] : []
        let update = updateAvailable ? ["Update available"] : []
        return (shown + more + update).joined(separator: "; ")
    }
}

@MainActor
enum MenuBarContentBuilder {
    private static let genericWords: Set<String> = ["models", "bot", "usage"]

    /// Pins select up to two limits per account; without pins, use its first two visible limits.
    static func compact(accounts: [DashboardAccount], pinned: Set<String>) -> MenuBarContent {
        let items = accounts.flatMap { account -> [MenuBarContent.Item] in
            let limits = account.lines.filter { $0.data.isBounded }
            guard !limits.isEmpty else {
                return [MenuBarContent.Item(
                    id: "\(account.id).remaining", provider: account.provider,
                    label: "Remaining", shortLabel: "", value: WidgetData.noDataValue
                )]
            }
            let selected = limits.filter { pinned.contains($0.id) }
            return (selected.isEmpty ? limits : selected).prefix(2).map { line in
                MenuBarContent.Item(
                    id: line.id, provider: account.provider, label: line.data.title,
                    shortLabel: shortLabel(line.data.title),
                    value: line.data.hasData
                        ? MetricFormatter.number(line.data.remainingFraction * 100, kind: .percent, style: .tray)
                        : WidgetData.noDataValue
                )
            }
        }
        return MenuBarContent(items: items, groupsByAccount: true)
    }

    /// Only what's running out, or with `alwaysShows` every section of the Priority tab in its order, top to bottom.
    static func build(board: PriorityBoard, limit: MenuBarLimit, alwaysShows: Bool = false) -> MenuBarContent {
        guard limit != .iconOnly else { return MenuBarContent(items: []) }
        let counted = alwaysShows
            ? board.pinned.map { ($0.provider, $0.line) } + (board.attention + board.useItOrLoseIt).map { ($0.provider, $0.line) }
            : board.attention.map { ($0.provider, $0.line) }
        let usedUp = alwaysShows ? board.usedUp.map { ($0.provider, $0.line) } : []
        let shown = (counted + usedUp).prefix(limit.count).map { provider, line in
            let label = line.data.title
            return MenuBarContent.Item(
                id: line.id,
                provider: provider,
                label: label,
                shortLabel: shortLabel(label),
                value: line.data.menuBarValue
            )
        }
        return MenuBarContent(items: shown, overflow: max(0, counted.count - shown.count))
    }

    static func shortLabel(_ label: String) -> String {
        var words = label.split(separator: " ")
        guard words.count > 1, let last = words.last, genericWords.contains(last.lowercased()) else { return label }
        words.removeLast()
        return words.joined(separator: " ")
    }
}
