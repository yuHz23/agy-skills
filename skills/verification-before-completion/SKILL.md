---
name: verification-before-completion
description: Enforces the gate between doing work and claiming it is done. Use before ANY positive statement about work state — "tests pass", "bug fixed", "build succeeds", "it works" — including paraphrases and implications, and before every commit or PR.
---

# Verification Before Completion

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

Following the letter of this skill while violating its spirit is itself a
violation. Confidence is not evidence. Memory of a past run is not evidence.
A subagent's word is not evidence.

## The Gate Function (run before every status claim)

1. **Identify the proving command.** What single command would prove the claim
   false if the claim were false? That is the command to run.
2. **Run it fresh, in this session.** Not from memory, not cached, not from a
   previous conversation.
3. **Read the entire output.** Not the tail. Check the exit code.
4. **Check the output actually confirms the claim.** "Command exited 0" is
   not enough — the output must contain what you said would be true.
5. **Only now make the claim**, and cite the command + exit code + output.

## Claims → required evidence

| Claim | Sufficient evidence | NOT sufficient |
|---|---|---|
| "Tests pass" | Fresh test run, exit 0, expected pass count in output | "I wrote tests", a past run, green checkmarks from memory |
| "Bug fixed" | Repro command that used to fail now passes, shown in output | "The fix addresses the root cause" |
| "Build succeeds" | Fresh build command, exit 0 | No build errors *mentioned* |
| "Feature works" | The feature exercised end-to-end with real I/O | Type checks; code "looks right" |
| "Requirement met" | Each acceptance criterion mapped to observed output | Partial coverage of the spec |
| "Subagent finished" | Their diff read / their check re-run by you | The subagent said "done" |
| "Reverted" | `git diff`/`git log` showing the revert | "I undid the change" |

## Red flags — STOP and verify before saying any of these

- Hedging: "should", "probably", "I believe", "it should now", "essentially done"
- Satisfaction before verification: "Done!" / "Perfect!" with no run shown
- Restating the plan as if the plan were the result
- Trusting a report (yours from memory, a subagent's, a tool's) without re-checking
- Skipping a verification because "it takes too long" — that is exactly when a
  claim gets made falsely

## Rationalizations → rebuttals

| Rationalization | Rebuttal |
|---|---|
| "I'm confident it works" | Confidence is not evidence. Run the command. |
| "I tested something similar earlier" | Different input, different run, different claim. Re-run. |
| "The change is small, low risk" | Small changes break builds constantly. Run it. |
| "Verifying would waste tokens/time" | A false 'done' costs far more than the verifying run. |
| "The user will check anyway" | Then say "not verified" instead of "done". |
| "I verified part of it" | Then the claim is about that part only. Scope it honestly. |

## Verified red-green cycle (for bug-fix claims)

A test that never failed proves nothing. For a "bug fixed" claim:

1. Write the regression test. Run it — it MUST FAIL (proves the test detects
   the bug).
2. Apply the fix. Run it — it MUST PASS.
3. Revert only the fix. Run it — it MUST FAIL again (proves the test, not
   luck, is doing the work).
4. Restore the fix. Run it — it passes. Claim done, citing this cycle.

Adapted from the `verification-before-completion` skill in
obra/superpowers (MIT), rewritten for the Antigravity/Gemini agent.