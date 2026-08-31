# Georgian review — badeapp.com (annotated)

Every Georgian string on the site, with the English it was written from.
65 strings.

**What this pass is.** Each `KA:` line was checked against the app's own Georgian
in `BadeKit/Sources/Localization/Localizable.xcstrings` (242 keys, `ka` complete).
Where the app already has a settled word for something — ამონაწერი, გამოწერა,
ჩამოჭრა, პარამეტრები, შენაძენი, კურსი — the site now uses the same one, and the
app key is named in the note. Where the Georgian was simply awkward or
ungrammatical and the app had nothing to say, it is rewritten and the reason given.

A `FIX:` line means *replace the `KA:` line above it*. A `NOTE:` line with no `FIX:`
is a question or an observation, not a change. Strings with neither were left alone —
they were already right.

IDs are unchanged.

**Open questions are collected at the bottom** — five of them, and the register one
affects every string on the site.


## Landing page — `index.html`

### IND-01
EN: The subscriptions you forgot about.
KA: გამოწერები, რომლებიც დაგავიწყდათ.

### IND-02
EN: Bade reads your bank statement and finds everything charging you month after month — including what the exchange rate quietly added. All of it on your iPhone.
KA: Bade კითხულობს თქვენს საბანკო ამონაწერს და პოულობს ყველაფერს, რაც ყოველთვიურად გიჯდებათ — მათ შორის იმას, რაც ვალუტის კურსმა ჩუმად დაამატა. ყველაფერი თქვენს iPhone-ზე.
FIX: Bade კითხულობს თქვენს საბანკო ამონაწერს და პოულობს ყველაფერს, რაც თვიდან თვემდე ჩამოგეჭრებათ — მათ შორის იმას, რაც ვალუტის კურსმა ჩუმად დაამატა. ყველაფერი თქვენს iPhone-ზე.
NOTE: „ყოველთვიურად გიჯდებათ“ flattens "month after month" into a rate; the app's verb for a charge landing is ჩამოჭრა (`reminder.tomorrow`, `settings.remindersFooter`), which also restores "charging you".

### IND-03
EN: Download on the App Store
KA: ჩამოტვირთეთ App Store-დან

### IND-04
EN: iPhone · iOS 26 or later · Free to try
KA: iPhone · iOS 26 ან უფრო ახალი · უფასოდ საცდელი
FIX: iPhone · iOS 26 ან უფრო ახალი · გამოცდა უფასოა
NOTE: „უფასოდ საცდელი“ is not idiomatic — საცდელი is an adjective left without its noun, and it reads as "free trial period", which Bade does not offer (Pro is a one-time purchase). See question 3.

### IND-05
EN: How it works
KA: როგორ მუშაობს

### IND-06
EN: Give it a statement. It does the rest.
KA: მიეცით ამონაწერი. დანარჩენს თავად აკეთებს.
FIX: მიეცით ამონაწერი — დანარჩენს თავად გააკეთებს.
NOTE: Present აკეთებს describes a habit; the English is a promise about this statement, which Georgian puts in the future.

### IND-07
EN: Reads your bank's PDF
KA: კითხულობს ბანკის PDF-ს

### IND-08
EN: Export a statement from Bank of Georgia or TBC and hand it over. In Georgian or English — Bade reads both.
KA: გადმოწერეთ ამონაწერი საქართველოს ბანკიდან ან TBC-დან. ქართულად თუ ინგლისურად — Bade ორივეს კითხულობს.
FIX: ჩამოტვირთეთ ამონაწერი საქართველოს ბანკიდან ან თიბისიდან და გადააწოდეთ Bade-ს. ქართულად თუ ინგლისურად — Bade ორივეს კითხულობს.
NOTE: Three things. The app writes the bank as თიბისი in Georgian script (`parsing.betaNote`: „საქართველოს ბანკისა და თიბისის ამონაწერებს“) — see question 4. The app's verb for getting a statement out of a bank is ჩამოტვირთვა (`welcome.guide.title`). And "and hand it over" was dropped entirely from the Georgian; it is the actual instruction in the sentence.

