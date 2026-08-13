# Next session — start here

Read `CLAUDE.md` first for the working agreement, constraints and UI conventions.
This file is the handoff: where the project is, what is next, and what is still open.

Last updated: **2026-08-13**, end of "Bade part 5".

---

## Where it is

**Steps 1–8, 11, 12 and 13 done** (13's code is complete and tested; no purchase has ever
round-tripped). **Step 9 built, measured and decided against. Step 10 all but finished.**
Everything through step 11 is committed and pushed. The detection change that followed it is
built and running on the device but **not yet committed**.

```
PDF → Ingestion → Normalization → Detection → Persistence → UI
   BOG  326 transactions → 11 subscriptions → nothing unconvertible
   TBC  770 transactions →  2 subscriptions (the largest of three)
```

**469 tests, `swift test` ~0.7s away from the statements, ~2s here where the PDFs exist.
No simulator needed. iOS build green, no warnings.**

### Screens

| # | Screen | State |
|---|---|---|
| ① | Welcome | ✅ |
| ② | Parsing | ✅ reading, unreadable, and read-but-empty |
| ③ | Review | ✅ three confidence tiers |
| ④ | Subscriptions | ✅ `+`, Edit on swipe and long-press |
| ⑥ | Detail | ✅ chart with the readout above the plot, FX section, Edit |
| ⓜ | Manual entry / Edit | ✅ five entry points |
| ⑤ | Upcoming + TabView | ✅ behind the Pro lock; opens on a day when a reminder is tapped |
| ⑩ | Settings | ✅ currency, language, appearance, text size, week start, rates, reminders, export |
| ⑨ | Bade Pro | ✅ real screen: price from the store, buy, restore, owned, failed |
| ⓡ | Reminder prompt | ✅ asked once, after the first import, Pro only |
| ⑦ | FX breakdown | ▲ **on screen, but money figures deliberately withheld — see below** |
| ⓦ | Widget | ✅ small and medium: this month, spent/still coming, next three. Pro only |

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
- **Whether the widget should name the month** ("AUGUST" rather than "THIS MONTH"), so its figure
  cannot be misread as the list's levelled one. Proposed, never answered. One string.
- **In Xcode:** target iPhone only (`TARGETED_DEVICE_FAMILY` is `1,2,7` and `SUPPORTED_PLATFORMS`
  includes `xros` and `macosx`), and set `ITSAppUsesNonExemptEncryption` so App Store Connect stops
  asking the export-compliance question on every upload.
- **In App Store Connect:** the `com.khvedelidze.Bade.pro` product at ₾24.99 / $9.99, App Privacy
  answers ("Data Not Collected" is honest), a privacy policy URL, and a build number that is not `1`.

---

## Next up

**Finish step 13 by verifying it.** The code is done: `ProPurchasing` in `Core`, `StoreKitPro` in
`Purchases`, and `@AppStorage("isPro")` as a cache of the entitlement, written at launch and from
`Transaction.updates`. What has never happened is a purchase.

- A **local `.storekit` config** only applies when Xcode launches the app (⌘R). Launched from the
  home screen, the app talks to the real App Store, finds no product, and correctly says the store
  cannot be reached. That is why Pro cannot be unlocked on the device by a config file alone.
- **TestFlight is the way in.** Sandbox purchases there are free and they persist standalone, which
  also solves giving Pro to friends. Promo codes need no code at all — a redemption arrives as an
  ordinary transaction — but they require the app to be live first.

What is gated, and where it is enforced:

| Feature | Enforced by |
|---|---|
| Upcoming | `.badeLocked(!isPro)` in `BadeRootView` — blurs, inerts, offers Pro |
| Reminders | `reminderPreference` resolves to lead `.off` unless `isPro`, so nothing schedules |
| Reminder settings | The row leads to `ProView` instead of the picker |
| The permission ask | `askAboutReminders` requires `isPro` |

**Then 14**, the Georgian translation pass.

