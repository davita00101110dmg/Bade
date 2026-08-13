# Next session — start here

Read `CLAUDE.md` first for the working agreement, constraints and UI conventions.
This file is the handoff: where the project is, what is next, and what is still open.

Last updated: **2026-08-13**, end of "Bade part 4".

---

## Where it is

**Build-order steps 1–8 and 12 done. Step 9 built, measured and parked. Step 10 all but finished.**
Everything is committed on `main`; the working tree is clean and the app runs on the device.

```
PDF → Ingestion → Normalization → Detection → Persistence → UI
   326 transactions → 11 subscriptions → nothing unconvertible
```

**394 tests, `swift test` ~0.7s, no simulator needed. iOS build green, no warnings.**

### Screens

| # | Screen | State |
|---|---|---|
| ① | Welcome | ✅ |
| ② | Parsing | ✅ |
| ③ | Review | ✅ three confidence tiers |
| ④ | Subscriptions | ✅ `+`, Edit on swipe and long-press |
| ⑥ | Detail | ✅ chart, FX section, Edit |
| ⓜ | Manual entry / Edit | ✅ five entry points |
| ⑤ | Upcoming + TabView | ✅ behind the Pro lock |
| ⑩ | Settings | ✅ currency, language, appearance, text size, week start, rates, reminders, export |
| ⑨ | Bade Pro | ✅ the pitch; the button is inert until StoreKit |
| ⓡ | Reminder prompt | ✅ asked once, after the first import, Pro only |
| ⑦ | FX breakdown | ▲ **on screen, but money figures deliberately withheld — see below** |

---

## Do this first

**The one thing blocking step 10.** Open the BOG PDF at a Setanta or Spotify charge and read what
the record actually says. Needed: whether it names an account currency, shows any second amount,
and what wording surrounds the two "conversion rate" lines.

Why it matters: a converted charge is recorded as `GEL 14.99` with a `USD→GEL` conversion beside
it and **no second amount anywhere**. So the dollar figure does not exist on the statement — it can
only be divided back out — and which side the merchant priced in is unknown. Worse, the arithmetic
does not yet make sense either way: the bank's rate is consistently *above* the scheme's, which
would mean the bank beat the scheme nine times out of nine if lari were being bought with dollars.
It is not settlement drift either; the lari was strengthening, which would push it the other way.

Until that is answered the FX section shows **only what is printed**: what left the account, both
rates, and the gap between them as a percentage. `FXMarkup` computes the money and annualised
figures and is fully tested — nothing displays them. A sticker price was shown once, labelled as
though the statement contained it, and the user rightly caught it.

Statement text is never printed into a session, so this cannot be settled from parsed fields.

---

## Waiting on the user

- **A list of UI comments**, outstanding since before step 9 and never collected. The oldest item.
- **A real TBC statement**, which step 11 cannot start without.
- **Whether to move the chart's readout above the plot.** The chart is 2.5× taller than the design
  drew it because values were hard to read while scrubbing — but the readout still sits *below* the
  plot, so a hand covers it. Height does not fix that; moving the readout does. Asked twice, not
  answered.

---

## Next up

**Step 13, StoreKit 2 one-time unlock.** `@AppStorage("isPro")` in `BadeRootView` is the **only**
thing anything reads, so that one line becomes the entitlement and every gated feature follows.
Flip it to `true` to see Upcoming and the reminder settings today.

What is gated, and where it is enforced:

| Feature | Enforced by |
|---|---|
| Upcoming | `.badeLocked(!isPro)` in `BadeRootView` — blurs, inerts, offers Pro |
| Reminders | `reminderPreference` resolves to lead `.off` unless `isPro`, so nothing schedules |
| Reminder settings | The row leads to `ProView` instead of the picker |
| The permission ask | `askAboutReminders` requires `isPro` |

**Then 14** the Georgian translation pass, and **11** whenever a TBC statement arrives.

Note the brief says renewal reminders and the calendar are free-forever core loop. Both are now
Pro. That was a deliberate call by the user on 2026-08-13; the brief has not been rewritten.

---

## Open items

1. **No SwiftData migration plan.** The schema has changed repeatedly and `container()` is behind
   `try!`, so a mismatch crashes on launch rather than degrading. Survivable only because the user
   deletes and reinstalls. **This has to land before anyone else installs the app** — that, not v1,
   is its real deadline.
