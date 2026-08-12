# Next session — start here

Read `CLAUDE.md` first for the working agreement, constraints and UI conventions.
This file is the handoff: where the project is, what is next, and what is still open.

Last updated: **2026-08-12**, end of "Bade part 3".

---

## Where it is

**Build-order steps 1–8 are done.** Five screens were built or reworked in part 3, all of them
run on the device, and the user has reviewed the UI once and had their first round of changes
applied. Everything is committed. **End-to-end testing against a real statement is the next task.**

```
PDF → Ingestion → Normalization → Detection → Persistence → UI
   835 transactions → 11 subscriptions → ₾510/month, nothing unconvertible
```

**347 tests, `swift test` ~0.7s, no simulator needed. iOS build green, no warnings.**

### Screens

| # | Screen | State |
|---|---|---|
| ① | Welcome | ✅ its "Add manually" button is now wired |
| ② | Parsing | ✅ |
| ③ | Review | ✅ three confidence tiers |
| ④ | Subscriptions | ✅ now also `+`, and Edit on swipe and long-press |
| ⑥ | Detail | ✅ now also Edit in the toolbar |
| ⓜ | Manual entry / Edit | ✅ five entry points, reviewed |
| ⑤ | Upcoming + TabView | ✅ tiles, day selection, swipe, history |
| ⑩ | Settings | ✅ currency, language, appearance, text size, week start, export |
| ⑨ | Bade Pro | ✅ the pitch; purchasing is still step 13 |
| ⑦ | FX breakdown | blocked on §8 NBG rates |

### Commit state

Everything is committed on `main`, in eight reviewable commits: identity and merging · merchant
suggestions · shared groundwork · manual entry · Upcoming and the tab bar · Settings and Pro ·
the snapshot harness · docs. **Not yet pushed.**

They are review units, not bisect points. `Package.swift` declares the Upcoming, Settings and
Snapshot targets in the groundwork commit, before the sources for them land, so the intermediate
commits do not each build on their own. Only the final tree was verified.

---

## What part 3 built

### ⓜ The form — one screen, five ways in

`Subscriptions/Form/`, nested beside `Detail/` rather than its own module: Detail and the list
present it directly, so saving reuses the `.saved` machinery that already existed. Welcome reaches
it through App, which is the only place that knows both.

Entry points: `+` on Subscriptions · Edit in Detail's toolbar · Edit on the leading swipe (behind
Cancel, so a full swipe still means what it always did) · Edit in the long-press menu · Welcome's
"Add manually".

Decisions taken, all the user's:

- **Identity is frozen at creation.** `SubscriptionRecord.update(from:)` no longer rewrites
  `matchKey`, so renaming a subscription cannot hide it from the next import of the same statement.
  This exposed a second bug: `merging` took the merchant from whichever side was newer, which would
  have silently undone the rename. It now keeps the stored name.
- **`matchKey` folds the merchant** to letters and digits, so a typed "netflix " and a detected
  "Netflix" are one subscription. `MerchantName` moved from Catalog to Core so the catalog and the
  identity cannot drift apart on what "the same name" means.
- **A hand-entered subscription has no history.** `charges` stays empty; its first and last charge
  dates are derived from the next charge minus one period, purely so the FX lookup has a date.
  A subscription that *has* charges keeps the dates they gave it, whatever the form does.
- Confidence is `.confident`. Editing an amount does **not** write a `PriceChange`.

### ⑤ Upcoming + the TabView

A month grid where a day that costs something is a filled tile and today is the one tile in the
accent colour, with that month's charges listed by day underneath. Tapping a day narrows the list
to it; swiping or the arrows change month. Tabs are Subscriptions · Upcoming · Settings; Welcome
still has no tab bar and import still covers it.

- **What fills a month depends on where the month is.** Up to today it is what a statement
  recorded, at the price actually billed; after today it is the rhythm projected forward. The split
  is the start of today, so a charge due today is not lost by both halves.
- **Nothing is ever projected backwards.** A past month Bade never saw stays empty rather than
  being filled with charges nobody can vouch for.