### IND-09
EN: Finds what repeats
KA: პოულობს განმეორებადს
FIX: პოულობს იმას, რაც მეორდება
NOTE: განმეორებადს is a bare adjective in the dative with no noun to attach to. The app says „ყველა განმეორებად ტრანზაქციას“ (`welcome.subtitle`) — with the noun present. Here the headline wants no noun, so the relative clause does the work.

### IND-10
EN: Monthly, yearly, weekly. Price rises, free trials that turned into charges, and the ones you cancelled and forgot you resumed.
KA: თვიური, წლიური, კვირეული. ფასის ზრდა, უფასო საცდელები, რომლებიც გადახდად იქცა, და ისინი, რომლებიც გააუქმეთ და დაგავიწყდათ რომ განაახლეთ.
FIX: ყოველთვიური, წლიური, ყოველკვირეული. ფასის ზრდა, უფასო საცდელი პერიოდები, რომლებიც გადახდაში გადაიზარდა, და ის გამოწერები, რომლებიც გააუქმეთ, მერე კი განაახლეთ და დაგავიწყდათ.
NOTE: The cadence words are wrong against the app: `cadence.monthly` is ყოველთვიური and `cadence.weekly` is ყოველკვირეული (თვიური / კვირეული appear nowhere). „საცდელები“ has the same bare-adjective problem as IND-09. And the last clause is a calque of the English word order that Georgian can't hold — the cancel-then-resume-then-forget sequence has to be told in order.

### IND-11
EN: Counts the real cost
KA: ითვლის ნამდვილ ღირებულებას
FIX: ითვლის რეალურ ხარჯს
NOTE: ღირებულება is a thing's worth; what Bade counts is what left your account. The app consistently frames this as spending — „რამდენს ხარჯავ თვეში?“ (`welcome.title`), „რამდენი გიჯდება“ (`widget.description`).

### IND-12
EN: A charge in dollars costs more than the sticker price. Bade uses the rate your bank actually applied, not an average.
KA: დოლარში გადახდა უფრო ძვირი ჯდება, ვიდრე მითითებული ფასი. Bade იყენებს იმ კურსს, რომელიც ბანკმა რეალურად გამოიყენა და არა საშუალოს.
FIX: დოლარში გადახდა იმაზე ძვირი ჯდება, ვიდრე ფასზე წერია. Bade იყენებს იმ კურსს, რომელიც ბანკმა რეალურად გამოიყენა, და არა საშუალოს.
NOTE: „მითითებული ფასი“ compares a payment to a price, which limps; "sticker price" is idiomatically "what it says on the price". Second sentence needs the comma before და არა — otherwise it reads as a second thing the bank applied.

### IND-13
EN: Warns you before it charges
KA: გაფრთხილებთ გადახდამდე
FIX: გაფრთხილებთ ჩამოჭრამდე
NOTE: Same word as IND-02 — the app's `settings.remindersFooter` is literally „შეხსენებები ჩამოჭრამდე“. გადახდა is you paying; ჩამოჭრა is money being taken, which is the point of the reminder.

### IND-14
EN: A reminder before the next renewal, so cancelling is still a choice rather than a regret.
KA: შეხსენება მომდევნო განახლებამდე, რომ გაუქმება ჯერ კიდევ არჩევანი იყოს და არა სინანული.
NOTE: Matches `pro.reminders` („განახლების შეხსენებები“) and reads well. Left alone.

### IND-15
EN: Privacy
KA: კონფიდენციალურობა

### IND-16
EN: Your statement never leaves your phone.
KA: თქვენი ამონაწერი არასდროს ტოვებს ტელეფონს.
NOTE: Exactly the app's `welcome.privacy.line1` („არაფერი ტოვებს ტელეფონს.“) in formal register. Left alone.

