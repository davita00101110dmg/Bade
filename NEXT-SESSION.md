# Next session — start here

Read `CLAUDE.md` first for the working agreement, constraints and UI conventions.
This file is the handoff: where the project is, what is next, and what is still open.

Last updated: **2026-08-23**, during "Bade part 8".

---

## Where it is

**Every build-order step is done.** 1–8, 10, 11, 12, 13 complete; **9 measured and decided against**;
**14 written and awaiting the one review only a native speaker can give**.

**A purchase has round-tripped.** Bought in a TestFlight sandbox build, and all six gates flipped —
Upcoming, the FX card, export, reminders, the Pro row's tick, the widget. That was the single largest
unverified thing in this project for months and it is closed.

**§10 is finished, and the answer inverted the question.** See §The FX markup was fabricated.

```
PDF → Ingestion → Normalization → Detection → Persistence → UI
   BOG  main card  → 22 detections: 8 confident, 1 probable, 2 unsure, 11 ended
   BOG  other card → 28 detections: 1 confident, 1 probable, 2 unsure, 24 ended
   TBC  770 transactions → 6 subscriptions (the largest of three)
```

**545 tests, `swift test` ~2s** — and they pass without the private statements too, which was not true
before both banks had a committed fixture. Plus **57 snapshot references** on the simulator, ~140s;
see §Snapshot tests. iOS build green, no warnings. Quality gates clean bar one pre-existing `"GEL"`
in `Catalog/MerchantSeed.swift:395`, a bundled price point rather than an assumption in logic.

**`CURRENT_PROJECT_VERSION` is 2, on the app *and* the widget.** Caught in between: the app was
bumped first and the extension left at 1, which the iOS build reports only as a warning and App Store
Connect rejects at validation. Both are 2 now and the build is clean. `BadeTests` and `BadeUITests`
stay at 1; they never ship. **An extension's version must always move with its host.**

**The home screen name lost its full stop** — `INFOPLIST_KEY_CFBundleDisplayName` is `Bade`, not
`Bade.`. Note that `app.name` still resolves to `Bade.`, so the icon says one thing and the launch
wordmark says another. Decide them together, or drop the wordmark (see §The launch screen).

⚠️ **Everything since the last upload is not in TestFlight.** The build there predates the
presentation fix, the tooltips, the currency restriction, the Settings restructure, the FX
correction, the owned Pro page, both field limits, the delete confirmation, Increase Contrast and
the new launch screen.

### Screens

| # | Screen | State |
|---|---|---|
| ⓛ | Launch | ✅ wordmark rises, the stop springs in after it; the root waits for it to finish |
| ① | Welcome | ✅ language globe top right — Settings is unreachable until something is imported |
| ② | Parsing | ✅ BETA badge, "Opening the file" + sweeping bar, rows land in a spring |
| ③ | Review | ✅ one checkbox per row; header counts what is ticked |
| ④ | Subscriptions | ✅ merchant colours, decimals on the hero, total follows the scroll, pull for the web |
| ⑥ | Detail | ✅ bars grow in, FX in a sentence behind the Pro lock |
| ⓜ | Manual entry / Edit | ✅ five entry points |
| ⑤ | Upcoming + TabView | ✅ Pro-locked; dots weighted by money, hollow when cancelled |
| ⑩ | Settings | ✅ Pro rows are absent without Pro rather than badged |
| ⑨ | Bade Pro | ✅ five features, all of which exist |
| ⓡ | Reminder prompt | ✅ asked once, after the first import, Pro only |
| ⑦ | FX breakdown | ▲ **a plain sentence; the money figures are still withheld — see below** |
| ⓦ | Widget | ✅ small and medium, net behind both states, locked tile shows a redacted figure |

### Teaching the gestures — new, outside the build order

Decided on 2026-08-22 against onboarding screens and against coach marks over every page. **Nothing
is taught up front and nothing is dimmed.** What is actually undiscoverable here is a handful of
gestures, not the idea.

An earlier attempt used a quiet inline line that only left once the gesture was performed. On a
phone it read as furniture and would not go away while browsing, so it was replaced by **TipKit**:
a popover with an arrow, anchored to the thing itself, with three ways out — close it, perform the
gesture, or tap elsewhere.

`DesignSystem/BadeTip.swift` holds the two tips and `BadeTipStyle`. `Tips.configure` is called once
from the root, pinned to `.applicationDefault` — never the App Group, because a framework choosing
its own store location is exactly how the SwiftData store silently moved.

