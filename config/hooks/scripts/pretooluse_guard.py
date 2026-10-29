#!/usr/bin/env python3
"""PreToolUse safety gate for Antigravity (agy-skills).

Reads the PreToolUse hook payload on stdin, auto-approves run_command calls
except for a denylist of destructive patterns, and prints the decision JSON
on stdout. Denylisted commands are hard-blocked with a reason.

Payload (stdin):
    {"toolCall": {"name": "run_command", "args": {"CommandLine": "..."}},
     "stepIdx": 19, "conversationId": "...", ...}

Output (stdout):
    {"decision": "auto_approve"} | {"decision": "deny", "reason": "..."}
"""
import json
import re
import sys

# (pattern, reason) — matched case-insensitively against the command line.
DENYLIST = [
    (r"\bmkfs(\.\w+)?\b", "filesystem formatting"),
    (r"\bdd\b[^|]*\bof=/dev/(sd|nvme|vd|disk)", "raw write to a disk device"),
    (r"format\s+[a-zA-Z]:", "drive format"),
    (r"\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s+(/|~|\$HOME|/home|/etc|/usr|/var|\*)", "recursive delete of a system/home root"),
    (r"Remove-Item\s+.*-Recurse\s+-Force\s+['\"]?C:\\?['\"]?\s*$", "recursive force delete of C:\\ root"),
    (r"\b(shutdown|reboot|halt|poweroff)\b", "system shutdown/reboot"),
    (r"curl[^|;]*\|\s*(ba)?sh(\s|$)", "piping curl straight into a shell"),
    (r"wget[^|;]*\|\s*(ba)?sh(\s|$)", "piping wget straight into a shell"),
    (r"iex\s*\(\s*(New-Object\s+System\.Net\.WebClient|Invoke-WebRequest)", "PowerShell download-and-execute"),
    (r":\(\)\s*\{\s*:\|:&\s*\}\s*;:", "fork bomb"),
    (r"git\s+push\s+.*--force\s+.*\b(main|master)\b", "force-push to main/master"),
    (r">\s*/dev/sd[a-z]", "redirecting output to a raw disk device"),
]


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # Malformed input: do not silently allow, but do not crash either.
        print(json.dumps({"decision": "ask", "reason": "guard could not parse payload"}))
        return

    tool = (payload.get("toolCall") or {}).get("name") or ""
    args = (payload.get("toolCall") or {}).get("args") or {}
    cmd = str(args.get("CommandLine") or args.get("command") or "")

    if tool != "run_command" or not cmd:
        # Other tools are governed by settings.json permissions.
        print(json.dumps({"decision": "auto_approve"}))
        return

    for pattern, reason in DENYLIST:
        if re.search(pattern, cmd, re.IGNORECASE):
            print(json.dumps({
                "decision": "deny",
                "reason": f"safety-gate: blocked {reason!r}. Ask the user explicitly if this is truly intended.",
            }))
            return

    print(json.dumps({"decision": "auto_approve"}))


if __name__ == "__main__":
    main()