### IND-17
EN: Not "we don't sell your data." Bade has no account to sign into, no server to send anything to, and no analytics. Your statement is read in memory and never written to disk — not even a cached copy.
KA: არა „ჩვენ არ ვყიდით თქვენს მონაცემებს“. Bade-ს არ აქვს ანგარიში, არ აქვს სერვერი, სადაც რამე გაიგზავნება, და არ აქვს ანალიტიკა. თქვენი ამონაწერი იკითხება მეხსიერებაში და არასდროს ეწერება დისკზე — ქეშირებული ასლიც კი არა.
FIX: არა „ჩვენ არ ვყიდით თქვენს მონაცემებს“. Bade-ს არ აქვს ანგარიში, რომელშიც უნდა შეხვიდეთ, არც სერვერი, რომელსაც რამე გაეგზავნება, არც ანალიტიკა. თქვენი ამონაწერი ოპერატიულ მეხსიერებაში იკითხება და დისკზე არასდროს იწერება — ქეშირებული ასლიც კი არა.
NOTE: Four repairs. "No account to sign into" lost its relative clause — bare „არ აქვს ანგარიში“ contradicts PRI-16, where Bade does deal with an Apple account. „სერვერი, სადაც რამე გაიგზავნება“ uses the locative სადაც for a recipient; it needs რომელსაც. The three-fold არ აქვს … არ აქვს … არ აქვს is heavier than the English; არც … არც carries it. And მეხსიერება alone is the same word this document uses for on-device storage in PRI-05/PRI-06 — the contrast the sentence is built on disappears unless RAM is ოპერატიული მეხსიერება. Finally ეწერება → იწერება.

### IND-18
EN: The app reaches the network in exactly one case: fetching the National Bank of Georgia's published exchange rates. That request carries a currency code and a date, and nothing else.
KA: აპლიკაცია ინტერნეტს მხოლოდ ერთ შემთხვევაში მიმართავს: საქართველოს ეროვნული ბანკის გამოქვეყნებული კურსების წამოსაღებად. ეს მოთხოვნა შეიცავს მხოლოდ ვალუტის კოდსა და თარიღს.
FIX: აპლიკაცია ინტერნეტს მხოლოდ ერთ შემთხვევაში მიმართავს: საქართველოს ეროვნული ბანკის გამოქვეყნებული კურსების ჩამოსატვირთად. ეს მოთხოვნა მხოლოდ ვალუტის კოდსა და თარიღს შეიცავს, სხვას არაფერს.
NOTE: The setting this describes is `settings.rates` — „ოფიციალური კურსების ჩამოტვირთვა“ — so the verb should be the same one the user will see in Settings, not წამოღება. "And nothing else" is a deliberate second beat in the English and was dropped; „სხვას არაფერს“ restores it.

### IND-19
EN: Read the full privacy policy →
KA: სრული კონფიდენციალურობის პოლიტიკა →
FIX: წაიკითხეთ კონფიდენციალურობის სრული პოლიტიკა →
NOTE: As written, სრული attaches to კონფიდენციალურობა — "the full-privacy policy". The adjective belongs to პოლიტიკა. The verb was also dropped, which matters because this is a link.

### IND-20
EN: Built for Georgia first
KA: შექმნილია პირველ რიგში საქართველოსთვის

### IND-21
EN: Bade speaks Georgian and English throughout, shows money with the symbol it belongs to, and understands the statement formats the banks here actually export — not a generic parser that half-works everywhere.
KA: Bade სრულად საუბრობს ქართულად და ინგლისურად, თანხას აჩვენებს მისივე სიმბოლოთი და ესმის იმ ამონაწერების ფორმატები, რომლებსაც აქაური ბანკები რეალურად აგზავნიან — და არა ზოგადი პარსერი, რომელიც ყველგან ნახევრად მუშაობს.
FIX: Bade სრულად საუბრობს ქართულად და ინგლისურად, თანხას მისივე სიმბოლოთი აჩვენებს და იცნობს იმ ამონაწერების ფორმატებს, რომლებსაც აქაური ბანკები რეალურად გასცემენ — და არა ზოგადი პარსერი, რომელიც ყველგან ნახევრად მუშაობს.
NOTE: „ესმის ... ფორმატები“ is the wrong case frame — ესმის takes a nominative subject, so the sentence loses Bade as its actor mid-clause. იცნობს + dative keeps Bade the subject across all three verbs, which the English needs. აგზავნიან means the banks send them somewhere; they issue them (გასცემენ) and you export them. See question 2 about პარსერი.

