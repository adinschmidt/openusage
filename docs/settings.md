# Settings

Open Settings from the panel's **⋯** menu or press **⌘,**. It has four tabs: General, Display,
Alerts, and Advanced. Changes apply at once. Hover the ⓘ beside a setting to see what it does.

## General

- **Launch at Login.** Starts OpenUsage when you sign in to your Mac.
- **Global Shortcut.** Opens and closes the panel from any app. Click the field and press the keys.

## Menu bar

- **Compact Provider Icons.** On by default in this fork. Always shows up to two limits per account
  beside one icon, as percentages left. Pin limits to choose them; otherwise the first two visible
  limits show in their saved order. The menu-bar item cap and Always Show setting below apply only
  with compact icons off. The dashboard's Show Usage As setting does not change compact percentages.
- **Max Items In Menu Bar.** App Icon Only, or Up to 1 through Up to 5 limits, closest to running out
  first. Others show as a count, like `+7`. The default is Up to 3. See [Menu bar](menu-bar.md).
- **Always Show In Menu Bar.** The alternate menu-bar mode lists limits in this order: Pinned,
  Running Out, Use It or Lose It, then Used Up. Off by default, showing only what's running out.
- **Warning.** A limit with this much left or less turns orange and moves to Running Out. 20% to
  70% left, 30% by default.
- **Critical.** A limit with this much left or less turns red. 5% to 25% left, 10% by default.
- **Burning Fast.** Also lists a limit under Running Out, and in the menu bar, when it would run out
  before it resets at your current pace, however much it has left. On by default.
- **Use It or Lose It.** Includes a limit in the alternate menu-bar mode when it resets within 24 hours
  with over 50% left, the same rule as the alert of that name. It shows in the menu bar only with
  Always Show In Menu Bar on. On by default, and separate from the alert.

Warning and Critical always count what's left, even with Show Usage As set to Used, and they also
pick which limits the menu bar shows and when the Warning and Critical notifications fire. Critical
always stays under Warning: moving one onto the other pushes the other 5% along.

## Appearance

- **Theme.** System, Light, or Dark.
- **Time Format.** Auto (your macOS locale), 12-hour, or 24-hour.

## Usage display

- **Show Usage As.** `48% used` or `52% left`, on the dashboard and in the menu bar.
- **Reset Times.** `Resets 3h 25m` or `Resets Wed 4:00 PM`.
- **Pace Marks.** A tick on each bar where usage would be at an even pace through
  the window. Off by default.

Click a limit's amount or reset on the dashboard to flip either one.

## Notifications

All off by default. Turning the first one on asks macOS for permission.
If notifications are off for OpenUsage, click **System Settings** in the notice to open
**Notifications → OpenUsage** and allow them.

- **Critical.** A limit drops to its Critical level or less left (10% by default).
- **Warning.** A limit drops to its Warning level or less left (30% by default).
- **Will Run Out.** A limit may run out before its reset. After it fires, it waits until the limit's
  pace eases to 90% of the limit before it can fire again.
- **Use It or Lose It.** A limit resets within 24 hours with over 50% left. Only for windows longer
  than a day, such as weekly and monthly limits, never the 5-hour session or a dollar spending cap.

Each fires once per metric per reset window. Click one to open All Usage.

## Privacy

- **Privacy Mode.** Shows the app icon instead of your usage, and blurs account names in the panel,
  while your screen is shared or recorded. Copied pictures blur account names while it's on. Off by
  default.
- **Help Make OpenUsage Better.** Sends optional daily account counts by provider. The daily active
  ping and crash reports don't depend on it.

See [Privacy](privacy.md).

## Command line

- **Terminal Helper.** **Install…** links `/usr/local/bin/openusage` to the app's `openusage`
  command, after a macOS administrator prompt. **Uninstall** removes the link. It reads
  **Unavailable** when something OpenUsage didn't install sits at that path. See
  [Command line](cli.md).

## Debug

- **Log Level.** Error, Warning, Info (default), or Debug. Choose Debug while you reproduce a
  problem. See [Debugging](debugging.md).

## Updates

- **Check Automatically.** Checks about once an hour and shows **Update Available** on the
  dashboard.
- **Beta Updates.** Includes pre-release builds.
- **Check for Updates…** checks now.

The dev build disables these. See [Updates](updates.md).

## Importing existing OpenUsage accounts

The personal app uses `com.adinschmidt.openusage` for its preferences and Keychain services. Its first
launch copies accounts, layout, menu-bar visibility, and other settings from `com.robinebers.openusage`.
It copies account credentials and any hub management keys directly between Keychain services.

macOS may ask permission for each old credential. Each copy is attempted once, including refused or
interrupted prompts. If a copy fails, sign in again or replace that account's key in Accounts. An
existing personal account list is never overwritten, and removing an imported account does not bring
it back on a later launch. The old app's settings and credentials are left untouched.
