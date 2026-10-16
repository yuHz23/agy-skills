---
name: test-driven-development
description: Enforces RED-GREEN-REFACTOR with a failing test written before any production code. Use whenever writing or modifying code, especially bug fixes and new features. Code written before its failing test must be deleted, not kept.
---

# Test-Driven Development

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**

## The cycle

1. **RED**: Write the smallest test that expresses the desired behavior.
   Run it. It MUST FAIL. If it passes before the code exists, the test is
   broken — fix the test, not the code.
2. **GREEN**: Write the minimum production code to make the test pass.
   Run it. It must pass.
3. **REFACTOR**: Clean up while keeping the tests green. Run the tests after
   every refactor step.

## Rules that make it real

- **Delete code written before a test.** Code written "for reference" before
  the failing test is not kept — it is deleted and rewritten test-first.
  "But it works" is not an exception; that is exactly the claim TDD exists to
  prevent.
- **A test that never failed proves nothing.** For a regression fix, run the
  verified red-green cycle: test fails on the bug → fix → passes → revert
  fix → fails again → restore fix → passes.
- **One behavior per test.** If the test can fail for more than one reason,
  split it.
- **No skipping the run.** Every RED and GREEN step requires an actual
  execution with its output read. "It should fail" / "it should pass" are
  claims — see the `verification-before-completion` skill.

## Anti-rationalization table

| Excuse | Rebuttal |
|---|---|
| "I'll add tests after it works" | Tests written after pass immediately and prove nothing about the code. Write the failing test now. |
| "It's just a small change" | Small changes are exactly where regressions hide, and the smallest tests are the cheapest to write. |
| "Testing this is hard" | Hard-to-test code is a design problem. Fix the design, don't skip the test. |
| "I already wrote the code" | Then delete it and rewrite it test-first. The second write is faster and correct. |
| "The user didn't ask for tests" | The user asked for working code. Tests are how "working" gets proven, not decoration. |

Adapted from the `test-driven-development` skill in obra/superpowers (MIT),
rewritten for the Antigravity/Gemini agent.