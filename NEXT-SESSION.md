# Next session — start here

Read `CLAUDE.md` first for the working agreement, constraints and UI conventions.
This file is the handoff: where the project is, what is next, and what is still open.

Last updated: **2026-08-12**, end of "Bade part 3".

---

## Where it is

**Build-order steps 1–8 done. Step 9 built, measured and parked. Step 10 all but finished.**
Everything is committed on `main`; the working tree is clean and the app runs on the device.

```
PDF → Ingestion → Normalization → Detection → Persistence → UI
   326 transactions → 11 subscriptions → nothing unconvertible
```

**374 tests, `swift test` ~0.7s, no simulator needed. iOS build green, no warnings.**

### Screens

| # | Screen | State |
|---|---|---|
| ① | Welcome | ✅ |
| ② | Parsing | ✅ |
| ③ | Review | ✅ three confidence tiers |
| ④ | Subscriptions | ✅ `+`, Edit on swipe and long-press |
| ⑥ | Detail | ✅ chart, FX section, Edit; chart is 2.5× taller than the design drew |
| ⓜ | Manual entry / Edit | ✅ five entry points |
| ⑤ | Upcoming + TabView | ✅ **now behind the Pro lock** |
| ⑩ | Settings | ✅ currency, language, appearance, text size, week start, rates switch, export |
| ⑨ | Bade Pro | ✅ the pitch; the button is inert until StoreKit |
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
- **Whether to move the chart's readout above the plot.** The chart was made 2.5× taller because
  values were hard to read while scrubbing — but the readout sits *below* the plot, so a hand
  covers it. Height does not fix that; moving the readout does. Asked, not answered.

---

## Next up

**Make the Pro lock beautiful.** The user's words: *"I like the idea, but you can make this more
beautiful."* `BadeLock` in DesignSystem currently blurs the screen and puts a plain card over it —
lock glyph, title, tagline, button. It works and it is dull. This is the first thing to do.

**Then step 12, notifications.** The calendar and detail parts of that step are already done.

After that: **13** StoreKit (see the Pro gate below), **14** the Georgian translation pass, and
**11** whenever a TBC statement arrives.

### The Pro gate

`@AppStorage("isPro")` in `BadeRootView`, default `false`, is the **only** thing anything reads.
Upcoming is wrapped in `.badeLocked(!isPro) { … }`, which blurs it, makes it inert, and offers the
Pro page as a sheet. When StoreKit lands, that one line becomes the entitlement and every gated
feature follows. Flip it to `true` to see Upcoming again.

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
4. **Bade Pro advertises six features and has none.** FX markup is closest and currently shows a
   percentage with no money attached. Price alerts, trends, category analytics, widgets and themes
   do not exist. Fine while it is unbuyable; not fine the moment StoreKit lands.
5. **Re-importing the same statement is silent.** It merges correctly and duplicates nothing, but
   nothing says "you have already imported this".
6. **`ImportOutcome.foundNothing` has no screen.**
7. **Seven look-alike Apple charges are still seven cards** in Review's "Not sure" tier.
8. **Every Georgian string is `needs_review`** — drafts, not a translator's work.
9. **The end-to-end run** the user asked for has still not happened.

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
- **Never commit without asking.**
- **Ask about UI behaviour per screen**, and batch the questions before a long build rather than
  interrupting through it. They will interrupt mid-turn with corrections; read those carefully.
- **They will question the code and the numbers, and they are usually right.** The invented sticker
  price, the arrows that did not work, the haptic that re-fired — all found by them, not by tests.
- **Verify claims before making them.** Two verification attempts this session were wrong before
  they were right: check `Bade.debug.dylib`, not the thin launcher, and prove a fix rather than
  assert it.
- **Designs are a starting point.** Implement, then propose.
- Simulator is theirs to drive. Build and run tests; do not attach to it without asking.

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
- *"Locked"* on launch means the phone is locked. `unavailable` in `devicectl list devices` means
  it is off the network — a different problem, and nothing local will fix it.
- **To check what is actually installed**, inspect `Bade.app/Bade.debug.dylib`, not `Bade.app/Bade`.
  The latter is a thin launcher containing none of the code, which makes every symbol check return
  zero and look alarming.

---

## Verifying anything

```sh
cd BadeKit && swift test          # 374 tests, ~0.7s, no simulator
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

Screen snapshots — real iOS rendering, writes PNGs for a person to look at:

```sh
xcodebuild test -scheme BadeKit-Package \
  -destination 'platform=iOS Simulator,id=<booted sim id>' -only-testing:SnapshotTests
# then read BADE_SNAPSHOT_DIR from the output
```

---

## Traps hit, so they are not hit again

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
- **`ForEach(_:id: \.self)` over strings silently collapses duplicates.** Two weekdays are "T" and
  two are "S", so the calendar header lost two columns.
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