### IND-22
EN: Privacy
KA: კონფიდენციალურობა

### IND-23
EN: Support
KA: მხარდაჭერა


## Privacy policy — `privacy.html`

### PRI-01
EN: Privacy Policy
KA: კონფიდენციალურობის პოლიტიკა

### PRI-02
EN: Last updated 31 August 2026
KA: ბოლო განახლება: 2026 წლის 31 აგვისტო
NOTE: Georgian is correct. But `privacy.html` in this repo still says "last updated 22 August 2026" — see question 5.

### PRI-03
EN: Bade is designed so that there is almost nothing to write a policy about. It has no account system, no backend, and no analytics. This page describes exactly what the app does with your information, which is very little.
KA: Bade ისეა შექმნილი, რომ პოლიტიკისთვის თითქმის არაფერია დასაწერი. მას არ აქვს ანგარიშის სისტემა, სერვერი და ანალიტიკა. ეს გვერდი ზუსტად აღწერს, რას აკეთებს აპლიკაცია თქვენს ინფორმაციასთან — და ეს ძალიან ცოტაა.

### PRI-04
EN: Your bank statements
KA: თქვენი საბანკო ამონაწერები

### PRI-05
EN: When you import a statement, it is read into memory, parsed on your device, and discarded. The file itself is never copied into the app's storage, never written to disk, and never uploaded anywhere. Closing the import screen ends its life entirely.
KA: როცა ამონაწერს შემოიტანთ, ის იკითხება მეხსიერებაში, მუშავდება თქვენს მოწყობილობაზე და იშლება. თავად ფაილი არასდროს კოპირდება აპლიკაციის მეხსიერებაში, არასდროს იწერება დისკზე და არსად იტვირთება. იმპორტის ეკრანის დახურვა მთლიანად ასრულებს მის არსებობას.
FIX: როცა ამონაწერს შემოიტანთ, ის ოპერატიულ მეხსიერებაში იკითხება, თქვენს მოწყობილობაზე მუშავდება და იშლება. თავად ფაილი არასდროს კოპირდება აპლიკაციის საცავში, არასდროს იწერება დისკზე და არსად იტვირთება. იმპორტის ეკრანის დახურვა მთლიანად ასრულებს მის არსებობას.
NOTE: The paragraph uses მეხსიერება twice for two opposite things — the RAM the file is read into, and the storage it is never copied to. As written it says the file is read into memory and never copied into memory. RAM is ოპერატიული მეხსიერება, app storage is საცავი.

### PRI-06
EN: What is kept is the result: the subscriptions found, their amounts, dates and currencies. That stays on your device, in the app's own storage. Deleting the app deletes it.
KA: ინახება მხოლოდ შედეგი: ნაპოვნი გამოწერები, მათი თანხები, თარიღები და ვალუტები. ეს რჩება თქვენს მოწყობილობაზე, აპლიკაციის საკუთარ მეხსიერებაში. აპლიკაციის წაშლა შლის მას.
FIX: ინახება მხოლოდ შედეგი: ნაპოვნი გამოწერები, მათი თანხები, თარიღები და ვალუტები. ეს რჩება თქვენს მოწყობილობაზე, აპლიკაციის საკუთარ საცავში. აპლიკაციის წაშლა შლის მას.
NOTE: Same storage word as PRI-05.

### PRI-07
EN: What leaves your device
KA: რა ტოვებს თქვენს მოწყობილობას

