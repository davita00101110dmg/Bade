# Bade

iOS app that parses bank statement PDFs on-device, detects recurring subscriptions, and reports true spend including FX markup. Launch market: Georgia (BOG, TBC).

**Full spec: `docs/BADE-ENGINEERING-SPEC.md`. Read it before implementing anything. Design context: `docs/BADE-DESIGN-BRIEF.md`.**

> `docs/` is intentionally not in this public repository — it carries launch strategy. Both files live locally in the working copy.

---

## Current step

> Build order step: **all of 1–14 done or decided.** 9 measured and rejected (left on the local
> branch `tier-2-normalization`, never pushed). **13 is verified — a purchase has round-tripped in a
> TestFlight sandbox build and all six gates flipped.** **10 is finished, and the answer inverted the
> question: the FX markup Bade was reporting was fabricated on every charge**, because a lari-billed
> charge with settlement rates printed beside it was read as a foreign one. **14 is written and
> waiting on the one review only a native speaker can give** — `GEORGIAN-REVIEW.md` holds the pass
> and the snippet that flips the states; it is ~14 keys stale and worth regenerating first.
> The home screen widget ships, though §13 lists widgets as out of scope for v1 — a deliberate call,
> since the Pro page sells them. The Liberty statement has no parser and is not claimed by one.
> Next: **the Georgian review**, then re-record the snapshots it invalidates, then **archive** —
> bumping `CURRENT_PROJECT_VERSION`, which must not stay at 1.
> (Update this line when a step is finished. Steps are listed in §12 of the spec.
> The screen inventory, the blocking question and the open items live in `NEXT-SESSION.md`.)

---

## Working agreement

- **Write like a staff iOS engineer. Top priority.** Clean, modern Swift; SOLID; single-responsibility types; dependencies injected behind protocols where a real second implementation exists. Apply SOLID to code that exists — never invent an interface for a hypothetical future caller. When SOLID and "simplest thing that works" conflict, the simplest design that keeps responsibilities separate wins.
- **Naming.** A feature's observable state holder is `<Feature>ViewModel`. No hex, font name, or user-facing string is ever written in a view.
- **Comments: only where necessary, one compact line. Never multi-line.** Prefer a clear name over a comment. No comment that restates the code.
- Ask about doubts, including small ones. Batch questions; don't pick silently and report afterwards.
- State assumptions explicitly. If a requirement is ambiguous, stop and ask — do not pick silently.
- Simplest thing that works. No speculative abstraction, no unrequested configurability, no error handling for impossible states. If 200 lines could be 50, write 50.
- Surgical changes. Touch only what the current task requires. Don't refactor working code or "improve" adjacent style.
- Every task ends in a passing test or demonstrable behaviour, not "it should work."
- For multi-step work, state the plan first as `step → verify: check`.
- Work one build-order step at a time. Don't jump ahead.

---

## Non-negotiable constraints

1. **`Decimal` for all money.** Never `Double`. No exceptions.
2. **No network** except optional NBG FX rate refresh. No backend, no accounts, no analytics SDK, no crash reporter that transmits user content.
3. **Statement files are never written to disk.** Parse in memory, discard immediately.
4. **The LLM never does arithmetic.** Foundation Models normalises merchant strings only. Cadence, totals, FX, and detection are deterministic Swift.
5. **The app must work fully with Apple Intelligence unavailable.** Tier-1 deterministic normalization is the floor; the LLM is an enhancement, never a dependency.
6. **No hardcoded GEL, Georgian strings, or bank-specific assumptions** outside a parser implementation. All strings localised from the first commit.
7. **Feature modules never import each other.** `Core` depends on nothing. `App` is the only module that knows about all of them.

---

## Layout

