# Bade

iOS app that parses bank statement PDFs on-device, detects recurring subscriptions, and reports true spend including FX markup. Launch market: Georgia (BOG, TBC).

**Full spec: `docs/BADE-ENGINEERING-SPEC.md`. Read it before implementing anything. Design context: `docs/BADE-DESIGN-BRIEF.md`.**

---

## Current step

> Build order step: **1 — Core domain model**
> (Update this line when a step is finished. Steps are listed in §12 of the spec.)

---

## Working agreement

- **Write like a staff iOS engineer. Top priority.** Clean, modern Swift; SOLID; single-responsibility types; dependencies injected behind protocols where a real second implementation exists. Apply SOLID to code that exists — never invent an interface for a hypothetical future caller. When SOLID and "simplest thing that works" conflict, the simplest design that keeps responsibilities separate wins.
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
Bade.xcodeproj      thin app target — avoid touching
Bade/               app entry point only
BadeKit/            all real code (SPM, one package, many targets)
  Sources/          Core, Detection, Ingestion, Normalization,
                    FX, Catalog, Persistence, Notifications,
                    DesignSystem, Features/*
  Tests/
  Tests/Fixtures/   golden statement fixtures + expected JSON
docs/
```

Xcode project files are fragile — don't hand-edit `.pbxproj`. If a change requires the Xcode project, say so and I'll do it in Xcode.

---

## Stack

Swift 6, strict concurrency, iOS 26+, SwiftUI, MVI, SwiftData (inside `Persistence` only), Swift Testing.

---

## Testing

Golden-file tests are the backbone: real anonymised statement in → exact expected subscription set out. Every wild bug becomes a permanent fixture.

Detection engine is pure and gets exhaustive coverage, including: variable amounts, merchant renames, duplicate imports, cancel-then-resume, trial-to-paid.

Never invent a statement fixture. If a parser task needs a real statement and none exists in `Tests/Fixtures/`, stop and ask for one.