### PRI-08
EN: One thing, and only if exchange rates are needed: a request to the National Bank of Georgia's public rate service. It sends a currency code and a date. It carries no identifier, no statement content, and nothing about you. You can switch it off in Settings, and the app works without it.
KA: მხოლოდ ერთი რამ და ისიც მაშინ, თუ საჭიროა ვალუტის კურსი: მოთხოვნა საქართველოს ეროვნული ბანკის საჯარო სერვისისკენ. ის აგზავნის ვალუტის კოდსა და თარიღს. არ შეიცავს იდენტიფიკატორს, ამონაწერის შიგთავსს ან რაიმეს თქვენს შესახებ. მისი გამორთვა შეგიძლიათ პარამეტრებში და აპლიკაცია მის გარეშეც მუშაობს.
FIX: მხოლოდ ერთი რამ და ისიც მაშინ, თუ ვალუტის კურსია საჭირო: მოთხოვნა საქართველოს ეროვნული ბანკის საჯარო კურსების სერვისთან. ის აგზავნის ვალუტის კოდსა და თარიღს. არ შეიცავს იდენტიფიკატორს, ამონაწერის შიგთავსს ან რაიმეს თქვენს შესახებ. მისი გამორთვა პარამეტრებში შეგიძლიათ და აპლიკაცია მის გარეშეც მუშაობს.
NOTE: -კენ is directional motion ("towards the service"); a request is made to a service — სერვისთან. "Rate service" also lost კურსების, which is what makes it obvious the request is about money and not about you. Settings is პარამეტრები, matching `settings.title`.

### PRI-09
EN: What Bade does not do
KA: რას არ აკეთებს Bade

### PRI-10
EN: No account, no sign-in, no email address collected.
KA: არ არის ანგარიში, შესვლა და არ გროვდება ელფოსტა.
FIX: არც ანგარიში, არც შესვლა, არც ელფოსტის შეგროვება.
NOTE: The English is three parallel negations; the Georgian breaks the parallel by switching verbs halfway („არ არის … და არ გროვდება“), which reads as a list that lost its thread. This is also the first bullet of five — PRI-11 through PRI-14 all open with არანაირი/არაფერი, so the parallel matters.

### PRI-11
EN: No analytics, telemetry or usage tracking of any kind.
KA: არანაირი ანალიტიკა, ტელემეტრია ან გამოყენების თვალთვალი.

### PRI-12
EN: No advertising, and no advertising identifiers.
KA: არანაირი რეკლამა და სარეკლამო იდენტიფიკატორები.

### PRI-13
EN: No third-party SDKs that transmit your content.
KA: არანაირი მესამე მხარის SDK, რომელიც თქვენს შიგთავსს გადასცემს.

### PRI-14
EN: Nothing sold or shared with anyone, because nothing is collected.
KA: არაფერი იყიდება და არავის უზიარდება, რადგან არაფერი გროვდება.

### PRI-15
EN: Purchases
KA: შენაძენები
NOTE: Matches the app's `pro.restore` („შენაძენის აღდგენა“). Left alone.

### PRI-16
EN: Bade Pro is a one-time purchase handled entirely by Apple through the App Store. Bade never sees your payment details — it only asks the system whether a purchase exists. Apple's own privacy policy covers that transaction.
KA: Bade Pro არის ერთჯერადი შენაძენი, რომელსაც სრულად ამუშავებს Apple App Store-ის მეშვეობით. Bade არასდროს ხედავს თქვენს გადახდის მონაცემებს — ის მხოლოდ ეკითხება სისტემას, არსებობს თუ არა შენაძენი. ამ ტრანზაქციას ფარავს Apple-ის კონფიდენციალურობის პოლიტიკა.
FIX: Bade Pro არის ერთჯერადი შენაძენი, რომელსაც სრულად Apple უზრუნველყოფს App Store-ის მეშვეობით. Bade არასდროს ხედავს თქვენს გადახდის მონაცემებს — ის მხოლოდ ეკითხება სისტემას, არსებობს თუ არა შენაძენი. ამ ტრანზაქციას ფარავს Apple-ის კონფიდენციალურობის პოლიტიკა.
NOTE: ამუშავებს means "sets in motion / starts up", not "handles". Also „ამუშავებს Apple App Store-ის მეშვეობით“ puts Apple next to App Store, so it reads at a glance as "Apple App Store" — moving the verb fixes both.

### PRI-17
EN: Notifications
KA: შეტყობინებები