Note the brief says renewal reminders and the calendar are free-forever core loop. Both are now
Pro. That was a deliberate call by the user on 2026-08-13; the brief has not been rewritten.

---

## The statements

Eight PDFs sit in the gitignored `statements/`: four BOG, **three TBC**, **one Liberty Bank**. The
TBC and Liberty ones belong to **other people**, who agreed to this use. Nothing about them may be
printed into a session, saved anywhere, or committed. Parse, take the subscriptions, nothing else.

All extract as text through PDFKit — no scans, no OCR.

### The TBC format, as built (step 11)

Established by masked probing; no real line was ever read.

- **A card purchase is `POS <location> - <merchant>, <amount> <CUR>, <Mon> <D> <YYYY> <HH:MM><AM|PM>,
  <address>, MCC: <digits>, …`** — one intact run carrying everything Bade needs. The row's own
  columns (BIC, IBAN, amount, balance) follow only **a quarter** of records, because extraction
  emits them as separate blocks, so they are not read at all.
- **`MCC:` appears once per card block and nowhere else**, which makes its count the exact number of
  purchases in the file — the denominator the local suite checks against. All three parse **100%**.
- **The location left of the dash takes one value in a whole statement** (empty for e-commerce), so
  it identifies nothing and is dropped. The merchant is what follows ` - `.
- **The purchase date is inside the record**; the `DD/MM/YYYY` in front is when TBC posted it.
  The month is an **English abbreviation**, so no Georgian is parsed at all.
- **`POS` also appears inside Georgian descriptions** — on the fee charged for a card operation
  above all. 111 of 881 in the largest file. A body has to prove itself a record.
- **The amount is in the currency the charge was made in**, which for this account is mostly GEL but
  also USD and EUR. There is no second amount to pair it with, so `conversion` is always `nil` and
  TBC contributes no markup data.
- **A conversion the account holder made prints its rate** — `(… 1 USD = 2.7100 GEL)`, three to five
  times in a year. `TBCExchangeRecord` reads them; the quantity is divided out.

**`TBCBGE22` alone is not a signature.** A BOG statement prints it on any transfer to a TBC account,
and a Liberty statement did too — all three were claimed by TBC until `canParse` also required one
readable record. `claimsTheTBCStatementsAndNoOthers` guards this against every PDF in the folder.

**Liberty has no parser.** One statement is not a format, and it is now correctly unrecognised
rather than mis-claimed.

### How to look at them without reading them

`statements/shapes.swift` and `statements/facts.swift` (gitignored, kept beside the PDFs) print
**masked shapes** and **statistics** — digits to `9`, Georgian to `ა`, Latin to `A` — so a layout can
be designed without a value entering the session. Run with `swift statements/shapes.swift <file>`.
Verify a parser by **counts only**: transactions parsed, date range, how many became subscriptions.
Never a merchant list, never a counterparty.

**A cross-file filter is not an anonymiser.** "Tokens frequent in every file" was used once to find
format labels on the assumption the three TBC files were different people. They are the same person,
and a name reached the session. Probe by **hypothesis instead**: supply the candidate string, get
back a count and a masked shape, so nothing unknown is ever printed.

### The golden fixture

`Tests/Fixtures/tbc-statement-01.txt` is derived from the largest TBC statement: 770 real records,
with real dates, amounts, currencies and MCCs. **Only a merchant the bundled catalog already knows
survives verbatim** — six raw strings resolving to Apple and Spotify. The other 185 became
`MERCHANT###`. IBAN, PAN, address and balances are fixed placeholders; the non-card rows around it
were written by hand. `namesNoMerchantThatIsNotAlreadyPublic` enforces the rule permanently and
reports a count rather than the offending name.

It was written by a throwaway generator in `PipelineTests`, deleted once it had run. To rebuild it,
write another: parse the statement, keep `catalog.entry(for:) != nil` merchants, replace the rest,
re-render each record and re-parse to prove the rendering round-trips.

---

## Open items

