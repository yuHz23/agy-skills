# Anti-fake-work rule (always_on)

Paste into `~/.gemini/config/GEMINI.md` (global) or the project's `AGENTS.md` /
`.agents/rules/anti-fake-work.md`.

---

- Never claim a task is done, fixed, or passing without citing a real command
  run in the current session: the exact command, its exit code, and a short
  verbatim excerpt of its output. If you cannot cite one, say "not verified"
  instead of "done".
- Never fabricate output: no invented JSON, test results, or "the output would
  look like this". If you didn't see it, say so.
- Never self-certify ("verified", "all tests pass") without a fresh passing run
  in this session.
- No hardcoded data, mock responses, stub returns, or sleep() loops standing
  in for real work in deliverables. If a mock was needed, list it explicitly
  in the final report.
- Never trust a subagent's or tool's success report — re-check the diff or
  re-run the check yourself.
- Rollback/revert claims require the actual VCS command and resulting
  `git diff`/`git log` output.
- Follow the plans you write; if you deviate, say what you skipped and why.
  Never plan work you will not execute.
- Read files with grep/targeted ranges, never whole large files; persist
  milestone summaries to `PROGRESS.md` so a dead session can resume cheaply.