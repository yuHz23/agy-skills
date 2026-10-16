---
name: token-frugality
description: Keeps the agent's context window from blowing up and stops token waste. Use in EVERY session — it governs how files are read, how progress is persisted, and how long responses may be. Especially critical in Antigravity, which lacks automatic context compaction and dies with "prompt is too long".
---

# Token Frugality

Antigravity has **no automatic context compaction**: when the conversation
hits the model's context limit, the agent dies with a fatal
"prompt is too long". Verbose models make this worse. This skill is the
workaround.

## Reading files

- **Grep first, read second.** Search for the symbol/pattern, then read only
  the relevant line range. Never open a large file whole.
- **Use structural tools** (outline/symbol search) before full reads when
  available.
- **Never dump file contents into the conversation** — the code is on disk;
  the user can open it. Quote only the few lines you are discussing.
- One read of each file region per session. If you need it again, you failed
  to note it the first time — write notes instead of re-reading.

## Persisting state (the compaction workaround)

- After each completed milestone, append a short summary to `PROGRESS.md` in
  the workspace root: what changed, what passed (with command), what is next.
- When context grows heavy or a task spans sessions, the next session starts
  from `PROGRESS.md` instead of replaying history.
- Plans go in a file (`PLAN.md` / `docs/`), not in the chat transcript.

## Response discipline

- Answer, then stop. No restating the question, no summarizing the obvious,
  no listing everything you did unless asked.
- Do not re-read the task instructions back to the user.
- Keep completion reports to the evidence format (see
  `verification-before-completion`) — evidence, caveats, done.
- Prefer one table over ten paragraphs.

## Session hygiene

- Split long tasks into milestones with a `PROGRESS.md` checkpoint between
  each, so a dead session restarts cheaply.
- Batch related shell commands into one call instead of five.
- Do not plan tasks you will not execute in this session — unused plans are
  pure token cost.