| Where | Anchored to | What it says | Retired by |
|---|---|---|---|
| ④ Subscriptions | the first row | Swipe a row to edit it or mark it cancelled. | any of the three row actions, by swipe or long press |
| ⑤ Upcoming | the first day of the month that costs something | Tap a day to see just that day. | selecting any day |
| ③ Review | under the header — a permanent line, not a tip | Only what Bade was sure of is ticked. Tick anything else you recognise. | **never** |

**The style carries the palette and the language as values**, read in the presenting view rather
than through the environment. A tip is system-presented in its own popover, and presented content
inherits nothing — the same boundary that once ran the whole import flow in English.

**One bug found on device and fixed here.** The ④ tip appeared on first entry and dismissed itself a
second later, then behaved on every later visit. The hero total counts up for `BadeMotion.totalReveal`
and writes `hasArrived` back to the screen when it lands, which re-renders the list and takes the
anchor out from under the popover. On a later visit `.task(id: total)` never re-runs, which is why it
looked like a first-entry-only fault. The tip now waits for that write.

The Review line is not a tip and has no storage. `ReviewDecision(startingFrom:)` ticks only
`.confident && !hasEnded`, so on the second BOG statement that is **1 ticked against 27** — an empty
box reads as a verdict Bade reached rather than the question it is. True of every import, which is
why it never goes away.

**Deliberately not taught:** the pull-net (it does nothing) and the five-tap money rain (it is meant
to be found).

**Watch on device:** the ④ hint lives inside the rows' `ForEach`, keyed to whichever row is first,
so changing the sort removes and reinserts it during the same animated batch update that open item 0
already misbehaves in. It has not been seen on a phone yet. If it flickers, the fix is to lift it out
of the `ForEach` and give it a fixed position in the section.

---

## Do this first

**The Georgian review.** It is the last thing standing between the app and a submission, and it is
the one thing nobody else can do. `GEORGIAN-REVIEW.md` has the whole pass — six decisions to accept
or reject, two grammar bugs, every key either way, and a snippet at the foot that flips all the
states in one run.

The document is **12 keys stale**: written against 227, the catalog now holds **239 — of which 223
are still `needs_review` and 16 are translated** (counted 2026-08-23). Everything added since is
listed in git and none of it was part of the pass. Ask for it to be regenerated rather than reading
around the gap.

⚠️ **Re-record the snapshot references afterwards.** Eleven of the fifty-seven are Georgian, so a
translation pass fails them by design. `rm -rf Tests/Fixtures/Snapshots` and run the suite once.

---

## The FX markup was fabricated

The question that blocked §10 for weeks — which side of the conversion the amount was denominated in
— had a wrong premise. One statement row settled it:

    Payment - Amount: GEL14.99; Merchant: SETANTA.COM, United Kingdom; MCC:5734;
    Payment transaction amount and currency: 14.99 GEL;
    Card scheme conversion rate (USD-GEL): 2.5979; Bank conversion rate (USD-GEL): 2.6371

Setanta costs 14.99 GEL and 14.99 GEL left the account. **Nothing was converted.** The rates are
printed because the merchant is abroad and the scheme settles through dollars, but the amount was
fixed in lari, so that spread never touched the cardholder.

Bade divided 14.99 by the bank's rate into a $5.68 sticker nobody was quoted, multiplied back at the
scheme's, and reported the difference as a loss. **The "consistent 1.3–1.5% markup" recorded here as
a finding about the bank was `(bank − scheme) / scheme`** — a property of the two rates and nothing
else, which is exactly why it was so reliable.

Counted across the committed fixture, all 327 payment records:

| | Charged | Rates printed | Result |
|---|---|---|---|
| 222 | GEL | none | nothing to report |
| 50 | EUR | none | no conversion happened |
| 33 | USD | none | no conversion happened |
| 22 | GEL | USD-GEL | `GEL ≠ USD` → not converted |

**Not one record has `currency == conversion.from`.** `Charge.wasConverted` now decides — a
conversion applies only when the charge is denominated in the currency being converted *from*. The
rates still feed the rate book, because a USD-GEL rate is worth having; only the claim that it cost
somebody something is gone.

**The 22 were re-tested rather than trusted**, since the whole correction rested on the single
Setanta row. If they had really been converted from dollars, dividing the lari back by the bank's
rate should recover clean dollar stickers. **None of the 22 does**; 8 are clean lari prices and 14
are messy in both directions. The fix is right on this data.

