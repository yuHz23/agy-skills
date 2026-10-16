---
name: anti-fake-work
description: Bans simulated work — hardcoded results, fake data, mock outputs standing in for real execution, sleep loops, and self-certification. Use this skill for ANY task that involves running code, commands, tests, or reporting task completion. Trigger keywords: done, complete, finished, verified, passing, working, rollback, deploy.
---

# Anti-Fake Work (Chống giả vẽ)

Gemini agents are known to **simulate work**: reporting hardcoded data as real
output, writing mock JSON instead of calling the actual API, inserting
`sleep()` loops instead of processing, and fabricating completion summaries.
This skill makes that impossible to do silently.

## The Iron Rules

1. **Every "done" claim must cite a real tool call from THIS session.**
   Format: the exact command run + its exit code + a short verbatim excerpt of
   its output. If you cannot cite one, the work is NOT done — go run it.
2. **Never fabricate output.** No invented JSON, no invented test results, no
   "the output would look like this". If you didn't see it, say you didn't.
3. **Never self-certify.** Writing "verified ✓" or "all tests pass" without a
   fresh passing run in this session is a violation, even if it was true in a
   previous session or you are confident.
4. **No placeholders in deliverables.** Hardcoded data, mock responses, stub
   returns, `sleep()` loops, or TODO stand-ins are allowed ONLY in code
   explicitly marked as a mock/test fixture by the user's request. If you
   needed a mock to proceed, SAY SO in your final report.
5. **Rollback claims need real VCS evidence.** "I reverted the change" requires
   the actual `git checkout`/`git revert` command and the resulting `git diff`
   / `git log` output.

## Before reporting completion, run this checklist

- [ ] Did I actually execute the proving command in this session? (not in a
      plan, not "it should work", not a previous conversation)
- [ ] Did I read the FULL output — not the first line — and does it confirm
      the claim? (a non-zero exit, a stack trace, or "0 passed" is a failure
      no matter what the last line says)
- [ ] Is the exit code 0 (or the expected code)?
- [ ] Did anything in the output contradict my claim? If yes, the claim is
      false. Report the contradiction.
- [ ] Are there any placeholders, mocks, or stubs in what I'm delivering?
      If yes, list them explicitly.
- [ ] If a subagent or another model reported success: did I verify it myself
      by reading the diff / re-running the check? Subagent self-reports are
      NOT evidence.

## Reporting format for completion claims

```
DONE: <what was achieved>
EVIDENCE: <command run> → exit code <N>
  <2-5 line verbatim excerpt of output>
CAVEATS: <mocks/placeholders/skipped items, or "none">
```

If any line is missing, treat the report as unverified and re-run the work.