### PRI-18
EN: Renewal reminders are scheduled locally on your device. There are no push notifications, and no server knows when your subscriptions renew.
KA: განახლების შეხსენებები იგეგმება ლოკალურად, თქვენს მოწყობილობაზე. push-შეტყობინებები არ არსებობს და არცერთმა სერვერმა არ იცის, როდის განახლდება თქვენი გამოწერები.
NOTE: „განახლების შეხსენებები“ is the app's `pro.reminders` verbatim. Left alone.

### PRI-19
EN: Children
KA: ბავშვები

### PRI-20
EN: Bade is not directed at children and collects no personal information from anyone, regardless of age.
KA: Bade არ არის განკუთვნილი ბავშვებისთვის და არ აგროვებს პერსონალურ ინფორმაციას არავისგან, ასაკის მიუხედავად.

### PRI-21
EN: Changes
KA: ცვლილებები

### PRI-22
EN: If this policy changes, the date at the top changes with it. Any change that affects what leaves your device will be described here plainly rather than buried.
KA: თუ ეს პოლიტიკა შეიცვლება, ზემოთ მითითებული თარიღიც შეიცვლება. ნებისმიერი ცვლილება, რომელიც შეეხება მოწყობილობიდან გამავალ ინფორმაციას, აქ პირდაპირ იქნება აღწერილი.

### PRI-23
EN: Contact
KA: კონტაქტი

### PRI-24
EN: Questions about this policy: support@badeapp.com
KA: კითხვები ამ პოლიტიკაზე: support@badeapp.com

### PRI-25
EN: Home
KA: მთავარი

### PRI-26
EN: Support
KA: მხარდაჭერა


## Support page — `support.html`

### SUP-01
EN: Support
KA: მხარდაჭერა

### SUP-02
EN: Something not working, or a statement Bade cannot read? Write to support@badeapp.com and describe what happened. Please do not attach your bank statement — it is not needed, and I would rather you kept it.
KA: რამე არ მუშაობს, ან Bade ვერ კითხულობს ამონაწერს? მომწერეთ support@badeapp.com და აღწერეთ, რა მოხდა. გთხოვთ, არ მიამაგროთ თქვენი საბანკო ამონაწერი — ის საჭირო არ არის და მირჩევნია, თქვენთან დარჩეს.
NOTE: The last clause keeps the English's first person, which is unusual for a policy page but is clearly deliberate here. Left alone.

### SUP-03
EN: Which statements does Bade read?
KA: რომელ ამონაწერებს კითხულობს Bade?

### SUP-04
EN: PDF statements exported from Bank of Georgia and TBC, in either Georgian or English. Export the statement from your bank's app or internet bank, then hand the file to Bade.
KA: PDF ამონაწერები, გადმოწერილი საქართველოს ბანკიდან და TBC-დან, ქართულად ან ინგლისურად. გადმოწერეთ ამონაწერი ბანკის აპლიკაციიდან ან ინტერნეტბანკიდან და გადაეცით ფაილი Bade-ს.
FIX: PDF ამონაწერები, საქართველოს ბანკიდან და თიბისიდან ჩამოტვირთული, ქართულად ან ინგლისურად. ჩამოტვირთეთ ამონაწერი ბანკის აპლიკაციიდან ან ინტერნეტბანკიდან და გადააწოდეთ ფაილი Bade-ს.
NOTE: Same two as IND-08 — თიბისი per `parsing.betaNote`, ჩამოტვირთვა per `welcome.guide.title`. „გადაეცით“ is handing something to a person; a file goes to an app as გადააწოდეთ. Georgian also prefers the participle before the noun it modifies here.

### SUP-05
EN: A subscription is missing
KA: გამოწერა აკლია

