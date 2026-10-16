---
name: auto-pass
description: Setup guide for eliminating yes/no permission prompts in Antigravity (CLI and IDE) — auto-approve commands, edits, and artifacts safely. Use when the user wants to stop permission prompts, asks about agentMode/trustedWorkspaces/permissions.allow, or wants to configure auto-run/yolo mode. Pairs auto-pass with a dangerous-command guard hook.
---

# Auto-Pass (no more yes/no prompts)

Antigravity asks for confirmation on every command. This skill sets up
auto-approval so the agent runs unattended, while keeping a guardrail against
destructive commands.

## 1. `settings.json` — the main switches

Location: `~/.gemini/antigravity-cli/settings.json` (CLI). The keys that kill
the prompts:

```json
{
  "agentMode": "accept-edits",
  "artifactReviewPolicy": "always-proceed",
  "toolPermission": "always-proceed",
  "trustedWorkspaces": ["C:\\Users\\YourName"],
  "permissions": {
    "allow": [
      "command(git)", "command(python)", "command(npm)", "command(node)",
      "command(docker)", "command(podman)", "command(ssh)", "command(tmux)",
      "command(curl)", "command(jq)", "command(adb)", "command(ffmpeg)"
    ]
  }
}
```

- `toolPermission: "always-proceed"` — tool calls no longer prompt.
- `agentMode: "accept-edits"` — file edits auto-accept.
- `artifactReviewPolicy: "always-proceed"` — artifact review auto-accepts.
- `trustedWorkspaces` — paths where the above apply; only trust directories
  you actually work in.
- `permissions.allow` — per-binary grants. `"command(regex:.*)"` allows
  everything (true yolo) — convenient but pair it with the guard hook below.

See `config/settings.example.json` in this repo for the full known-good file.

## 2. Permission grant formats (scoped, for sidecars/subagents)

For scheduled automations and sidecars (`sidecar.json` →
`agent_permissions.access_grants`), keep grants narrow — never wildcards:

- `command(<binary and subcommand>)` → `command(gh pr list)` (never `command(*)`)
- `read_file(<absolute path>)`, `write_file(<absolute path>)` (never `read_file(*)`)
- `mcp(<server>/<tool>)` — only for servers present in the environment
- `read_url(<domain>)`, `execute_url(<domain>)`

Never invent grants for tools that were not verified to exist — a sidecar
running unattended with a hallucinated grant just fails silently.

## 3. Hooks — auto-pass with a guardrail (recommended)

`hooks.json` lets a `PreToolUse` hook decide `allow` / `deny` / `ask` for
every tool call programmatically. The shipped config in `config/hooks/` of this
repo:

- **safety-gate** (`PreToolUse` on `run_command`): auto-allows everything
  EXCEPT a denylist of destructive patterns (disk/format device commands,
  recursive deletes on root/home, shutdown, `curl … | sh` pipe-to-shell,
  fork bombs). Denied commands come back with a reason instead of prompting.
- **iron-law-reminder** (`PreInvocation`): injects a one-line ephemeral
  reminder — no completion claims without fresh evidence — before each model
  call, so the anti-fake rules survive long sessions.

Install: copy `config/hooks/hooks.json` + `scripts/` into your workspace
`.agents/` directory (hooks run with that folder as working directory, via
`cmd /c` on Windows). The shipped hooks.json uses the Windows `py` launcher;
on Unix replace `py` with `python3`.

## 4. What auto-pass does NOT cover

- Network-facing GitHub actions (`gh`/`git` push/PR operations) use the
  separate `gh.*`/`git.*` permission format — see the built-in
  `permissioned-github` skill; ask only after a command actually fails.
- Auto-pass means the agent's mistakes happen unattended. The
  `anti-fake-work` and `verification-before-completion` skills are the
  compensating control — install them together with this one.