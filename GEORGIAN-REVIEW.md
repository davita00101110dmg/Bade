# The Georgian pass — for review

Step 14. Every one of the 227 keys was read at the place it appears on screen, judged against the
control it sits in, and against the rest of the file. **50 were changed, 177 were left alone, and 2
were added** for the VoiceOver work in the same session.

**Nothing has been marked reviewed.** Every Georgian value is still `needs_review`, because only a
native speaker's yes should flip it. Read this file, change what you disagree with, then run the
snippet at the bottom once and step 14 is done.

`swift test` 511 passing · iOS build green, no warnings · all five quality gates zero.

---

## Six decisions that are yours, not mine

These are the calls a translator cannot make alone. Everything in the tables below follows from
them, so if you reject one, say so and the keys under it change together.

**1 · Register: informal `შენ` throughout.** The file was split roughly two to one — Welcome, the FX
sentences, Review's title and three Pro lines addressed the reader as `თქვენ`, everything else as
`შენ`. The FX card managed both at once: `შენი ბანკის კურსი` as a row label, directly under
`თქვენი ბანკის კურსი … დაგიჯდათ` as the sentence. I went informal because it was already the
majority, because it is what Georgian consumer apps use, and because formal `თქვენ` reads like the
bank Bade is positioned against. **13 keys changed for this reason alone.** Reject it and the same
13 flip the other way — the work is symmetrical.

**2 · The wordmark stays Latin.** `app.name` ships as `Bade.` in both languages, but two keys had
quietly localised it to `ბადე` — `welcome.subtitle`, the second line a new user ever reads, and
`parsing.failure.unrecognised`. So the app called itself two different things. I standardised on
`Bade` to match `app.name`. This is the branding question still open in the handoff; deciding it the
other way means changing `app.name` too, not just these two.

**3 · Nothing is ever "uploaded".** Four keys used `ატვირთე` / `ატვირთულია` — *upload*. Bade's
entire promise is that nothing leaves the phone, and the Welcome screen says so two inches away.
Georgian readers do use `ატვირთვა` loosely for "load a file in", but on this app it actively
contradicts the pitch. Replaced with `იმპორტი` for the noun (matching the buttons, and Apple's own
Georgian) and `შემოიტანე` / `დაამატე` for the verb. If you want the fully native word throughout,
the buttons become `ამონაწერის შემოტანა` and four more keys change.

**4 · One word per thing.** `ჩამოჭრა` for a charge everywhere — it was already dominant and it is
what BOG and TBC use in their own notifications. `ბარათის სისტემა` for the card scheme, which had
been both that and `საგადახდო სისტემა` in the same card. `დანამატი` for the markup, replacing
`ზედნადები`, which means overhead in the accounting sense.

**5 · The app has no first person.** It said `ვამოწმებ ტრანზაქციებს` — *I am checking transactions*
— as the ② Parsing headline, `ვერ შევინახეთ` — *we could not save* — in Review, and named itself
`Bade` everywhere else. Three voices. All impersonal now, or `Bade` as the subject.

**6 · Menu items are verbal nouns.** `მონიშნე აქტიურად` (imperative) became `აქტიურად მონიშვნა`,
matching `წაშლა`, `რედაქტირება`, `შენახვა` and every other action in the app. Imperatives were kept
where English is also imperative and the control is a call to action — `შემახსენე`, `ნახე, რას
გაძლევს Pro`, `შეიტყვე ჩამოჭრამდე`.

---

## Two grammar bugs, not style

Both would have shipped as visibly broken Georgian, and neither is visible in English.

**`reminder.onDay %@` — a notification title, on a real user's lock screen.**
The format was `%@-ს ჩამოგეჭრება` and `%@` is filled by the system's weekday name. CLDR hands back
the **nominative**: `ორშაბათი`, `სამშაბათი`, `პარასკევი`. So the title rendered as
**`ორშაბათი-ს ჩამოგეჭრება`** — a case ending hyphenated onto a word that has to be inflected
instead (`ორშაბათს`). I verified this against Foundation rather than assuming it; all seven days
come back nominative.

It cannot be fixed in the catalog, because the wrong form is injected by the formatter, and it must
not be fixed in code — inflecting Georgian in `ReminderText` would put Georgian strings outside a
parser, which constraint 6 forbids. So the wording changed to one that takes the nominative:
**`%@ — ჩამოგეჭრება`**. If you would rather keep the case ending, the only clean route is a
localised weekday key per day, which is seven more strings.

**`review.ended %@` — the same trap, on a Review row.** `დასრულდა %1$@` with a month name renders
`დასრულდა აგვისტო`, which reads "August ended". A colon licenses the nominative, so it is now
`დასრულდა: %1$@`.

**A permanent guard was added** for the related failure — a translation quietly losing a `%@`.
`everyTranslationCarriesTheSamePlaceholders` compares the placeholders in every Georgian value
against its English source. I broke a key deliberately to confirm it fails, then restored it.

---

## The 50 changed

Sorted by key. The **bold** column is what ships if you approve.