- **A stale next-charge date is rolled forward quietly** — lapse is judged against the statement's
  end, so an active subscription with an old date means the statement is old.
- **`UpcomingView` is generic over what a row opens.** Detail is in another module, so App supplies
  the destination.

### ⑩ Settings

Display currency (the shared picker), language, export, about, and delete-everything — which now
exists **both** here and on Subscriptions, as asked.

- **`BadeRootView` no longer hardcodes GEL.** Currency defaults to whichever one most subscriptions
  are billed in (`predominantCurrency`), falling back to the phone's locale, and is overridden by
  `@AppStorage` once Settings is used.
- **Language is an in-app locale override**, English or ქართული, which takes date and money
  formatting with it.
- **Export offers JSON and CSV** through a share sheet. `SubscriptionJSON` and `SubscriptionCSV`
  are pure functions in Core so a screen holding subscriptions can render them without re-reading.
- **`DesignSystem` now depends on `Localization`** so `CurrencyPicker` could move there and serve
  both the form and Settings.

### Bugs the tests caught while building

- **Month stepping loses the 31st.** Adding one month repeatedly from Jan 31 clamps to Feb 28 and
  never recovers, so a subscription billed on the 31st drifts to the 28th forever. Projection now
  measures every period from a fixed anchor. `Cadence.charge(after:periods:in:)`.
- **Detail opened from Upcoming had an empty `RateBook`**, so nothing would have converted. App
  now loads rates in `decideRoot`.
- **The tab bar broke `.task`-based reloading.** Both data tabs reload `.onAppear` instead, so an
  edit in one tab shows in the other.

---

## Read this before the end-to-end run

1. **The folded `matchKey` invalidates data already on the phone.** Stored rows carry unfolded keys,
   so a re-import after this change duplicates rather than merges. **Delete and reinstall before
   testing imports**, or the first result will look like a bug that is not one.
2. **The app name is still `Bade`.** The user chose `Bade.` with the period. It needs
   `Bundle Display Name` set in Xcode — it lives in the project file, which is not hand-edited.
3. **The user has UI comments outstanding** from their review, not yet collected or applied.

---

## Open items

1. **No SwiftData migration plan.** The schema has changed twice and `SubscriptionStore.container()`
   is behind `try!`, so a mismatch crashes on launch rather than degrading. **Must be solved before
   anyone else has data** — and see the `matchKey` note above.
2. **The test suite segfaults about one run in eight.** Parallel suites building SwiftData
   containers; the existing comment in `SubscriptionStoreTests` already names the cause. Part 3
   added a fifth such suite. `.serialized` only serialises *within* a suite, so the fix is either a
   shared lock around container creation in the test helpers or one parent suite spanning both files.
3. **Re-importing the same statement is silent.** It merges correctly and duplicates nothing, but
   nothing tells the user they have already imported this file.
4. **`ImportOutcome.foundNothing` has no screen.**
5. **Uncertain singles are contained, not fixed.** Seven look-alike Apple charges are still seven
   cards in Review.
6. **Spotify split into three subscriptions** on the old card. Decided to leave alone: §7.1 uses
   amount to separate concurrent subscriptions and changing it risks merging real ones.
7. **Every Georgian string is `needs_review`,** now including three screens' worth of new drafts.
8. **Notifications (step 12) have no Settings row yet** — deliberately, as there is nothing to
   link to. Bade Pro has its page and its row; only the purchase is missing.

---

## After the review

**§8 NBG rates** — worth pulling forward. Self-contained, depends on no screen, and unlocks
Detail's bank-markup row and the whole FX breakdown (⑦), the signature paid feature. The endpoint
is in memory as `nbg-fx-rate-endpoint`.

---

## What was learned about the data (do not re-derive)

- **The statement carries its own exchange rates.** `konvertatsia` / `Foreign Exchange. FX Rate:`
  rows hold both sides of the account holder's own conversions. Reading them means a statement
  needs **no network call** to be totalled in one currency. The rate is derived from the two
  amounts, never from the printed `FX Rate`, which is quoted lari-per-foreign whichever way the
  conversion went.