**Why the foreign charges are silent — and why that is not the feature failing.** The 83 USD and EUR
charges print no rates *at all*, because this account is **multi-currency**: a euro charge came out
of the euro balance and nothing needed converting. Bade says so in words rather than showing a zero
(`detail.fx.noConversion`: *"Paid straight from your %@ balance, so nothing was converted and there
is no markup."*).

⚠️ **An earlier version of this note concluded the feature "has nothing to report on real
launch-market data". That generalised one account too far.** The silence is caused by holding foreign
balances, not by the card being Georgian. **A GEL-only account — the common Georgian card — is
exactly the case that fires**: no dollar balance, so the bank must convert, prints the charge in USD
beside USD-GEL rates, `currency == from`, and the markup is real. **No statement in `statements/`
is such an account, so that path has never been exercised on real data.**

The one risk left in it: if BOG denominates a *converted* charge in GEL (`Amount: GEL27.12` beside
USD-GEL rates) rather than in USD, that row is indistinguishable from the Setanta shape and Bade
would stay silent when it should not — a false negative. The 22 rows argue against it happening, but
this account cannot produce the case either way. **One statement from a card with no foreign-currency
balance settles it.**

**Decided 2026-08-23: the feature stays as built.** It is correct, it explains itself when there is
nothing to report, and it pays off for single-currency accounts. No change to the engine.

**The Pro page's copy was wrong, though, and was fixed the same day.** It sold the feature on
*foreign* charges — `pro.fxDetail` "on every foreign charge", `pro.fxWhere` "On any charge in another
currency" — which is exactly the promise this account cannot keep: a euro charge is a charge in
another currency and the card says nothing was converted. Both now say **converted** instead, in
English and Georgian. Everything under `detail.fx.*` was already right; only the page that sells it
had drifted, which is the more dangerous half to get wrong.

## Waiting on the user

- **The Georgian review.** Above.
- ~~**The reminders cap.**~~ **Settled 2026-08-23: accepted as is.** Above about eight subscriptions
  iOS's 64 pending notifications runs out in 5.7 months, and no local scheduling beats it.
  `BGAppRefreshTask` helps least for the only user who has the problem — the one who never opens the
  app — and repeating calendar triggers would break the day-grouping that makes three charges on one
  day a single notification. The horizon stays at three years and the app reschedules whenever it
  runs. Revisit only if TestFlight turns up real users above eight subscriptions.
- ~~**The FX feature's future.**~~ **Settled 2026-08-23: it stays as built.** It is silent on this
  multi-currency account because nothing was converted, and it fires on a GEL-only card. Worth having
  is **one statement from an account with no foreign-currency balance**, to exercise that path on real
  data for the first time — a nice-to-have, not a blocker.
- **Screenshots.** Never taken. An iPhone 16 Pro is 1206 × 2622, which Apple does not accept — use an
  iPhone 16 Pro Max simulator (1320 × 2868). Not needed for TestFlight, only for submission.
- **The App Store name.** "Bade." was taken as a fallback because "Bade" was gone. Editable until you
  submit; the subtitle is the field carrying the search weight.
- **The Georgian wordmark.** `app.name` ships as "Bade." in both languages. *Bade* is ბადე, the net
  the app is named for, so whether the Georgian build shows the Latin wordmark is a branding call.

### Done in App Store Connect

App record created, Paid Apps agreement active, IAP `com.khvedelidze.Bade.pro` created and in
*Prepare for Submission*, App Privacy answered "Data Not Collected", six accessibility labels
declared (VoiceOver, Voice Control, Dark Interface, Larger Text, Reduced Motion, Differentiate
Without Colour Alone), listing copy written, age rating 4+, category Finance.

**Sufficient Contrast can now be declared too — built 2026-08-23, see §Increase Contrast.** It is
the seventh label and the only one that was ever a missing feature rather than an untested one.

`privacy.html` and `support.html` are served from the repository root through GitHub Pages. Every
claim in the policy was checked against the code rather than written as boilerplate — the network
paragraph says what is actually on the wire, which is a date and nothing else, not even the currency.

**Offer codes do not apply.** They are subscription-only; Bade Pro is a non-consumable. Free access
for friends is TestFlight now, where sandbox purchases cost nothing, and App Store promo codes once
the app is approved.

### Xcode, done

Widget device family narrowed to `1` to match the app — an extension's family must be a subset of its
host's or validation rejects the upload. `ITSAppUsesNonExemptEncryption = NO` set. Verified in the
built Release plist, along with zero occurrences of the debug Pro symbols and no `.storekit` config
in the bundle.

An earlier version of this note claimed the *app* target needed narrowing. It did not — those values
belong to `BadeTests` and `BadeUITests`, which never ship. Attribute a build setting to its target
before believing it.

⚠️ **The debug Pro padlock is gone**, with `debugLocksPro` and `ProLockToggle`. `isPro` is
`hasEntitlement` in every configuration now, so **a Debug build shows the locked state** unless a real
entitlement exists. All local testing before this silently ran with Pro on. To look at a gated screen
without TestFlight, force `isPro` behind `#if DEBUG` — and take it out again, uncommitted. It lost its
guard once during this session and would have shipped free Pro to everyone.

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

### The golden fixtures

**Both banks have one now.** `Tests/Fixtures/bog-statement-01.txt` is derived from the full BOG
statement: 326 real records with real dates, amounts, currencies, MCCs and conversion rates. 132
merchants became `MERCHANT###`; 109 charges at brands the catalog already ships survive by name.
The three `PAYPAL *SPOTIFY*` reference strings are among them deliberately — folding those into one
subscription was a failure only real data ever exposed, and until now only a local statement proved
it stayed fixed.

**A brand is public; the branch it was bought at is not.** BOG appends either a country, which
identifies nobody, or a city and street, which says where somebody shops — two survived the first
pass as full addresses before it was caught. 62 address tails were trimmed, and `namesNoBranchAddress`
keeps it that way.

Why it mattered: every BOG suite is gated on `Fixtures/local`, which is gitignored, so **the launch
bank's parser had no test that survived leaving this laptop** — not on another machine, not in CI.
Verified by hiding `Fixtures/local` and running: 527 tests still pass, `BOG golden fixture` among
them.

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

0. ~~The sort label on Subscriptions clips when it changes.~~ **Fixed, 2026-08-22, structurally.**
   The control is in the toolbar now, as an `arrow.up.arrow.down` menu beside import and add. The
   cause was the `List` remeasuring its own section header during the same animated batch update
   that reorders the rows, so nothing *inside* the list could ever have been safe — which is why
   `.fixedSize()`, a nil transaction and `.contentTransition(.identity)` all did nothing. Out of
   the list, the list cannot touch it. The trade is that the current order is no longer legible at
   a glance; the tick inside the menu says it instead, and the button carries it as an
   accessibility value.

1. **Decided against for now, 2026-08-22 — but the code still computes them.** A screen to ask
   about candidates was scoped and deliberately not built. The cost is below and is real: roughly
   half of what the engine noticed is discarded at the last step. Revisit after TestFlight, when
   there is evidence about whether anybody notices the gap unprompted.

   **The repeat candidates are computed and nothing shows them.** `SubscriptionDetector.analyse`
   reports merchants charged 3+ times in a recurring-capable category that no cadence explained;
   they reach `ImportResult.candidates` and stop. The gap is the argument for building the screen:
   11 candidates against 22 detections on one BOG statement, **16 against 28** on the other — where
   only a single detection was confident — and 8 against 6 on the largest TBC one. Asking is the
   only honest way to close it, since the engine looked and found no rhythm.
2. **`matchKey` folds the merchant**, so rows stored before that change no longer match. **Delete
   and reinstall before testing an import**, or a re-import duplicates instead of merging and looks
   like a detection bug.
3. **Seven look-alike Apple charges are still seven rows** in Review's "Not sure" tier.
4. **Every Georgian string has now been read in context** — 229 keys, 50 revised, still all
   `needs_review` because only a native speaker's yes should flip them. `GEORGIAN-REVIEW.md` has the
   whole pass: six decisions to accept or reject, two grammar bugs, and the snippet that marks it
   done. Nothing else in step 14 is outstanding.
5. ~~A revoked entitlement does not reach the root's cache.~~ **Fixed.** `.proUnlocked` became
   `.proChanged(Bool)`, so Settings reports both answers; the root stores it and reschedules either
   way, which also clears reminders iOS is still holding. Three tests.
6. **Reminders still run dry, but only for heavy users.** The horizon was a year while the cap is 64,
   and for anyone with five or fewer subscriptions the *horizon* was what ran out first — one monthly
   subscription filled 12 of the 64 slots, an annual one filled 1. Three years now, measured: 1 sub
   11.6 → 35.6 months, 2 subs 11.6 → 31.6, annual-only 0.7 → 24.7. Above ~8 subscriptions the cap
   binds and nothing changed: 5.7 months, and no code can beat iOS's 64. Closing that needs a
   decision — `BGAppRefreshTask` (an entitlement and your Xcode work, and iOS never promises to run
   it), repeating calendar triggers (exact for monthly and annual, but they cannot carry the
   day-grouping, so quarterly charges sharing a day would announce wrongly), or accept it.
7. **The widget's headline and the list's answer different questions.** The list levels every
   cadence into "a month"; the widget shows what is left of this calendar month. Both are right and
   they diverge whenever a month is not typical.
8. **A stray store sits in the App Group container** on the device — the one the app used for two
   hours before the path was pinned. Harmless, unread, and deletable by hand.
9. **The `.storekit` config lives in `BadeTests/`.** The app target is a synchronized folder, so a
   file placed beside the app is copied into the shipped bundle — pricing config included. The
   scheme's `StoreKitConfigurationFileReference` points at it there. Odd home, deliberate reason.
10. **A VoiceOver pass has now been done by reading, not by listening.** Seven real gaps found and
   fixed: the progress bar announced a percentage and never what of; the monthly total combined its
   children and then overrode the label, so the app's biggest number read as bare money with the
   year, the count and the "not converted" warning all silently dropped; every calendar tile read as
   a bare number because the dots are shapes; no section heading anywhere carried `.isHeader`, so the
   rotor had nothing to jump between; the locked widget announced its fake "000.00" as this month's
   total; and three decorative SF Symbols read their own names into combined labels. Two keys were
   added (`common.progress`, `upcoming.dayCharges`).

   **And then heard, on 2026-08-22.** Walked on the device against a checklist covering all seven
   fixes plus the things never verified: the headings rotor, swipe actions reached through the
   actions rotor, the tooltips, the checkboxes, how money is spoken. Everything read correctly.
   A three-finger scroll failure reported during the first pass did not reproduce and is closed —
   it was an older build or the gesture itself.

   **So VoiceOver can be declared** in App Store Connect's accessibility labels, alongside Dark
   Interface, Larger Text, Reduced Motion and Differentiate Without Colour Alone. **Voice Control
   has since been tried and works**, and **Sufficient Contrast was built on 2026-08-23** — see
   §Increase Contrast. **All seven labels are declarable.**

   What remains open: iOS has no Georgian
   VoiceOver voice, so a Georgian reader hears Georgian text spoken by an English voice — Apple's
   limit, not Bade's, but worth knowing before promising anything to Georgian users specifically.
11. ~~Snapshot tests.~~ **Real, 2026-08-22.** Ten screens × four variants, plus two empty states:
   42 references committed under `Tests/Fixtures/Snapshots` (3.6 MB), compared pixel-wise on every
   run. See §Snapshot tests below for how to run and re-record them.
12. ~~The end-to-end run, and §14.7's cold start.~~ **Both done, 2026-08-22.** Run on the device
   from an empty state, and the monthly total was reached in under sixty seconds. §14.7 is
   satisfied by measurement rather than by assumption. The figure itself was not recorded, so if a
   margin ever matters, time it again.
13. **Detection reports far less than the statements contain.** Ended subscriptions are now shown
   as ended rather than dropped, which recovered several; the remaining gap is the repeat candidates
   in item 1.
14. ~~Import stops working after presentations collide.~~ **Fixed structurally, 2026-08-23.**
   `BadeRootView` drove a file importer, a cover, three sheets and two alerts from seven independent
   booleans, over a root that can swap between Welcome and the tabs while any is open. Two could be
   asked for at once, SwiftUI dropped the loser without saying so, and the loser's flag stayed set —
   after which every request set `true` to `true`, which is not a change, so nothing presented ever
   again until relaunch.

   One `Presentation?` now, so two at once is unrepresentable. `present` dismisses what is up, waits
   350ms, then presents; and asking for what is already showing works deliberately, because that is
   the recovery path if a presentation is ever dropped.

15. **Nothing bounds a pasted amount's *value*, only its shape.** Six digits and two decimals, so
   999999.99 is the ceiling. Fine for a subscription; there is no guard against someone entering it
   deliberately and skewing their own total.

16. **The FX card is silent on the statements here, and that is correct.** Nothing was converted on
   a multi-currency account, and the card says so in words. It fires on a GEL-only card, which no
   statement in `statements/` is — so that path is covered by tests but has never run on real data.
   See §The FX markup was fabricated. **Decided 2026-08-23: keep as built.**

### Increase Contrast — built 2026-08-23

`BadeColorPair` carries four values now instead of two, and the raised pair defaults to the standard
one so a colour states a second only where raising it is deliberate. `BadeTheme.init(scheme:contrast:)`
resolves them, and `BadeThemeModifier` reads `\.colorSchemeContrast` — as do the two places that
build a theme outside the view tree, the tip popover and the widget's container background.

**The values were solved, not chosen.** Text to 7:1, with `inkMuted` pulled to 8.5:1 so the ink
hierarchy survives being raised — at a flat 7:1 target `inkMuted` and `inkFaint` came out two shades
apart and the muted/faint distinction collapsed into one grey. Borders take 3:1, the floor for a
meaningful boundary; at 1.09:1 a card's edge was decoration.

**The find along the way: `warning` in light measured 3.60:1 — under the AA floor at *standard*
contrast.** It has been the weakest colour in the palette all along, and nothing tested it, because
the existing suite checked ink, muted ink, accent and faint ink and never the semantic colours. Its
raised value is 7.01:1; the standard value is untouched and still under the floor, which is a
separate decision about the normal palette and is **not** closed.

`IncreasedContrastTests` holds all of it: every colour against its target, a guard that raising can
never *lower* contrast, and that standard contrast still resolves to exactly the old values — the
raised palette leaking to everyone would be invisible in a unit test and obvious on a phone.

**A fifth snapshot variant** (`increased-contrast`, 10 screens, 52 references now) proves the wiring
end to end. `ColorSchemeContrast` is read-only in the environment, so the variant overrides
`traitOverrides.accessibilityContrast` on the host — which is the honest test, since it drives the
real system signal rather than injecting a value. Checked that the new references actually differ
from their `-light` counterparts: all of them do. A passing suite where the override silently did
nothing would have been the same false proof the font change gave last time.

**One exception, deliberate.** The merchant avatars — the tinted circles with an initial — come from
`BadeMerchantColour`, a hue derived from the name with fixed saturation and brightness, not from the
palette. They do not respond to Increase Contrast. Defensible because the letter is redundant: the
merchant's name is in full ink immediately beside it, so nothing is conveyed only by that circle.
Worth raising if anyone asks; it is one call site (`SubscriptionListRow.swift:90`).

### The launch screen — rebuilt 2026-08-23

`DesignSystem/BadeLaunchSurface.swift`. The wordmark rises 26pt into place over `badeLaunch`
(0.55s), and the full stop springs open on `badeCatch` after a 0.28s beat, in the accent colour.
No net: the mesh treatment is gone from this screen, and `NetMetrics.launchOpacity` / `launchReach`
went with it. `NetBackground` and `NetPanel` stay for Welcome, the Pro hero, the widget and the
empty states.

**It lives in `DesignSystem`, not `App`.** `App/` is the composition root and a branded animated
view is not composition — and there it is reachable by the snapshot suite, which is how it now has
five references.

**The root waits for it.** The read that decides between Welcome and the tabs finishes in a fraction
of the 0.95s the arrival takes, so the animation was drawn and then immediately cut off — it could
not be seen at all. `BadeLaunchSurface` reports when it has settled and the root holds until both
that and `isReady`, with the cross-fade keyed to both because either can finish last. **Reduce
Motion skips the hold**: the design says draw the settled frame and hand over, and somebody who
asked for less motion should not be made to wait for an animation that is not playing. The cost is
stated rather than hidden — **every launch is ~0.95s slower**, and `BadeWordmarkMetrics.settle` is
the one constant that changes it.

**`app.wordmark` is a new key**, lowercase `bade` in both languages, because `app.name` is `Bade.`
and the design is lowercase with the stop drawn separately so it can carry the accent and arrive on
its own. Three forms of the name now exist deliberately: the icon says `Bade`, `app.name` says
`Bade.`, the launch screen says `bade.`.

**The static launch screen matches.** `Bade/Assets.xcassets/LaunchBackground.colorset` carries
`#EFEEE9` / `#0E0F0C` and `Bade/Info.plist` points `UILaunchScreen.UIColorName` at it, so the frame
iOS draws before any code runs is the app's own surface rather than white. Verified in the built
bundle. `INFOPLIST_KEY_UILaunchScreen_Generation` is still on and merges a redundant nested
`UILaunchScreen` key inside the dict; iOS ignores it and reads the colour, but turning that setting
off would tidy it.

### The widget

Built although §13 of the spec lists widgets as out of scope for v1, because the Pro page sells them.
`Widgets` holds the snapshot, the timeline and the views; `BadeWidget/BadeWidgetBundle.swift` is an
eight-line shell in the extension target, so everything real stays previewable in the package.

- The app publishes a **snapshot** — this month's total, what is still to come, the next three
  charges, the display currency, the app's locale and `isPro` — into the App Group container. The
  widget decodes it and computes nothing: no SwiftData, no rates, no StoreKit in that process.
- Published from `.task(id: widgetKey)` on `currency | language | isPro | reload`, **and** from
  `store.changes()`, so an edit made deep inside a feature reaches the home screen.
- The hero is **what is still to come this month**, with the month's whole cost beneath it, and the
  charges listed beside it are this month's only — the tile is headed "this month" and borrowing
  next month's to fill the rows contradicted it. Only a real month can be half spent, which is what
  the bar means; the list's levelled "a month" answers a different question and always will.
- The net is behind both states. The locked tile shows a redacted, blurred figure through it,
  because a tile that only says "buy Pro" never shows what it is withholding.

### Cadence is fitted to a phase, not chained from gaps — now recorded in the spec

**§7 has been amended.** Step 2 is the phase fit with its slack table and the 80% rule; step 3 is
the majority vote over day-deltas and says it is the only place deltas are used. A paragraph after
the list explains why the two steps answer different questions, and what replacing step 3 as well
cost when it was tried.

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

## Snapshot tests

They do not run on the host — `#if os(iOS)` — so `swift test` never even compiles them. That is how
they rotted last time: two call sites went stale and nothing noticed for weeks, because the only
thing that builds this file is a simulator.

```sh
cd BadeKit
xcodebuild -scheme BadeKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SnapshotTests test                       # ~105s
```

After a deliberate design change, re-record and read the diff before committing it:

```sh
rm -rf Tests/Fixtures/Snapshots     # or pass TEST_RUNNER_BADE_RECORD_SNAPSHOTS=1
```

⚠️ `xcodebuild` does **not** forward the shell's environment to the test process. A plain
`BADE_RECORD_SNAPSHOTS=1` in front of the command is silently ignored and every "recording" run
quietly compares instead — which cost an hour of believing a broken loop. The `TEST_RUNNER_` prefix
is the mechanism; Xcode strips it before handing it over.

**What it will and will not catch.** Forty-one screens are pixel-identical between runs and bounded
at 0.1%, so anything that moves a row or resizes text fails loudly — a four-point change to
`BadeSpacing.md` tripped 29 of 42. Subscriptions is bounded at 2% instead, because its hero total
draws through `BadeMoneyText(shimmers: true)`, a repeating animation that never settles; a
regression on that one screen smaller than 2% of its pixels goes uncaught, and that is the price of
having the other forty-one mean something.

**The clock is pinned, as of 2026-08-23.** Upcoming and the form rendered against the real `.now`,
so 13 of the 42 moved with the calendar date — see the trap above. `UpcomingViewModel` and
`SubscriptionFormViewModel` now accept `today:` and the snapshots pass `date(0)`, the same epoch the
fixture data uses. Verified by a full compare run after re-recording: 42 of 42 clean.

A mismatch writes the rendered PNG to a temporary folder and prints both paths, so the two can be
opened side by side.

---

## Verifying anything

```sh
cd BadeKit && swift test          # 545 tests, ~2s here, ~0.7s without the statements
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

- **A `TextField` will not take a shorter value back from its own setter.** Bounding input in a
  reducer passed every test and did nothing on a phone: the field kept what was typed until
  something else forced a redraw, so the limit only appeared to bite on losing focus — which is
  worse than none, because it silently rewrote a number somebody had already read. The view has to
  own `@State` and truncate in `onChange`; writing to state the view owns is a separate update, and
  SwiftUI applies that. Three attempts went into this, two of them reasoning rather than using the
  pattern that is known to work.
- **`Button(role: .destructive)` inside `swipeActions` deletes the row itself.** SwiftUI performs
  its own removal the instant it is tapped, before anything is asked, so putting a confirmation in
  front made the row collapse and spring back — a delete that looked like it happened and got
  undone. Tint with `theme.destructive` instead and let the answer do the deleting.
- **`xcodebuild` does not forward the shell's environment to the test process.** A plain
  `FOO=1 xcodebuild test` is silently ignored; `TEST_RUNNER_FOO=1` is the mechanism, and Xcode strips
  the prefix. An hour went into believing a record-mode loop that was quietly comparing instead.
- **A snapshot of a view that reads `.now` rots overnight.** `UpcomingViewModel` and
  `SubscriptionFormViewModel` let their state default `today` to `.now`, so the references recorded
  on 2026-08-22 failed on the 23rd — 8 of 42, purely because the day changed. The fixture *data* was
  pinned to a fixed epoch from the start; the *view's* idea of today was not, which is the half that
  was easy to miss. Both inits now take `today: Date = .now` and the snapshots pass `date(0)`.
  Worse than the noise: 5 more references rendered identically across those two days and moved only
  once the date was pinned, so "it passed yesterday" was never evidence of determinism. **Anything a
  snapshot renders must have every clock injected, not just the data.**
- **Animation makes a screen unrepeatable.** With no code change between runs, nine snapshots
  differed by up to 10.77% of their pixels — a total counting up, a net fading in. That noise was
  larger than most real regressions, so the comparison failed at random and caught nothing. Worse,
  it produced a convincing false proof: a font change "caught" by exactly the six screens that were
  already nondeterministic. Measure a noise floor across identical runs before trusting any
  tolerance.
- **A limit on a string is not a limit on a number.** Six characters made "999.99" cost the same as
  "999999", so the decimals became unreachable exactly when the amount was large enough to want
  them. Count the halves separately.
- **Bound a fixture's data, not just its names.** The first scrubbed BOG statement kept two merchants
  as full street addresses, because the brand check passed and the location tail rode along with it.
  A brand is public; the branch somebody shops at is not.

- **Presented content is not inside the presenting view's tree.** A sheet or a cover inherits none
  of what the root sets — locale, calendar, text size, forced appearance, the palette. Four
  presentations each set the theme and stopped, and the whole import flow ran in English on the
  system's calendar for months. `BadeAppEnvironment` carries all five; every presentation applies it.
- **WidgetKit lifts `containerBackground` out of the view entirely.** No modifier ordering gets the
  environment to it. It read the default palette — light — while the content resolved dark, which
  put a near-white total on a cream tile and read as an empty widget. Anything WidgetKit extracts
  must resolve from `colorScheme`, which is why `BadeTheme.matching(_:)` exists.
- **Animate a `List`'s reorder on the state change, never on the `List`.** `.animation(_:value:)`
  keyed to the rows array asks SwiftUI to animate a structural change from outside while the list
  animates the same change from inside; whichever loses leaves a row clipped until the next
  relayout. `withBadeAnimation { model.send(...) }` at the mutation is the reliable form.
- **An animation on a state change reaches the whole screen.** The reorder spring caught the section
  header and the sort label with it. Where something must not move, it needs saying — though see
  open item 0 for a case where saying it did not help.
- **The mesh must fade, never clip.** `NetBackground`'s falloff is measured against the widest side
  of its canvas, so on anything wider than it is tall it is still at strength when the canvas ends
  and stops on a hard line. Fixed three times in three places: mask both ends (the lock), shorten
  the reach (the widget), or mask the leading edge (the pull web). A clipped net always looks broken.
- **A toolbar does not reliably rebuild when its content appears out of a condition.** Keep the item
  present and fade it. And giving a screen title content makes the bar lay itself out for a large
  title even with no `navigationTitle` — `.toolbarTitleDisplayMode(.inline)` is what stops the gap
  that opens above the content.
- **`onScrollVisibilityChange` on a row inside a `List` never reported.** Read the list's own
  geometry with `onScrollGeometryChange` instead; an offset is a number that can be reasoned about.
- **Padding inside a bottom-anchored block moves the content, not the block.** The Pro lock's copy
  sat on ground that ignored the bottom safe area, so padding it only grew the white area downward.
  Whatever must clear the tab bar has to be measured from the edge it is clearing.
- **Swift's `Hasher` is seeded per process.** Anything that must look the same on every launch — a
  merchant's colour, a reminder's emoji — needs its own stable fingerprint, not `hashValue`.
- **A statement cannot record a charge that has not happened.** `upcomingCharges` drops recorded
  charges dated after today, which is right; a test fixture that dates one in the future is the
  thing that is wrong.

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