1. **Bade Pro advertises seven features and two work.** Reminders ship; FX shows a percentage with
   no money attached. Price alerts, trends, category analytics, widgets and themes do not exist.
   Charging ₾24.99 for that page risks a 2.3.1 rejection for inaccurate metadata — trim the list or
   mark the rest as coming. **Decide this before the listing is written.**
2. **`matchKey` folds the merchant**, so rows stored before that change no longer match. **Delete
   and reinstall before testing an import**, or a re-import duplicates instead of merging and looks
   like a detection bug.
3. **Seven look-alike Apple charges are still seven cards** in Review's "Not sure" tier.
4. **Every Georgian string is a draft** — 199 keys, all `needs_review`, none seen by a translator.
5. **A revoked entitlement seen by Settings does not reach the root's cache.** `.proChecked(false)`
   updates the screen and reports nothing, so `isPro` stays true until the next launch. Refund-shaped.
6. **Reminders run dry after about six months** of not opening the app: 64 pending notifications is
   iOS's cap and rescheduling only happens on launch or on a change.
7. **The widget's month total and the list's headline answer different questions.** The list levels
   every cadence into "a month"; the widget shows this calendar month. They agree in a typical month
   and diverge whenever one is not — an annual charge landing, or a month with none. Labelling the
   widget with the month's name was proposed and never decided.
8. **A stray store sits in the App Group container** on the device — the one the app used for two
   hours before the path was pinned. Harmless, unread, and deletable by hand.
9. **`isPro` is forced true in DEBUG.** `BadeRootView.isPro` answers yes in a debug build, because a
   local StoreKit config only works when Xcode launches the app. The real entitlement is still
   tracked in `hasEntitlement`. It means **the locked states cannot be seen on a debug build**.
10. **The `.storekit` config lives in `BadeTests/`.** The app target is a synchronized folder, so a
   file placed beside the app is copied into the shipped bundle — pricing config included. The
   scheme's `StoreKitConfigurationFileReference` points at it there. Odd home, deliberate reason.
11. **No VoiceOver pass has ever been done.** Elements are labelled and combined; nobody has listened.
12. **Snapshot tests need a simulator**, which is not wanted here, so UI regressions are caught by eye.
13. **The end-to-end run** the user asked for has still not happened.
14. **Detection still finds far less than the statements contain, and the lapse rule is now the
   binding constraint.** In the largest TBC statement, 14 merchants charge 3+ times in a category
   that can recur; **1** becomes a subscription, **4** resolve a clean cadence and are then dropped
   as lapsed, and 12 are rejected outright. The lapse rule is doing what it was written to do —
   a subscription whose charges stopped is not current — but it means every cancelled subscription
   vanishes rather than being reported as ended. **Whether an ended subscription should be shown as
   ended is a product decision**, and it is the next real lever, ahead of any further cadence work.

### The widget

Built although §13 of the spec lists widgets as out of scope for v1, because the Pro page sells them.
`Widgets` holds the snapshot, the timeline and the views; `BadeWidget/BadeWidgetBundle.swift` is an
eight-line shell in the extension target, so everything real stays previewable in the package.

- The app publishes a **snapshot** — this month's total, what is still to come, the next three
  charges, the display currency, the app's locale and `isPro` — into the App Group container. The
  widget decodes it and computes nothing: no SwiftData, no rates, no StoreKit in that process.
- Published from `.task(id: widgetKey)` on `currency | language | isPro | reload`, **and** from
  `store.changes()`, so an edit made deep inside a feature reaches the home screen.
- The hero is **this calendar month**, matching the Upcoming tab, not the levelled "a month" the
  list shows. Only a real month can be half spent, which is what the bar means.

### Cadence is fitted to a phase, not chained from gaps — a deliberate spec deviation

**Spec §7.3 step 2 says "compute day-deltas between consecutive charges" and step 3 clusters those
deltas into windows. `CadenceResolver.timelineCadence` no longer does that**, and the spec has not
been amended. Update §7.3 or record the exception.