- **Rates are dated and accumulate** across imports, deduplicated by pair + day + rate.
- **The account is multi-currency.** A USD charge paid from a USD balance has no conversion
  because none happened. That is not missing data.
- **The two test statements are different cards**, ~18 and ~25 months, zero shared transactions.
  The old card's subscriptions all lapsed when the user switched cards around Dec 2025 — which is
  what validated the lapse rule (35 detections → 3).
- **Only `Google One` and `LTD KEEPZ.ME`** have ever been detected by interval at annual and
  semiannual cadence. Everything else annual is a single catalog-matched charge.

---

## Working with this user

- **Show it running on the device before committing.** Build → install → launch → *then* ask.
- **Never commit without asking.**
- **Ask about UI behaviour per screen** — buttons, states, transitions — rather than filling gaps.
  Batch the questions before a long build rather than interrupting through it.
- **They will question the code**, and the questions are usually right.
- **Designs are a starting point.** Implement what is drawn, then propose changes.
- Simulator is theirs to drive. Build and run tests; do not attach to the simulator.

---

## Running on the device

Paired over the network, no cable. Two different identifiers, confusingly.

```sh
# build
xcodebuild -project Bade.xcodeproj -scheme Bade \
  -destination 'platform=iOS,id=00008140-001A682611E2801C' -allowProvisioningUpdates build

# kill the running copy first — iOS otherwise keeps serving it
D=DBEB4346-E638-5BA5-AACF-50285C07B389
PID=$(xcrun devicectl device info processes --device $D | awk '/Bade.app\/Bade/{print $1}')
[ -n "$PID" ] && xcrun devicectl device process signal --device $D --pid "$PID" --signal SIGKILL

xcrun devicectl device install app --device $D \
  ~/Library/Developer/Xcode/DerivedData/Bade-*/Build/Products/Debug-iphoneos/Bade.app
xcrun devicectl device process launch --device $D --terminate-existing com.khvedelidze.Bade
```

- **Never pass `--console`** — it ties the app's lifetime to the session and killing it kills the app.
- *"Developer disk image could not be mounted"* means **the phone is locked**. Ask them to unlock.
- `xcrun devicectl list devices` showing **`unavailable`** means it is off the network, not locked.

---

## Verifying anything

```sh
cd BadeKit && swift test          # 347 tests, ~0.7s, no simulator
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

---

## Traps hit, so they are not hit again

- **A platform-varying `some View` does not survive a module boundary.** A `#if os(iOS)` helper
  returning `some View` compiled on macOS and failed on iOS with *"has no member"*, poisoning
  every modifier after it. Write platform shims as concrete `ViewModifier`s, as `badeAnimation`
  and `badeDecimalEntry` do.
- **`confirmationDialog` anchors to whatever triggered it.** From a swipe or a context menu it
  lands somewhere unrelated. Use `.alert` for destructive confirmations.
- **A `Button` as a list row fights its own swipe and long-press gestures.** Use plain content, or
  a `NavigationLink`.
- **A grouped `List` reserves top space for a header it does not have.** `contentMargins(.top,
  .zero, for: .scrollContent)` removes it; row insets cannot.
- **Never step a date one period at a time.** See the 31st bug above.
- **SourceKit in this repo reports "No such module" for every new file.** It is a stale index, not
  a real error — `swift build` is the truth.
- **The BOG parser flattens all whitespace before matching**, so line wrapping is already handled.

---

## Data handling — read before touching statements

Real statements live only in `statements/` and `BadeKit/Tests/Fixtures/local/`, both gitignored,
plus a blanket `*.pdf` rule.

- **Never commit one.** The repo is public and MIT-licensed.
- Statements contain **third parties** — other people's names and IBANs in transfer records. The
  user cannot consent on their behalf.
- A scrubber exists at `statements/scrub.py` (gitignored).
- **Verify, do not trust.** Compare merchant/amount/date frequency tables before and after.
- When probing real data, print **aggregates and merchant-level detail only** — never a raw line,
  never a counterparty. Delete scratch probes before committing.