```
Bade.xcodeproj        thin app target — avoid touching
Bade/                 @main, assets, entitlements. Nothing else.
BadeKit/              all real code (SPM, one package, many targets)
  Sources/
    Core/             entities + protocols. Imports Foundation only.
    Ingestion/        PDF/text → [RawTransaction]. Parser registry.
    Normalization/    raw description → merchant. Tier 1, no LLM.
    Detection/        recurrence engine. Pure.
    Catalog/          bundled merchant database.
    Persistence/      SwiftData. Sealed — no other module imports it.
    Pipeline/         composes ingestion → normalization → detection.
    Notifications/    reminder planning (pure) + the one UserNotifications import.
    Purchases/        the one StoreKit import, behind Core's ProPurchasing.
    Widgets/          the home screen snapshot, its timeline and its views.
    DesignSystem/     theme, type, spacing, motion, haptics, components.
    Localization/     the one Localizable.xcstrings, typed constants, money format.
    Features/         Welcome, Import (Parsing + Review). One per feature.
    App/              composition root only. The one target the app links.
  Tests/
  Tests/Fixtures/     golden fixtures; local/ is gitignored (real statements)
docs/                 gitignored — spec and design brief live locally
statements/           gitignored — never commit a real statement
```

`swift test` runs the whole suite in ~2s (540 tests). Snapshot tests are separate and need a
simulator — see §Snapshot tests in `NEXT-SESSION.md`; `swift test` never even compiles them. The package declares macOS **only** so that
works on the host; Bade ships iOS-only. Occasionally an iOS-only SwiftUI API needs a shim
(`badeCover`) or a semantic alternative (`.cancellationAction` over `.topBarLeading`).

Xcode project files are fragile — don't hand-edit `.pbxproj`. If a change requires the Xcode project, say so and I'll do it in Xcode.

---

## UI conventions

Every screen meets these. They are not negotiable per-screen; fix the token, not the view.

- **No magic numbers.** `BadeSpacing` / `BadeRadius` / `BadeLayout`, written `.padding(.top, .lg)`.
  Never arithmetic on a token (`.sm + 2`) — add a token or snap to the scale.
- **A component's own dimensions** live with it (`BadeButtonMetrics`), not in the spacing scale.
- **No raw string keys.** `Text(.welcome.title)` via typed constants; a typo is a compile error.
- **No hardcoded colour or font.** `@Environment(\.badeTheme)` and the `Font.bade*` scale.
- **Money is always `.badeMoney(code)`** — always renders the symbol (₾, ₺, ֏), locale places it.
- **Motion via `.badeAnimation(_:value:)`**, named by meaning. Reduce Motion is handled inside it.
- **Haptics via `.badeFeedback(_:trigger:)`**, never the only signal for an outcome.
- **Backgrounds via `.background(...)`**, not a wrapping `ZStack`.
- **A screen exposes one outcome enum**, not a bag of `() -> Void` closures. Leaving is an intent.
- **Structure:** `<Screen>View.swift` at the feature root, `Views/` for subviews, `Models/` for
  types, `<Screen>View+Previews.swift` for previews. No non-view types in a view file.
  A module holding two screens nests one folder per screen (`Import/Parsing/`, `Import/Review/`)
  and keeps only genuinely shared types at its root.
- **Previews** cover both languages, both appearances and large text, and are explicitly typed —
  previews rewrite literals into `__designTimeString`, and inference through that defeats the compiler.
- **Check every state has a way out.** A screen with no exit is a trapped user.

---

## Stack

Swift 6, strict concurrency, iOS 26+, SwiftUI, MVI, SwiftData (inside `Persistence` only), Swift Testing.

---

## Testing

Golden-file tests are the backbone: real anonymised statement in → exact expected subscription set out. Every wild bug becomes a permanent fixture.

Detection engine is pure and gets exhaustive coverage, including: variable amounts, merchant renames, duplicate imports, cancel-then-resume, trial-to-paid.

Never invent a statement fixture. If a parser task needs a real statement and none exists in `Tests/Fixtures/`, stop and ask for one.
