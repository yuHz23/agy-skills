---
name: auto-pass
description: Explains and configures global Antigravity CLI auto-approval. Use when the user wants fewer permission prompts, asks about agentMode, toolPermission, permissions.ask, trustedWorkspaces, or global hooks.
---

# Antigravity Auto-Pass

The installer in this repository configures Antigravity CLI auto-approval for
the current user. It also installs skills for the CLI, App, and IDE.

## CLI settings

The CLI settings file is ~/.gemini/antigravity-cli/settings.json:

~~~json
{
  "$schema": "https://antigravity.google/schemas/v1/settings.json",
  "agentMode": "accept-edits",
  "artifactReviewPolicy": "always-proceed",
  "toolPermission": "always-proceed",
  "enableTerminalSandbox": true,
  "allowNonWorkspaceAccess": false
}
~~~

- agentMode: accept-edits accepts workspace file edits automatically.
- toolPermission: always-proceed runs tools without a prompt unless an
  explicit Ask or Deny rule matches.
- artifactReviewPolicy: always-proceed skips artifact review pauses.
- enableTerminalSandbox: true enables the terminal sandbox when supported.
- allowNonWorkspaceAccess: false keeps file access inside the active
  workspace.

Permission rules have precedence Deny > Ask > Allow. The installer clears the
global permissions.ask list so old Ask rules do not defeat auto-pass; it
preserves existing global Allow and Deny lists. Project or shared Ask/Deny
rules can still apply.

Do not add command(regex:.*) to permissions.allow: it grants broad command
access, and it cannot override an Ask or Deny rule.

## Global skills and hooks

Antigravity CLI loads global skills from
~/.gemini/antigravity-cli/skills/. Antigravity App and IDE load them from
~/.gemini/config/skills/.

Global CLI, App, and IDE hooks live in ~/.gemini/config/hooks.json. The
installer places their scripts in
~/.gemini/config/agy-skills/hooks/scripts/ and writes absolute commands, so
they do not depend on the current workspace.

The safety-gate hook auto-approves ordinary run_command calls and blocks a
short list of common destructive patterns. It is not a complete sandbox or a
comprehensive command security filter. Explicit permission rules still apply.

## Install and refresh

1. Download or clone this repo.
2. On Windows, double-click install.bat; on Linux/macOS, run bash install.sh.
3. Restart Antigravity CLI. Use /skills and /hooks to inspect the installed
   customizations. Use /skills reload if a skill is missing.

The installer backs up edited JSON and rule files with a timestamp. If an
existing JSON file is malformed, it stops without replacing it.

## Permission and sandbox limits

always-proceed is the highest-risk setting: commands, web actions, and MCP
tools can run without confirmation. The terminal sandbox only contains shell
commands on supported AGY versions and hosts. If the sandbox is unavailable,
auto-approval remains enabled without that containment. Use this configuration
only on a machine and workspace the user trusts.