A chain of deltas breaks on one late charge, and a subscription billing on the 31st produces gaps of
28, 31 and 32 from the calendar alone. `timelineCadence` instead fits charges to a phase: projections
are measured from a fixed anchor (every charge is tried as the anchor, since a trial or off-cycle
first charge would throw them all out), and a charge counts when it lands within a few days of a
projection **no other charge has taken** — which is what stops a burst of same-day charges reading as
a rhythm. 80% must be on rhythm, so at four charges all four must be; the allowance opens at five.

`CadenceResolver.cadence` — the majority vote over deltas, used per cluster once the grouper has
settled — is **unchanged**, and `Cadence.approximateDays` still serves it. Replacing that one too
merged Apple's one-off purchases into its subscription and lost MAGTICOM; the two functions answer
different questions at different call sites.

**What it actually bought:** on the three TBC statements, the subscription count did not move
(0, 0, 2). Two timelines in the largest now survive the grouper intact where none did before, but
both are dropped later as lapsed. The one user-visible gain is that Spotify's history is complete —
five occurrences instead of four, with the trial recorded as a price change from 2.49 to 2.99, which
is spec §7.6's trial-to-paid case working on real data for the first time. No regressions anywhere.

### Decided against

**Tier 2 normalization (step 9) is not planned.** Built, measured, and left on the local branch
`tier-2-normalization` (commit `d85f7c1`, never pushed): 0.23s per line at best, 128 lines
qualifying, 79 of them worthless one-offs. Do not rebuild it as it stands. If merchant names are
ever worth improving again, it wants a different shape — a batch pass over an import rather than a
per-line call, or a bundled table rather than a model.

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
- **Only `Google One` and `LTD KEEPZ.ME`** have ever been detected by interval at annual and
  semiannual cadence. Everything else annual is a single catalog-matched charge.

---

## Working with this user

- **Show it running on the device before committing.** Build → install → launch → *then* ask.
  The simulator is not wanted: device only, paired over WiFi.
- **Never commit without asking.**
- **Ask about UI behaviour per screen**, and batch the questions before a long build rather than
  interrupting through it. They will interrupt mid-turn with corrections; read those carefully.
- **They will question the code and the numbers, and they are usually right.** The invented sticker
  price, the arrows that did not work, the haptic that re-fired — all found by them, not by tests.
- **Offer options before building anything visual.** Three or four genuinely different directions
  with a recommendation, not variations on one. That is how the Pro lock was designed.
- **Verify claims before making them.** Check `Bade.debug.dylib`, not the thin launcher, and prove
  a fix rather than assert it. When something is claimed to be flaky, run it ten times.
- **They will cut scope hard once they have seen it.** Three candidate chimes became one, and the
  debug button that auditioned them was deleted the moment it had done its job. Build the scaffold,
  expect to remove it.
- **They will take a recommendation or reject it outright, and either way it is settled.** The price
  is ₾24.99 against advice; the secret unlock path was abandoned in favour of promo codes after one
  sentence of pushback. Say the concern once, then build what was asked.

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
- **The app's own state can be read off the phone**, which settles arguments about what it thinks:
  ```sh
  xcrun devicectl device copy from --device $D --domain-type appDataContainer \
    --domain-identifier com.khvedelidze.Bade \
    --source Library/Preferences/com.khvedelidze.Bade.plist --destination ./prefs.plist
  xcrun devicectl device info files --device $D --domain-type appDataContainer \
    --domain-identifier com.khvedelidze.Bade --subdirectory "Library/Application Support"
  ```

---

## Verifying anything

