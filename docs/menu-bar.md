# Menu bar

**Compact Provider Icons** is on by default in this fork. Each account with visible bounded metrics
gets one icon and up to two stacked limits, always showing percentages left in the saved account and
metric order. Pin limits to select them for that account; otherwise its first two visible limits
show. Extra pins after the first two do not show. Limits stay visible regardless of urgency and there
is no five-item cap. Accounts without any visible bounded metrics keep their icon with a dash
instead of a percentage.
Privacy Mode still hides the strip during screen sharing or recording.

An account's **Show In Menu Bar** switch hides that account from either menu-bar mode. Its dashboard
metrics, refreshes, and notifications stay enabled.

Turn Compact Provider Icons off in Settings → Display for the upstream behavior described below.

The alternate strip shows limits closest to running out, with pins and other limits included when
Always Show In Menu Bar is on.

- Left-click the icon to open the panel. Right-click (or control-click) it for **Settings** and
  **Quit OpenUsage**.
- The alternate strip shows limits running low, up to
  **Settings → Display → Menu Bar → Max Items In Menu Bar** (3 by default).
- With **Always Show In Menu Bar** on (off by default), the alternate strip lists pinned limits,
  limits running out, limits resetting mostly unused, then used-up limits. Each limit shows once.
- Each limit shows the provider's mark, a short name, and its value. An account can appear more than once.
- Limits past that number show as a count, like `+7`. Used Up limits never count. With Always Show
  In Menu Bar off, only limits running out show or count.
- With nothing to show, or with **App Icon Only**, the strip shows the app icon.
- With [Privacy Mode](privacy.md#privacy-mode) on, it shows the app icon while your screen
  is shared or recorded.
- When an [update](updates.md) is available, the app icon shows at the end of the strip until the
  update banner goes away.
- When a provider has more than one account, its mark carries the account name's initials: "Personal"
  reads P and "Attention Machine 1" reads A1. Rename one of two accounts with the same initials to tell
  them apart.