### SUP-06
EN: Bade needs to see a charge repeat before it can call it a subscription, so a longer statement finds more. If something is still missing, add it by hand — that entry behaves exactly like a detected one, and later imports will keep it up to date.
KA: Bade-ს სჭირდება დაინახოს გადახდის განმეორება, სანამ მას გამოწერად ჩათვლის, ამიტომ უფრო გრძელი პერიოდის ამონაწერი მეტს პოულობს. თუ რამე მაინც აკლია, დაამატეთ ხელით — ეს ჩანაწერი ზუსტად ისე მუშაობს, როგორც ავტომატურად ნაპოვნი, და შემდგომი იმპორტები მას განაახლებს.
FIX: სანამ ჩამოჭრას გამოწერად ჩათვლის, Bade-მ უნდა დაინახოს, რომ ის მეორდება — ამიტომ რაც უფრო გრძელი პერიოდის ამონაწერია, მით მეტს პოულობს. თუ რამე მაინც აკლია, დაამატეთ ხელით — ეს ჩანაწერი ზუსტად ისე მუშაობს, როგორც ავტომატურად ნაპოვნი, და შემდგომი იმპორტები მას განაახლებენ.
NOTE: „შემდგომი იმპორტები … განაახლებს“ is a plural subject with a singular verb — the one outright agreement error in the document. The opening is also an English clause order Georgian can't hold („სჭირდება დაინახოს … სანამ“); putting the სანამ clause first is how Georgian says it. ხელით დამატება matches `welcome.addManually`.

### SUP-07
EN: The totals look wrong
KA: ჯამები არასწორად გამოიყურება

### SUP-08
EN: Charges in another currency are converted using the rate your bank actually applied, taken from the statement itself. Where a statement never converted a pair, Bade falls back to the National Bank of Georgia's published rate, which needs rate fetching enabled in Settings.
KA: სხვა ვალუტაში გადახდები კონვერტირდება იმ კურსით, რომელიც ბანკმა რეალურად გამოიყენა და რომელიც თავად ამონაწერშია. თუ ამონაწერს კონკრეტული წყვილი არასდროს გადაუყვანია, Bade იყენებს საქართველოს ეროვნული ბანკის გამოქვეყნებულ კურსს, რისთვისაც პარამეტრებში ჩართული უნდა იყოს კურსების წამოღება.
FIX: სხვა ვალუტაში ჩამოჭრები კონვერტირდება იმ კურსით, რომელიც ბანკმა რეალურად გამოიყენა და რომელიც თავად ამონაწერშია. თუ ამონაწერში ესა თუ ის ვალუტის წყვილი არასდროს კონვერტირებულა, Bade იყენებს საქართველოს ეროვნული ბანკის გამოქვეყნებულ კურსს — ამისთვის პარამეტრებში ჩართული უნდა იყოს „ოფიციალური კურსების ჩამოტვირთვა“.
NOTE: The setting has a name the user will actually see, and it is `settings.rates` — „ოფიციალური კურსების ჩამოტვირთვა“. Naming it in quotes is worth more than describing it. „ამონაწერს … გადაუყვანია“ makes the statement the actor doing the converting, which is odd; and კურსი is the term the app uses throughout (`detail.fx.*`), so the pair should be converted, not "carried across".

### SUP-09
EN: Restoring Bade Pro
KA: Bade Pro-ს აღდგენა

### SUP-10
EN: On a new device, open the Pro page and choose "Restore a purchase". Pro is a one-time purchase tied to your Apple Account, so it comes back at no cost as long as you are signed in with the account that bought it.
KA: ახალ მოწყობილობაზე გახსენით Pro გვერდი და აირჩიეთ „შენაძენის აღდგენა“. Pro არის ერთჯერადი შენაძენი, დაკავშირებული თქვენს Apple Account-თან, ამიტომ ის უფასოდ ბრუნდება, თუ შესული ხართ იმავე ანგარიშით, რომლითაც შეიძინეთ.
FIX: ახალ მოწყობილობაზე გახსენით Pro გვერდი და აირჩიეთ „შენაძენის აღდგენა“. Pro არის ერთჯერადი შენაძენი, დაკავშირებული თქვენს Apple ანგარიშთან, ამიტომ ის უფასოდ ბრუნდება, თუ შესული ხართ იმავე ანგარიშით, რომლითაც შეიძინეთ.
NOTE: „შენაძენის აღდგენა“ is `pro.restore` verbatim — good. But the app writes the account as Apple ანგარიში (`pro.nothingToRestore`: „ამ Apple ანგარიშზე შენაძენი ვერ მოიძებნა“), not Apple Account-. Leaving it in English also forces the awkward Latin-plus-Georgian-case „Account-თან“ one clause before the Georgian ანგარიშით appears anyway.