2. **`matchKey` folds the merchant**, so rows stored before that change no longer match. **Delete
   and reinstall before testing an import**, or a re-import duplicates instead of merging and looks
   like a detection bug.
3. **The test suite segfaults about one run in eight.** Parallel suites building SwiftData
   containers; `SubscriptionStoreTests` already names the cause. `.serialized` only serialises
   within a suite, so the fix is a shared lock around container creation in the test helpers, or
   one parent suite spanning both files.
4. **`isPro` is injected into `SettingsViewModel` once**, at construction. Buy Pro from the row that
   leads to `ProView` and the Settings screen behind it will not refresh until it is rebuilt.
   Harmless while nothing can be purchased; **fix it in step 13**, with the same `scenePhase`
   re-read the notification permission check already uses.
5. **Bade Pro advertises seven features and one of them works.** Reminders ship. FX markup is
   closest behind it and currently shows a percentage with no money attached. Price alerts, trends,
   category analytics, widgets and themes do not exist. Fine while it is unbuyable; not fine the
   moment StoreKit lands.
6. **Tapping a reminder just opens the app.** No deep link to the charge or the calendar.
7. **Re-importing the same statement is silent.** It merges correctly and duplicates nothing, but
   nothing says "you have already imported this".
8. **`ImportOutcome.foundNothing` has no screen.**
9. **Seven look-alike Apple charges are still seven cards** in Review's "Not sure" tier.
10. **Every Georgian string is `needs_review`** — drafts, not a translator's work. 186 keys.
11. **The end-to-end run** the user asked for has still not happened.

---

## What was learned about the data (do not re-derive)

- **The statement carries its own exchange rates**, and prints **two**: the card scheme's and the
  bank's. The gap between them is a consistent **1.3–1.5%** and needs no network. NBG's published
  rate differs from the bank's by hundredths of a percent — about **six cents a year** across four
  subscriptions — so the scheme rate is the reference worth using.
- **NBG's API takes one date per request**, has no range parameter, and returns all ~42 currencies.
  Rates quoted per 10 or 100 must be divided by `quantity`, or a markup is overstated tenfold.
- **The account is multi-currency.** A charge paid from a balance already in its own currency has
  no conversion, because none happened. That is not missing data.
- **Tier 2 normalization was measured and parked** — see the `tier-2-normalization` branch. 0.23s
  per line at best, 128 lines qualifying, 79 of them worthless one-offs. Do not rebuild it.
- **Only `Google One` and `LTD KEEPZ.ME`** have ever been detected by interval at annual and
  semiannual cadence. Everything else annual is a single catalog-matched charge.

---

## Working with this user

- **Show it running on the device before committing.** Build → install → launch → *then* ask.
  The simulator is not wanted for this: device only, paired over WiFi.
- **Never commit without asking.**
- **Ask about UI behaviour per screen**, and batch the questions before a long build rather than
  interrupting through it. They will interrupt mid-turn with corrections; read those carefully.
- **They will question the code and the numbers, and they are usually right.** The invented sticker
  price, the arrows that did not work, the haptic that re-fired — all found by them, not by tests.
- **Offer options before building anything visual.** Three or four genuinely different directions
  with a recommendation, not variations on one. That is how the Pro lock was designed.
- **Verify claims before making them.** Check `Bade.debug.dylib`, not the thin launcher, and prove
  a fix rather than assert it.
- **They will cut scope hard once they have seen it.** Three candidate chimes became one, and the
  debug button that auditioned them was deleted the moment it had done its job. Build the scaffold,
  expect to remove it.

---

## Running on the device

Paired over the network, no cable.

```sh
xcodebuild -project Bade.xcodeproj -scheme Bade \
  -destination 'platform=iOS,id=00008140-001A682611E2801C' -allowProvisioningUpdates build

D=DBEB4346-E638-5BA5-AACF-50285C07B389
PID=$(xcrun devicectl device info processes --device $D | awk '/Bade.app\/Bade/{print $1}')
[ -n "$PID" ] && xcrun devicectl device process signal --device $D --pid "$PID" --signal SIGKILL

xcrun devicectl device install app --device $D \
  ~/Library/Developer/Xcode/DerivedData/Bade-*/Build/Products/Debug-iphoneos/Bade.app
xcrun devicectl device process launch --device $D --terminate-existing com.khvedelidze.Bade
```

- **Never pass `--console`** — it ties the app's lifetime to the session.
- *"Locked"* on launch means the phone is locked, and nothing local will fix it. `unavailable` in
  `devicectl list devices` means it is off the network — a different problem.