| Key | English | Was | Now | Where |
|---|---|---|---|---|
| `common.working` | Working | მუშაობს | **მიმდინარეობს** | VoiceOver value on a progress bar |
| `detail.billedIn %@ %@` | %1$@ · billed in %2$@ | %1$@ · ანგარიშსწორება %2$@-ში | **%1$@ · გადახდა %2$@-ში** | ⑥ Detail |
| `detail.deleteMessage` | Importing the statement again will find it. | ამონაწერის ხელახლა იმპორტი კვლავ იპოვის მას. | **ამონაწერის ხელახლა იმპორტისას ისევ მოიძებნება.** | ⑥ Detail |
| `detail.fx.costLessOfficial %@` | Your bank's rate cost you %@ less than the National Bank's. | თქვენი ბანკის კურსი ეროვნული ბანკის კურსზე %@-ით იაფი დაგიჯდათ. | **შენი ბანკის კურსი ეროვნული ბანკის კურსზე %@-ით იაფია.** | ⑥ Detail — the FX card |
| `detail.fx.costLessScheme %@` | Your bank's rate cost you %@ less than the card network's. | თქვენი ბანკის კურსი ბარათის სისტემის კურსზე %@-ით იაფი დაგიჯდათ. | **შენი ბანკის კურსი ბარათის სისტემის კურსზე %@-ით იაფია.** | ⑥ Detail — the FX card |
| `detail.fx.costMoreOfficial %@` | Your bank's rate cost you %@ more than the National Bank's. | თქვენი ბანკის კურსი ეროვნული ბანკის კურსზე %@-ით ძვირი დაგიჯდათ. | **შენი ბანკის კურსი ეროვნული ბანკის კურსზე %@-ით ძვირია.** | ⑥ Detail — the FX card |
| `detail.fx.costMoreScheme %@` | Your bank's rate cost you %@ more than the card network's. | თქვენი ბანკის კურსი ბარათის სისტემის კურსზე %@-ით ძვირი დაგიჯდათ. | **შენი ბანკის კურსი ბარათის სისტემის კურსზე %@-ით ძვირია.** | ⑥ Detail — the FX card |
| `detail.fx.noConversion %@` | Paid straight from your %@ balance, so nothing was converted and there is no markup. | გადახდილია პირდაპირ შენი %@ ბალანსიდან — კონვერტაცია არ მომხდარა და ზედნადებიც არ არის. | **გადახდილია პირდაპირ შენი %@ ბალანსიდან — კონვერტაცია არ მომხდარა და დანამატიც არ არის.** | ⑥ Detail — the FX card |
| `detail.fx.rateGap` | Difference between the rates | სხვაობა კურსებს შორის | **კურსების სხვაობა** | ⑥ Detail — **never shown**, see dead keys |
| `detail.fx.schemeRate` | Card scheme rate | საგადახდო სისტემის კურსი | **ბარათის სისტემის კურსი** | ⑥ Detail — the FX card, behind the disclosure |
| `import.nothingNewTitle` | Already imported | უკვე ატვირთულია | **უკვე იმპორტირებულია** | “already imported” alert |
| `parsing.chooseAnother` | Choose another file | აირჩიეთ სხვა ფაილი | **აირჩიე სხვა ფაილი** | ② Parsing |
| `parsing.failure.tooFew` | Almost nothing could be read from that statement. | ამონაწერიდან თითქმის ვერაფერი წაიკითხა. | **ამონაწერიდან თითქმის ვერაფერი ამოიკითხა.** | ② Parsing |
| `parsing.failure.unrecognised` | This does not look like a bank statement Bade can read yet. | ეს არ ჰგავს ამონაწერს, რომლის წაკითხვაც ბადეს ჯერ შეუძლია. | **ეს არ ჰგავს ამონაწერს, რომლის წაკითხვაც Bade-ს ჯერ შეუძლია.** | ② Parsing |
| `parsing.processedHere` | Processed on this phone only | დამუშავება ხდება ტელეფონში | **დამუშავება მხოლოდ ამ ტელეფონში ხდება** | ② Parsing |
| `parsing.title` | Checking transactions | ვამოწმებ ტრანზაქციებს | **ტრანზაქციები მოწმდება** | ② Parsing — the headline |
| `pro.blurb` | An app that charges a subscription to track subscriptions is a punchline. Bade Pro is bought once and yours. | აპლიკაცია, რომელიც გამოწერას ითხოვს გამოწერების თვალყურისთვის, სასაცილოა. Bade Pro ერთხელ იყიდება და შენია. | **აპლიკაცია, რომელიც გამოწერების საკონტროლოდ თვითონ ითხოვს გამოწერას, ანეკდოტია. Bade ერთხელ იყიდება და შენია.** | ⑨ Bade Pro |
| `pro.calendar` | Upcoming charges | მომავალი გადახდები | **მომავალი ჩამოჭრები** | ⑨ Bade Pro |
| `pro.calendarDetail` | A calendar of what is due, and what each day costs. | კალენდარი იმისა, რაც უნდა გადაიხადოთ, და რა ღირს თითოეული დღე. | **კალენდარი — რა ჩამოგეჭრება და რა ჯდება თითოეული დღე.** | ⑨ Bade Pro |
| `pro.exportDetail` | Everything Bade found, as CSV or JSON, whenever you want it. | ყველაფერი, რაც Bade-მ იპოვა, CSV ან JSON ფორმატში, როცა გინდათ. | **ყველაფერი, რაც Bade-მ იპოვა, CSV ან JSON ფორმატში, როცა მოგინდება.** | ⑨ Bade Pro |
| `pro.fx` | FX markup breakdown | ვალუტის კურსის ზედნადები | **ვალუტის კონვერტაციის დანამატი** | ⑨ Bade Pro |
| `pro.fxDetail` | The rate your bank really used, next to the card scheme's, on every foreign charge. | კურსი, რომელიც ბანკმა რეალურად გამოიყენა, ბარათის სისტემის კურსის გვერდით. | **კურსი, რომელიც ბანკმა რეალურად გამოიყენა, ბარათის სისტემის კურსის გვერდით — ყველა უცხოურ ჩამოჭრაზე.** | ⑨ Bade Pro |
| `pro.tagline` | One payment. ⏎ No subscription, ever. | ერთი გადახდა. ⏎ არასოდეს გამოწერა. | **ერთი გადახდა. ⏎ გამოწერა — არასოდეს.** | ⑨ Bade Pro |
| `reminder.onDay %@` | Charging on %@ | %@-ს ჩამოგეჭრება | **%@ — ჩამოგეჭრება** | a notification title |
| `review.ended %@` | ended %1$@ | დასრულდა %1$@ | **დასრულდა: %1$@** | ③ Review — a row's caption |
| `review.saveFailed` | Couldn't save. Try again. | ვერ შევინახეთ. სცადეთ ხელახლა. | **შენახვა ვერ მოხერხდა. სცადე ხელახლა.** | ③ Review |
| `review.tier.confident` | Confident | დარწმუნებული | **ნამდვილად** | ③ Review |
| `review.tier.uncertain` | Not sure | ეჭვქვეშ | **გაურკვეველი** | ③ Review |
| `review.title` | Review what we found | შეამოწმეთ ნაპოვნი | **შეამოწმე ნაპოვნი** | ③ Review |
| `settings.defaultBadge` | Chosen for you | შერჩეულია ავტომატურად | **შენთვის შერჩეული** | ⑩ Settings |
| `settings.ratesFooter` | The only thing Bade ever sends. It asks the National Bank for a day's rates — no account data, no merchant names — and only when a statement did not print a rate to compare against. | ერთადერთი, რასაც Bade აგზავნის. ეროვნულ ბანკს ერთი დღის კურსებს ეკითხება — ანგარიშის მონაცემების და მაღაზიების სახელების გარეშე — და მხოლოდ მაშინ, როცა ამონაწერში შესადარებელი კურსი არ არის. | **ერთადერთი, რასაც Bade აგზავნის. ეროვნულ ბანკს ერთი დღის კურსებს ეკითხება — ანგარიშის მონაცემების და სერვისების სახელების გარეშე — და მხოლოდ მაშინ, როცა ამონაწერში შესადარებელი კურსი არ არის.** | ⑩ Settings |
| `settings.reminderTime` | At | დროს | **დრო** | ⑩ Settings — label beside the time picker |
| `settings.textSize.standard` | Default | ნაგულისხმევი | **სტანდარტული** | ⑩ Settings |
| `store.resetMessage` | This version of Bade could not open what was stored on this phone, so it has started fresh. Nothing was deleted — the old data was set aside. Import your statement again. | Bade-ის ამ ვერსიამ ვერ გახსნა ტელეფონზე შენახული მონაცემები და თავიდან დაიწყო. არაფერი წაშლილა — ძველი მონაცემები გვერდით გადაინახა. ატვირთე ამონაწერი ხელახლა. | **Bade-ის ამ ვერსიამ ვერ გახსნა ტელეფონზე შენახული მონაცემები და თავიდან დაიწყო. არაფერი წაშლილა — ძველი მონაცემები გვერდით გადაინახა. ამონაწერი ხელახლა დაამატე.** | the reset alert |
| `subscriptions.markActive` | Mark as active | მონიშნე აქტიურად | **აქტიურად მონიშვნა** | ④ Subscriptions — swipe and context menu |
| `subscriptions.markCancelled` | Mark as cancelled | მონიშნე გაუქმებულად | **გაუქმებულად მონიშვნა** | ④ Subscriptions — swipe and context menu |
| `subscriptions.nothingCharging` | Nothing is charging you | ამჟამად არაფერი გიჭრით | **ამჟამად არაფერს იხდი** | ④ Subscriptions — under the hero, when empty |
| `subscriptions.sort.cost` | By cost | ფასის მიხედვით | **ფასით** | ④ Subscriptions — the sort menu |
| `subscriptions.sort.name` | By name | სახელის მიხედვით | **სახელით** | ④ Subscriptions — the sort menu |
| `subscriptions.unconvertible %lld` | %#@count@ not converted | %#@count@ არ გადაიყვანა | **%#@count@ ვერ კონვერტირდა** | ④ Subscriptions and ⑤ Upcoming — the warning caption |
| `upcoming.nothingEver` | Nothing is charging. Add a subscription or import a statement. | ჩამოჭრები არ არის. დაამატე გამოწერა ან ატვირთე ამონაწერი. | **ჩამოჭრები არ არის. დაამატე გამოწერა ან შემოიტანე ამონაწერი.** | ⑤ Upcoming |
| `upcoming.thisMonth` | This month | ამ თვეში | **მიმდინარე თვე** | ⑤ Upcoming — VoiceOver label on the month button |
| `welcome.guide.1` | Open your bank's app → Accounts | გახსენით ბანკის აპი → ანგარიშები | **გახსენი ბანკის აპი → ანგარიშები** | ① Welcome |
| `welcome.guide.title` | How to export your statement | როგორ ჩამოტვირთოთ ამონაწერი | **როგორ ჩამოტვირთო ამონაწერი** | ① Welcome |
| `welcome.privacy.line2` | We never ask for your bank password. | ბანკის პაროლი არასდროს გვჭირდება. | **Bade არასოდეს ითხოვს ბანკის პაროლს.** | ① Welcome |
| `welcome.subtitle` | Bade finds every recurring charge in your bank statement. | ბადე იპოვის ყველა განმეორებად ჩამოჭრას თქვენს საბანკო ამონაწერში. | **Bade იპოვის ყველა განმეორებად ჩამოჭრას შენს საბანკო ამონაწერში.** | ① Welcome |
| `welcome.title` | How much are you paying a month? | რამდენს იხდით თვეში? | **რამდენს იხდი თვეში?** | ① Welcome |
| `widget.empty` | Import a statement to see your total here. | ატვირთე ამონაწერი, რომ ჯამი აქ გამოჩნდეს. | **შემოიტანე ამონაწერი, რომ ჯამი აქ გამოჩნდეს.** | ⓦ Widget |
| `widget.ofMonth %@` | of %@ this month | %@-დან ამ თვეში | **ამ თვეში სულ %@** | ⓦ Widget — under the bar |
| `widget.stillComing` | Still coming | კიდევ მოსალოდნელი | **დარჩენილი** | ⓦ Widget — the heading |