```sh
cd BadeKit && swift test          # 469 tests, ~2s here, ~0.7s without the statements
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

`CoreData: error:` lines during a test run are expected: `StoreRecoveryTests` deliberately writes a
corrupt store to prove the recovery path. The run still passes.

---

## Traps hit, so they are not hit again

- **An App Group moves the SwiftData store.** CoreData's default directory becomes the group
  container the moment an app has one, so adding the widget's entitlement silently relocated the
  store and left the data behind — on an existing install that reads as every subscription
  vanishing. `SubscriptionStore.storeURL` pins the path to the app's own container. Never let the
  store's location be decided by an entitlement.
- **A next charge date is only true until it is not.** `nextChargeDate` is computed against the
  statement, so a statement ending on the 7th leaves a charge due the 10th sitting in the past by
  the 13th. Read it through `Subscription.nextCharge(onOrAfter:)`, never raw.
- **Projections reach back to the start of this month, and no further.** A charge due after the
  statement ended but before today belongs to neither half otherwise, and the month on screen ends
  up with a hole where a charge plainly happened. Older months stay as recorded.
- **No localised string resolves outside an app bundle.** In `swift test` on the host, `pro.title`
  comes back as `"pro.title"` — pre-existing, and true of every key. Test the *choice* of resource
  (`LocalizedStringResource` is `Equatable` and compares interpolated arguments), never the resolved
  text. `ReminderText.titleResource(for:)` exists for exactly this reason.
- **`UNNotificationSound` only looks in the app bundle root** and `Library/Sounds`. A file in a
  SwiftPM resource bundle is invisible to it, which is why `bade-chime-rise.wav` lives in `Bade/`.
- **iOS holds its notification delegate weakly.** `ReminderTaps` is kept alive by the root's
  `@State`; drop that and taps stop arriving with no error anywhere.
- **`Bade/` is a `PBXFileSystemSynchronizedRootGroup`.** Files dropped into the folder join the app
  target automatically — no Xcode step, no `.pbxproj` edit — and are copied into the bundle, which
  is why dev-only files must live elsewhere. Removing one cleans it out of the bundle too.
- **`UNUserNotificationCenter` is not `Sendable`.** Fetch `.current()` per call; storing it breaks
  a `Sendable` struct under strict concurrency.
- **SwiftData registers stores process-wide.** Two suites building containers at the same instant
  segfaulted the run about once in eight. `TestContainers` serialises creation only; 12 consecutive
  runs are clean.
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
- **A readout under a chart is under a hand.** Scrub readouts go above the plot; axis labels stay
  below.
- **`confirmationDialog` anchors to whatever triggered it.** Use `.alert` for destructive confirms.
- **A grouped `List` reserves top space for a header it does not have.** `contentMargins(.top,
  .zero, for: .scrollContent)` removes it.
- **`drawHierarchy` renders nothing for a window that was never on screen**, and such a window
  never runs SwiftUI's appearance lifecycle either — ask the layer tree directly and drive loads by
  hand.
- **SourceKit in this repo reports "No such module" for every new file.** Stale index, not a real
  error. `swift build` is the truth.
- **The BOG parser flattens all whitespace before matching**, so line wrapping is already handled.
- **`some Sequence` has no `first` property.** Returning an opaque `Sequence` from a helper and then
  writing `.first != nil` binds to the unapplied `first(where:)` *method*, which is never nil — so
  the guard was always true and `canParse` silently degenerated to its cheap half. It compiles, with
  a warning that is easy to miss because an incremental build does not re-emit it. Return
  `some Collection` when the caller needs `first`, and read the warnings on a forced rebuild.
- **`Decimal`'s `description` drops a trailing zero**: `15.20` renders as `15.2`, which a
  two-decimal grammar rejects. Rendering money for a fixture wants
  `.formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(.init(identifier: "en_US_POSIX")))`,
  never string interpolation.
- **Measuring a gate is not measuring the outcome.** A probe showed a new cadence test accepting
  three timelines the old one rejected, which was reported as "roughly +3 subscriptions". The real
  answer was **+0**: passing the grouper's gate says nothing about surviving lapse and confidence
  afterwards. Measure end to end, at the number a user would actually see.
- **A computed `static var` that opens PDFs re-opens them on every access.** Six local tests reading
  four megabytes each turned a 0.7s suite into 5.2s. `static let` fixed it.

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
