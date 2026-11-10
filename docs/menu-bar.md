# Menu bar

**Compact Provider Icons** is on by default in this fork. Each account with visible bounded metrics
gets one icon and up to two stacked limits, always showing percentages left in the saved account and
metric order. Pin limits to select them for that account; otherwise its first two visible limits
show. Extra pins after the first two do not show. Limits stay visible regardless of urgency and there
is no five-item cap. Accounts without any visible bounded metrics keep their icon with a dash
instead of a percentage.
Privacy Mode still hides the strip during screen sharing or recording.

Turn Compact Provider Icons off in Settings → Display for the upstream behavior described below.

The strip shows the limits closest to running out, or with Always Show In Menu Bar everything
Priority lists.

- Left-click the icon to open the panel. Right-click (or control-click) it for **Settings** and
  **Quit OpenUsage**.
- The strip shows the top limits of the dashboard's [Running Out](dashboard.md#priority) list, up to
  **Settings → Display → Priority → Max Items In Menu Bar** (3 by default).
- With **Always Show In Menu Bar** on (off by default), it lists everything Priority does, in its
  order: Pinned, Running Out, Use It or Lose It, then Used Up. A pinned limit shows once, where
  Priority lists it.
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