---

## The 2 added

Both exist for the VoiceOver work in this session, not for anything visible.

| Key | English | Georgian | Where |
|---|---|---|---|
| `common.progress` | Progress | მიმდინარეობა | VoiceOver label on a progress bar |
| `upcoming.dayCharges %lld` | %#@count@ | %#@count@ | ⑤ Upcoming — VoiceOver value on a calendar tile |

---

## Twelve keys nothing displays

Found while tracing each key to its screen. Not deleted — that is your call.

| Key | Why it is orphaned |
|---|---|
| `pro.alerts` + `Detail` | Deliberate. `Strings.swift` says so: parked with features that do not exist yet. |
| `pro.trends` + `Detail` | Same. |
| `pro.categories` + `Detail` | Same. |
| `pro.themes` + `Detail` | Same. |
| `detail.fx.rateGap` | "Difference between the rates". `ExchangeCard` shows paid, bank rate and reference rate — never a gap row. Left over from an earlier FX card. |
| `review.isSubscription`, `review.notOne` | "Subscription" / "Not one". `ReviewSectionView`'s own comment records that the per-row question was removed in favour of one checkbox. Genuinely dead. |
| `widget.toGo %@` | "%@ to go". Superseded by `widget.ofMonth`; `BadeWidgetView` never calls it. |
| `settings.remindersPro` | "Reminders are part of Bade Pro." Unreachable: `remindersSection` only renders when `isPro`, and the footer's `!isPro` branch is inside it. |