- **To check what is actually installed**, inspect `Bade.app/Bade.debug.dylib`, not `Bade.app/Bade`.
  The latter is a thin launcher containing none of the code, which makes every symbol check return
  zero and look alarming.

---

## Verifying anything

```sh
cd BadeKit && swift test          # 394 tests, ~0.7s, no simulator
xcodebuild -project Bade.xcodeproj -scheme Bade \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Quality gates, all currently zero:

```sh
grep -rnE "(spacing|padding|cornerRadius): *[0-9]+" Sources/Features Sources/DesignSystem | grep -v Bade
grep -rn 'Text("' Sources/Features/         # raw string keys
grep -rn "format: .currency" Sources/       # money not via .badeMoney
grep -rn "import UIKit" Sources/            # must stay empty
grep -rn '"GEL"' Sources/ | grep -v Sources/App/ | grep -v Previews
```

Screen snapshots exist (`SnapshotTests`, real iOS rendering, writes PNGs) but need the simulator,
which the user does not want driven. Judge UI on the device instead.

---

## Traps hit, so they are not hit again

- **No localised string resolves outside an app bundle.** In `swift test` on the host, `pro.title`
  comes back as `"pro.title"` — this is pre-existing and affects every key. Test the *choice* of
  resource (`LocalizedStringResource` is `Equatable` and compares interpolated arguments), never the
  resolved text. `ReminderText.titleResource(for:)` exists for exactly this reason.
- **`UNNotificationSound` only looks in the app bundle root** and `Library/Sounds`. A file in a
  SwiftPM resource bundle is invisible to it, which is why `bade-chime-rise.wav` lives in `Bade/`.
- **`Bade/` is a `PBXFileSystemSynchronizedRootGroup`.** Files dropped into the folder join the app
  target automatically — no Xcode step, no `.pbxproj` edit. Removing one cleans it out of the built
  bundle too.
- **`UNUserNotificationCenter` is not `Sendable`.** Fetch `.current()` per call; storing it breaks
  a `Sendable` struct under strict concurrency.
- **A platform-varying `some View` does not survive a module boundary.** Write platform shims as
  concrete `ViewModifier`s, as `badeAnimation` and `badeDecimalEntry` do.
- **A modifier that branches on state changes the view's shape**, and changing shape above a
  `TabView` tears it down and drops you on the first tab. Read the environment value and hand it
  back unchanged instead.
- **Several `Button`s in one `List` row merge into a single tap target** unless each declares its
  own `.buttonStyle`. This is why the calendar's month arrows did not work.
- **A `List` row is destroyed when it scrolls away and rebuilt when it returns**, resetting its
  `@State`. The hero total's count-up and haptic replayed every time until "has arrived" moved up
  to the screen.
- **Never step a date one period at a time.** Adding a month repeatedly from the 31st clamps to the
  28th and never recovers. Measure every period from a fixed anchor.
- **A `ForEach` id that is really a coincidence collapses rows.** `\.self` over strings loses
  duplicate weekdays; `ProView`'s features are keyed by SF Symbol name, so reusing `bell.badge`
  would have silently dropped a row.
- **`confirmationDialog` anchors to whatever triggered it.** Use `.alert` for destructive confirms.
- **A grouped `List` reserves top space for a header it does not have.** `contentMargins(.top,
  .zero, for: .scrollContent)` removes it.
- **`drawHierarchy` renders nothing for a window that was never on screen**, and such a window
  never runs SwiftUI's appearance lifecycle either — ask the layer tree directly and drive loads by
  hand.
- **SourceKit in this repo reports "No such module" for every new file.** Stale index, not a real
  error. `swift build` is the truth.
- **The BOG parser flattens all whitespace before matching**, so line wrapping is already handled.

---

## Data handling — read before touching statements

Real statements live only in `statements/` and `BadeKit/Tests/Fixtures/local/`, both gitignored,
plus a blanket `*.pdf` rule.

- **Never commit one.** The repo is public and MIT-licensed.
- Statements contain **third parties** — other people's names and IBANs in transfer records.
- A scrubber exists at `statements/scrub.py` (gitignored).
- **Verify, do not trust.** Compare merchant/amount/date frequency tables before and after.
- When probing real data, print **aggregates and merchant-level detail only** — never a raw line,
  never a counterparty. Delete scratch probes before committing.