### SUP-11
EN: Deleting your data
KA: მონაცემების წაშლა

### SUP-12
EN: Settings has an option to erase everything Bade has stored. Deleting the app does the same. Nothing survives elsewhere, because nothing was ever sent anywhere.
KA: პარამეტრებში არის ყველა შენახული მონაცემის წაშლის ვარიანტი. აპლიკაციის წაშლა იმავეს აკეთებს. სხვაგან არაფერი რჩება, რადგან არაფერი გაგზავნილა.
FIX: პარამეტრებში არის „ყველაფრის წაშლა“ — ის შლის ყველაფერს, რაც Bade-ს აქვს შენახული. აპლიკაციის წაშლა იმავეს აკეთებს. სხვაგან არაფერი რჩება, რადგან არაფერი გაგზავნილა.
NOTE: Same reasoning as SUP-08 — the control has a name in the app, `subscriptions.deleteAll` („ყველაფრის წაშლა“), and the wording of its confirmation is „წაიშლება ყველა გამოწერა და კურსი, რაც Bade-ს აქვს შენახული“. „წაშლის ვარიანტი“ is also a stack of three genitives, which Georgian reads slowly.

### SUP-13
EN: Requirements
KA: მოთხოვნები

### SUP-14
EN: iPhone running iOS 26 or later.
KA: iPhone iOS 26 ან უფრო ახალი ვერსიით.

### SUP-15
EN: Home
KA: მთავარი

### SUP-16
EN: Privacy
KA: კონფიდენციალურობა


## Questions

**1 — Register: the site and the app disagree, on every single string.**
This is the one that needs an answer before anything ships. The site is formal
plural throughout (თქვენი ამონაწერი, გადმოწერეთ, დაგავიწყდათ). The app is
informal singular throughout — „შენს გამოწერებში“, „რამდენს ხარჯავ თვეში?“,
„დააიმპორტე ამონაწერი“, „შეიტყობ“. Someone who reads the landing page and then
opens the app is addressed two different ways.

It is defensible either way — a public site can be formal while the app is
intimate, and Georgian marketing does often keep თქვენ. But it should be a
decision, not an accident. I have kept formal in this pass, since that is what
the document already was, and switching is mechanical either way (~30 strings
carry a person marker). Tell me which and I will make the whole site consistent.

**2 — „პარსერი“ in IND-21.**
A transliterated developer word on a consumer landing page. The alternative is
„ზოგადი წამკითხველი“, which is plain Georgian but vaguer. If the audience is
tech-literate Tbilisi, პარსერი is fine and I would keep it. Your call.

**3 — "Free to try" (IND-04).**
No app string to borrow from — Bade's free tier has no name in the product. My
„გამოცდა უფასოა“ is a rewrite, not a translation. „უფასოდ გამოსაცდელი“ also
works. If you have a phrase you use for this in the App Store listing, use that
one instead and I will match it.

**4 — თიბისი or TBC?**
The app writes it in Georgian script (`parsing.betaNote`). I have followed the
app in IND-08 and SUP-04. But TBC's own Georgian-language marketing uses the
Latin logotype, so if you would rather the site match the bank's own usage, say
so — and then the app's `parsing.betaNote` is the string that should change, for
consistency in the other direction.

**5 — The date in PRI-02 vs `privacy.html`.**
Not a translation issue. The review document says the policy was last updated
31 August 2026; the `privacy.html` committed in this repo says 22 August 2026,
and its text is an older, shorter draft than the one PRI-01…PRI-26 translate.
So the live site is ahead of the repo. Which is authoritative? If the live pages
are, the two HTML files here are stale and should be replaced by what is
actually deployed — otherwise the next edit to them will quietly revert the site.

**One more thing.** There is no `index.html` in this repository, so I reviewed the
landing-page strings from this document alone and could not check them against
the real markup — line breaks, `<strong>` placement, or a string that has since
changed on the live site. If you drop the site's files in here I will re-check
the whole set against them.