The eight `pro.*` ones are documented and should stay. The other four are 4 keys of dead weight.

---

## The 177 left alone

Read, judged, and correct as they were. Included so the pass is complete rather than only its diff.

| Key | English | Georgian | Where |
|---|---|---|---|
| `app.name` | Bade. | Bade. | the wordmark |
| `cadence.annual` | annual | წლიური | ⑥ Detail, ③ Review, ⓜ Form |
| `cadence.monthly` | monthly | ყოველთვიური | ⑥ Detail, ③ Review, ⓜ Form |
| `cadence.quarterly` | quarterly | კვარტალური | ⑥ Detail, ③ Review, ⓜ Form |
| `cadence.semiannual` | semiannual | ნახევარწლიური | ⑥ Detail, ③ Review, ⓜ Form |
| `cadence.weekly` | weekly | ყოველკვირეული | ⑥ Detail, ③ Review, ⓜ Form |
| `common.ok` | OK | კარგი | shared |
| `currency.all` | All currencies | ყველა ვალუტა | currency picker |
| `currency.known` | In your subscriptions | შენს გამოწერებში | currency picker |
| `currency.search` | Search | ძებნა | currency picker |
| `currency.title` | Currency | ვალუტა | currency picker |
| `detail.aYear` | A year | წელიწადში | ⑥ Detail |
| `detail.cancel` | Cancel | გაუქმება | ⑥ Detail |
| `detail.delete` | Delete | წაშლა | ⑥ Detail |
| `detail.deleteTitle` | Delete this subscription? | წავშალოთ ეს გამოწერა? | ⑥ Detail |
| `detail.firstCharge` | First charge | პირველი ჩამოჭრა | ⑥ Detail |
| `detail.fx.bankRate` | Your bank's rate | შენი ბანკის კურსი | ⑥ Detail |
| `detail.fx.noRate` | No reference rate for that day yet. | იმ დღის საორიენტაციო კურსი ჯერ არ არის. | ⑥ Detail |
| `detail.fx.officialRate` | National Bank rate | ეროვნული ბანკის კურსი | ⑥ Detail |
| `detail.fx.paid` | Left your account | ჩამოგეჭრა | ⑥ Detail |
| `detail.fx.showRates` | Show the rates | კურსების ჩვენება | ⑥ Detail |
| `detail.fx.title` | What the conversion cost | რა დაჯდა კონვერტაცია | ⑥ Detail |
| `detail.history` | Last 12 months | ბოლო 12 თვე | ⑥ Detail |
| `detail.nextCharge` | Next charge | შემდეგი ჩამოჭრა | ⑥ Detail |
| `detail.noHistory` | No charges recorded yet. | ჩამოჭრები ჯერ არ არის. | ⑥ Detail |
| `detail.priceChange %@` | Price change · %@ | ფასის ცვლილება · %@ | ⑥ Detail |
| `detail.title` | Details | დეტალები | ⑥ Detail |
| `form.active` | Active | აქტიური | ⓜ Form |
| `form.activeFooter` | A cancelled subscription stays in Bade but stops counting towards your total. | გაუქმებული გამოწერა რჩება Bade-ში, მაგრამ აღარ ითვლება ჯამში. | ⓜ Form |
| `form.amount` | Amount | თანხა | ⓜ Form |
| `form.billing` | Billing | გადახდა | ⓜ Form |
| `form.cadence` | Repeats | პერიოდულობა | ⓜ Form |
| `form.cancel` | Cancel | გაუქმება | ⓜ Form |
| `form.discard` | Discard | არ შეინახოს | ⓜ Form |
| `form.discardMessage` | What you typed will not be saved. | აკრეფილი მონაცემები არ შეინახება. | ⓜ Form |
| `form.discardTitle` | Discard changes? | ცვლილებები არ შეინახოს? | ⓜ Form |
| `form.keepEditing` | Keep editing | რედაქტირების გაგრძელება | ⓜ Form |
| `form.price` | Price | ფასი | ⓜ Form |
| `form.save` | Save | შენახვა | ⓜ Form |
| `form.service` | Service | სერვისი | ⓜ Form |
| `form.servicePrompt` | Name | დასახელება | ⓜ Form |
| `form.suggestions` | Suggestions | შემოთავაზებები | ⓜ Form |
| `form.title.edit` | Edit subscription | გამოწერის რედაქტირება | ⓜ Form |
| `form.title.new` | Add subscription | გამოწერის დამატება | ⓜ Form |
| `import.nothingNewMessage` | Everything in this statement was already in Bade, so nothing new was added. Prices and dates were brought up to date. | ამ ამონაწერში ყველაფერი უკვე იყო Bade-ში, ამიტომ ახალი არაფერი დაემატა. ფასები და თარიღები განახლდა. | “already imported” alert |
| `locked.action` | See what Pro adds | ნახე, რას გაძლევს Pro | the Pro lock |
| `locked.title` | Part of Bade Pro | Bade Pro-ს ნაწილი | the Pro lock |
| `parsing.beta` | BETA | BETA | ② Parsing |
| `parsing.betaNote` | Reads Bank of Georgia and TBC statements. A bank can change its format without warning. | კითხულობს საქართველოს ბანკისა და თიბისის ამონაწერებს. ბანკმა შეიძლება ფორმატი გაფრთხილების გარეშე შეცვალოს. | ② Parsing |
| `parsing.close` | Close | დახურვა | ② Parsing |
| `parsing.failed` | Could not read that statement | ამონაწერის წაკითხვა ვერ მოხერხდა | ② Parsing |
| `parsing.failure.unreadable` | That file could not be opened. | ფაილის გახსნა ვერ მოხერხდა. | ② Parsing |
| `parsing.file.months %lld` | %lld months | %lld თვე | ② Parsing |
| `parsing.file.transactions %lld` | %lld transactions | %lld ტრანზაქცია | ② Parsing |
| `parsing.found` | Found | ნაპოვნია | ② Parsing |
| `parsing.nothingMessage` | Bade read the statement but found no charge that comes back on a rhythm. A longer statement — three months or more — gives it more to work with. | Bade-მ ამონაწერი წაიკითხა, მაგრამ განმეორებადი ჩამოჭრა ვერ აღმოაჩინა. უფრო ხანგრძლივი ამონაწერი — სამი თვე ან მეტი — მეტ მასალას მისცემს. | ② Parsing |
| `parsing.nothingTitle` | Nothing repeating here | განმეორებადი ვერაფერი მოიძებნა | ② Parsing |
| `parsing.occurrences %lld` | ×%lld | ×%lld | ② Parsing |
| `parsing.progress %@ %@` | %1$@ · %2$@ | %1$@ · %2$@ | ② Parsing |
| `parsing.reading` | Opening the file | ფაილი იხსნება | ② Parsing |
| `pro.alerts` | Price-increase alerts | ფასის ზრდის შეტყობინებები | ⑨ Bade Pro |
| `pro.alertsDetail` | Told when a subscription quietly goes up, with the old price and the new one. | შეიტყობ, როცა გამოწერა ჩუმად გაძვირდება — ძველ და ახალ ფასთან ერთად. | ⑨ Bade Pro |
| `pro.badge` | PRO | PRO | ⑨ Bade Pro |
| `pro.categories` | Category analytics | კატეგორიების ანალიტიკა | ⑨ Bade Pro |
| `pro.categoriesDetail` | How much of the total is streaming, software, or the gym. | ჯამის რა ნაწილია სტრიმინგი, პროგრამები თუ სპორტდარბაზი. | ⑨ Bade Pro |
| `pro.export` | Export your data | მონაცემების ექსპორტი | ⑨ Bade Pro |
| `pro.failed` | That did not go through. Nothing was charged. | ვერ განხორციელდა. თანხა არ ჩამოგეჭრა. | ⑨ Bade Pro |
| `pro.included` | What you get | რას მიიღებ | ⑨ Bade Pro |
| `pro.nothingToRestore` | No earlier purchase was found on this Apple Account. | ამ Apple Account-ზე ადრინდელი შენაძენი ვერ მოიძებნა. | ⑨ Bade Pro |
| `pro.owned` | Bade Pro is yours. | Bade Pro შენია. | ⑨ Bade Pro |
| `pro.ownedDetail` | Bought once, on this Apple Account. Nothing recurring, nothing to cancel. | ერთხელ ნაყიდი, ამ Apple Account-ზე. არაფერი განმეორებადი, გასაუქმებელი არაფერი. | ⑨ Bade Pro |
| `pro.reminders` | Renewal reminders | განახლების შეხსენებები | ⑨ Bade Pro |
| `pro.remindersDetail` | Told the day before a subscription renews, with what it is about to cost. | შეიტყობ გამოწერის განახლებამდე ერთი დღით ადრე — და რამდენი დაგიჯდება. | ⑨ Bade Pro |
| `pro.restore` | Restore a purchase | შენაძენის აღდგენა | ⑨ Bade Pro |
| `pro.storeUnavailable` | The App Store cannot be reached right now. | App Store ამჟამად მიუწვდომელია. | ⑨ Bade Pro |
| `pro.themes` | Themes and custom icons | თემები და ხატულები | ⑨ Bade Pro |
| `pro.themesDetail` | A different palette, and an app icon that is yours. | სხვა პალიტრა და შენი აპლიკაციის ხატულა. | ⑨ Bade Pro |
| `pro.title` | Bade Pro | Bade Pro | ⑨ Bade Pro |
| `pro.trends` | Spending history and trends | ხარჯების ისტორია და ტენდენციები | ⑨ Bade Pro |
| `pro.trendsDetail` | What you were paying a year ago, and the direction it has moved since. | რამდენს იხდიდი წლის წინ და როგორ შეიცვალა მას შემდეგ. | ⑨ Bade Pro |
| `pro.unlock` | Unlock Bade Pro | Bade Pro-ს გახსნა | ⑨ Bade Pro |
| `pro.unlockPrice %@` | Unlock Bade Pro · %@ | Bade Pro-ს გახსნა · %@ | ⑨ Bade Pro |
| `pro.widgets` | Widgets | ვიჯეტები | ⑨ Bade Pro |
| `pro.widgetsDetail` | The total and what is next, on your home screen. | ჯამი და შემდეგი ჩამოჭრა მთავარ ეკრანზე. | ⑨ Bade Pro |
| `reminder.today` | Charging today | დღეს ჩამოგეჭრება | a notification |
| `reminder.tomorrow` | Charging tomorrow | ხვალ ჩამოგეჭრება | a notification |
| `reminderPrompt.allow` | Turn on reminders | შეხსენებების ჩართვა | ⓡ Reminder prompt |
| `reminderPrompt.blurb` | Bade can tell you the day before a subscription renews, so a price you had forgotten about is never a surprise. | Bade შეგატყობინებს გამოწერის განახლებამდე ერთი დღით ადრე, რომ დავიწყებული ფასი მოულოდნელი არ იყოს. | ⓡ Reminder prompt |
| `reminderPrompt.notNow` | Not now | ახლა არა | ⓡ Reminder prompt |
| `reminderPrompt.title` | Know before it charges | შეიტყვე ჩამოჭრამდე | ⓡ Reminder prompt |
| `review.caption %lld %@` | %#@count@ · %2$@ | %#@count@ · %2$@ | ③ Review |
| `review.close` | Close | დახურვა | ③ Review |
| `review.confirm %lld` | Confirm · %lld | დადასტურება · %lld | ③ Review |
| `review.isSubscription` | Subscription | გამოწერაა | ③ Review |
| `review.notOne` | Not one | არ არის | ③ Review |
| `review.priceChanged` | price changed | ფასი შეიცვალა | ③ Review |
| `review.summary %lld %@` | %#@count@ · %2$@ a month | %#@count@ · %2$@ თვეში | ③ Review |
| `review.tier.confidentHint` | 3+ charges | 3+ ჩამოჭრა | ③ Review |
| `review.tier.ended` | Already ended | უკვე დასრულდა | ③ Review |
| `review.tier.endedHint` | charges stopped | ჩამოჭრა შეწყდა | ③ Review |
| `review.tier.probable` | Probably | სავარაუდოდ | ③ Review |
| `review.tier.probableHint` | 2 charges | 2 ჩამოჭრა | ③ Review |
| `review.tierCount %@ %lld` | %1$@ · %2$lld | %1$@ · %2$lld | ③ Review |
| `settings.about` | About | აპლიკაციის შესახებ | ⑩ Settings |
| `settings.appearance` | Appearance | იერსახე | ⑩ Settings |
| `settings.appearance.dark` | Dark | მუქი | ⑩ Settings |
| `settings.appearance.light` | Light | ნათელი | ⑩ Settings |
| `settings.data` | Data | მონაცემები | ⑩ Settings |
| `settings.defaultFooter` | Marked values were chosen for you — the currency from your statements, the rest from your phone. Pick one and it stays picked. | მონიშნული მნიშვნელობები ავტომატურად შეირჩა — ვალუტა ამონაწერებიდან, დანარჩენი ტელეფონიდან. აირჩიე და შენარჩუნდება. | ⑩ Settings |
| `settings.display` | Display | ჩვენება | ⑩ Settings |
| `settings.exportCSV` | Export as CSV | ექსპორტი CSV-ად | ⑩ Settings |
| `settings.exportJSON` | Export as JSON | ექსპორტი JSON-ად | ⑩ Settings |
| `settings.exportName` | Bade subscriptions | Bade-ის გამოწერები | ⑩ Settings |
| `settings.language` | Language | ენა | ⑩ Settings |
| `settings.language.en` | English | English | ⑩ Settings |
| `settings.language.ka` | ქართული | ქართული | ⑩ Settings |
| `settings.option.system` | System | სისტემური | ⑩ Settings |
| `settings.rates` | Fetch official rates | ოფიციალური კურსების ჩამოტვირთვა | ⑩ Settings |
| `settings.remindMe` | Remind me | შემახსენე | ⑩ Settings |
| `settings.reminderOff` | Off | გამორთული | ⑩ Settings |
| `settings.reminderOneDay` | 1 day before | 1 დღით ადრე | ⑩ Settings |
| `settings.reminderSameDay` | On the day | იმავე დღეს | ⑩ Settings |
| `settings.reminderThreeDays` | 3 days before | 3 დღით ადრე | ⑩ Settings |
| `settings.reminderTwoDays` | 2 days before | 2 დღით ადრე | ⑩ Settings |
| `settings.reminders` | Reminders | შეხსენებები | ⑩ Settings |
| `settings.remindersDenied` | Notifications are turned off for Bade. Turn them on in iOS Settings › Notifications › Bade. | Bade-სთვის შეტყობინებები გამორთულია. ჩართე iOS-ის პარამეტრებში › შეტყობინებები › Bade. | ⑩ Settings |
| `settings.remindersFooter` | Before a charge lands. Reminders are worked out on your phone; nothing is sent anywhere. | ჩამოჭრამდე. შეხსენებები შენს ტელეფონში ითვლება — არსად არაფერი იგზავნება. | ⑩ Settings |
| `settings.remindersPro` | Reminders are part of Bade Pro. | შეხსენებები Bade Pro-ს ნაწილია. | ⑩ Settings |
| `settings.textSize` | Text size | ტექსტის ზომა | ⑩ Settings |
| `settings.textSize.larger` | Larger | დიდი | ⑩ Settings |
| `settings.textSize.largest` | Largest | ყველაზე დიდი | ⑩ Settings |
| `settings.textSize.smaller` | Smaller | პატარა | ⑩ Settings |
| `settings.textSize.smallest` | Smallest | ყველაზე პატარა | ⑩ Settings |
| `settings.title` | Settings | პარამეტრები | ⑩ Settings |
| `settings.version %@` | Version %@ | ვერსია %@ | ⑩ Settings |
| `settings.weekStart` | Week starts on | კვირის დასაწყისი | ⑩ Settings |
| `settings.weekStart.monday` | Monday | ორშაბათი | ⑩ Settings |
| `settings.weekStart.sunday` | Sunday | კვირა | ⑩ Settings |
| `store.resetTitle` | Your data could not be read | შენი მონაცემები ვერ წაიკითხა | the reset alert |
| `subscriptions.add` | Add subscription | გამოწერის დამატება | ④ Subscriptions |
| `subscriptions.all` | All subscriptions | ყველა გამოწერა | ④ Subscriptions |
| `subscriptions.cancel` | Cancel | გაუქმება | ④ Subscriptions |
| `subscriptions.delete` | Delete | წაშლა | ④ Subscriptions |
| `subscriptions.deleteAll` | Delete everything | ყველაფრის წაშლა | ④ Subscriptions |
| `subscriptions.deleteAllMessage` | Every subscription and exchange rate Bade has stored will be removed. This cannot be undone. | წაიშლება ყველა გამოწერა და კურსი, რაც Bade-ს აქვს შენახული. ამის დაბრუნება შეუძლებელია. | ④ Subscriptions |
| `subscriptions.deleteAllTitle` | Delete everything? | წავშალოთ ყველაფერი? | ④ Subscriptions |
| `subscriptions.edit` | Edit | რედაქტირება | ④ Subscriptions |
| `subscriptions.import` | Import statement | ამონაწერის იმპორტი | ④ Subscriptions |
| `subscriptions.loadFailed` | Couldn't load your subscriptions. | გამოწერების ჩატვირთვა ვერ მოხერხდა. | ④ Subscriptions |
| `subscriptions.noLongerCharged` | No longer charged | აღარ ჩამოიჭრება | ④ Subscriptions |
| `subscriptions.perMonth` | A month | თვეში | ④ Subscriptions |
| `subscriptions.separator` |  ·  |  ·  | ④ Subscriptions |
| `subscriptions.sort.nextCharge` | By next charge | შემდეგი ჩამოჭრით | ④ Subscriptions |
| `subscriptions.sortLabel` | Sort | დალაგება | ④ Subscriptions |
| `subscriptions.title` | Subscriptions | გამოწერები | ④ Subscriptions |
| `subscriptions.yearAndCount %@ %lld` | %1$@ a year · %#@count@ | %1$@ წელიწადში · %#@count@ | ④ Subscriptions |
| `upcoming.cancelled` | Cancelled | გაუქმებული | ⑤ Upcoming |
| `upcoming.loadFailed` | Could not read your subscriptions. | გამოწერების წაკითხვა ვერ მოხერხდა. | ⑤ Upcoming |
| `upcoming.next` | Next month | შემდეგი თვე | ⑤ Upcoming |
| `upcoming.nothing` | Nothing is charging this month. | ამ თვეში ჩამოჭრა არ არის. | ⑤ Upcoming |
| `upcoming.nothingThatDay` | Nothing is charging that day. | იმ დღეს ჩამოჭრა არ არის. | ⑤ Upcoming |
| `upcoming.previous` | Previous month | წინა თვე | ⑤ Upcoming |
| `upcoming.showMonth` | Show the whole month | მთელი თვის ჩვენება | ⑤ Upcoming |
| `upcoming.title` | Upcoming | მოსალოდნელი | ⑤ Upcoming |
| `upcoming.total` | Total | ჯამი | ⑤ Upcoming |
| `welcome.addManually` | Add manually | ხელით დამატება | ① Welcome |
| `welcome.guide.2` | Statement → period: last 12 months | ამონაწერი → პერიოდი: ბოლო 12 თვე | ① Welcome |
| `welcome.guide.3` | Format PDF → Share → Bade | ფორმატი PDF → გაზიარება → Bade | ① Welcome |
| `welcome.import` | Import statement | ამონაწერის იმპორტი | ① Welcome |
| `welcome.privacy.line1` | Nothing leaves your phone. | არაფერი ტოვებს ტელეფონს. | ① Welcome |
| `widget.allCharged` | All charged | ყველა ჩამოიჭრა | ⓦ Widget |
| `widget.description` | What your subscriptions cost a month, and what is charging next. | რამდენი ჯდება გამოწერები თვეში და რა ჩამოგეჭრება შემდეგ. | ⓦ Widget |
| `widget.locked` | Widgets are part of Bade Pro. | ვიჯეტები Bade Pro-ს ნაწილია. | ⓦ Widget |
| `widget.name` | Monthly total | თვიური ჯამი | ⓦ Widget |
| `widget.nothingLeft` | Nothing left this month | ამ თვეში აღარაფერია | ⓦ Widget |
| `widget.thisMonth` | This month | ამ თვეში | ⓦ Widget |
| `widget.toGo %@` | %@ to go | დარჩა %@ | ⓦ Widget |

---

## One thing I did not change, and think you should look at

`settings.exportName` is `Bade-ის გამოწერები`, and it is not a label — `SettingsView` resolves it
through `.badeLocalized` and hands it to `ShareLink` as the **file name**. So a Georgian user
exporting to CSV gets `Bade-ის გამოწერები.csv`. It works, and iOS handles Unicode file names, but a
hyphenated genitive is an odd thing to see in a Files listing or an email attachment. Leaving it
Georgian, transliterating it, or keeping `Bade subscriptions` in both languages are all defensible;
it is a product call, so I left it alone.

---

## To mark the pass reviewed

Once you are happy with the values, from the repo root:

```sh
python3 - <<'PY'
import json, pathlib
p = pathlib.Path("BadeKit/Sources/Localization/Localizable.xcstrings")
d = json.loads(p.read_text(encoding="utf-8"))

def mark(node):
    if isinstance(node, dict):
        if "state" in node and node.get("state") == "needs_review":
            node["state"] = "translated"
        for value in node.values():
            mark(value)

for entry in d["strings"].values():
    mark(entry.get("localizations", {}).get("ka", {}))

p.write_text(json.dumps(d, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
print("all Georgian marked translated")
PY
cd BadeKit && swift test
```

It walks into the plural substitutions too, which carry their own `state` and would otherwise be
left behind. Run `swift test` after: the catalog suite checks every key still has both languages,
neither is blank, and the placeholders match.
