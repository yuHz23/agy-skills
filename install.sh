#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export AGY_SKILLS_SOURCE="$SCRIPT_DIR"
export HOME_DIR="${HOME:?Could not determine your home directory}"

PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
else
    echo "[!] Python 3 is required to merge the Antigravity settings safely."
    echo "    Install Python 3, then run this installer again. No files were changed."
    exit 1
fi
export PYTHON_CMD

"$PYTHON_CMD" - <<'PY'
import json
import os
import shlex
import shutil
import tempfile
from datetime import datetime
from pathlib import Path

source = Path(os.environ["AGY_SKILLS_SOURCE"])
home = Path(os.environ["HOME_DIR"]).expanduser().resolve()
gemini = home / ".gemini"
config = gemini / "config"
settings_path = gemini / "antigravity-cli" / "settings.json"
hooks_path = config / "hooks.json"
rule_path = gemini / "GEMINI.md"
legacy_rule_path = config / "GEMINI.md"
legacy_rule_text = legacy_rule_path.read_text(encoding="utf-8") if legacy_rule_path.exists() else ""
if "# Anti-fake-work" in legacy_rule_text or (not rule_path.exists() and legacy_rule_path.exists()):
    rule_path = legacy_rule_path
template_path = source / "config" / "hooks" / "hooks.json"
rule_source = source / "rules" / "anti-fake-work.md"
skills_source = source / "skills"
scripts_source = source / "config" / "hooks" / "scripts"
stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")

def read_object(path):
    if not path.exists():
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise SystemExit(f"Invalid JSON at '{path}'. The original file was left unchanged: {exc}")
    if not isinstance(value, dict):
        raise SystemExit(f"Expected a JSON object at '{path}'. The original file was left unchanged.")
    return value

def backup(path):
    if path.exists():
        backup_path = Path(f"{path}.bak.{stamp}")
        shutil.copy2(path, backup_path)
        print(f"[*] Backup: {backup_path}")

def save_object(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    backup(path)
    temp_name = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", newline="\n", dir=path.parent,
            prefix=f".{path.name}.", suffix=".tmp", delete=False
        ) as temp:
            temp_name = temp.name
            json.dump(value, temp, ensure_ascii=False, indent=2)
            temp.write("\n")
            temp.flush()
            os.fsync(temp.fileno())
        os.replace(temp_name, path)
    finally:
        if temp_name and os.path.exists(temp_name):
            os.unlink(temp_name)

settings = read_object(settings_path)
installed_hooks = read_object(hooks_path)
hook_template = read_object(template_path)
if not skills_source.is_dir() or not any(p.is_dir() for p in skills_source.iterdir()):
    raise SystemExit(f"No skill folders found at '{skills_source}'. No files were changed.")
if not rule_source.is_file() or not scripts_source.is_dir():
    raise SystemExit("The repository is missing its rule or hook scripts. No files were changed.")
permissions = settings.get("permissions", {})
if not isinstance(permissions, dict):
    raise SystemExit(f"Expected 'permissions' to be an object in '{settings_path}'. No files were changed.")

settings["$schema"] = settings.get("$schema", "https://antigravity.google/schemas/v1/settings.json")
settings["agentMode"] = "accept-edits"
settings["artifactReviewPolicy"] = "always-proceed"
settings["toolPermission"] = "always-proceed"
settings["enableTerminalSandbox"] = True
settings["allowNonWorkspaceAccess"] = False
trusted = settings.get("trustedWorkspaces", [])
if not isinstance(trusted, list):
    raise SystemExit(f"Expected 'trustedWorkspaces' to be an array in '{settings_path}'. No files were changed.")
if not any(str(item).rstrip("/\\").casefold() == str(home).rstrip("/\\").casefold() for item in trusted):
    trusted.append(str(home))
settings["trustedWorkspaces"] = trusted
permissions["ask"] = []
settings["permissions"] = permissions

global_hook_scripts = config / "agy-skills" / "hooks" / "scripts"
safety_script = global_hook_scripts / "pretooluse_guard.py"
reminder_script = global_hook_scripts / "preinv_reminder.py"
tool_hook = hook_template["agy-skills-safety-gate"]
reminder_hook = hook_template["agy-skills-iron-law-reminder"]
python_executable = shlex.quote(os.path.realpath(os.environ["PYTHON_CMD"]))
tool_hook["PreToolUse"][0]["hooks"][0]["command"] = f"{python_executable} {shlex.quote(str(safety_script))}"
reminder_hook["PreInvocation"][0]["command"] = f"{python_executable} {shlex.quote(str(reminder_script))}"
installed_hooks["agy-skills-safety-gate"] = tool_hook
installed_hooks["agy-skills-iron-law-reminder"] = reminder_hook

skills = [p for p in skills_source.iterdir() if p.is_dir()]
for destination in (gemini / "antigravity-cli" / "skills", config / "skills"):
    destination.mkdir(parents=True, exist_ok=True)
    for skill in skills:
        shutil.copytree(skill, destination / skill.name, dirs_exist_ok=True)
print(f"[+] Installed {len(skills)} skills for Antigravity CLI and IDE.")

global_hook_scripts.mkdir(parents=True, exist_ok=True)
for script in scripts_source.iterdir():
    if script.is_file():
        shutil.copy2(script, global_hook_scripts / script.name)
save_object(hooks_path, installed_hooks)
print(f"[+] Installed global hooks: {hooks_path}")

rule_lines = rule_source.read_text(encoding="utf-8").splitlines()
start = next((i for i, line in enumerate(rule_lines) if line.startswith("- Never claim")), None)
if start is None:
    raise SystemExit(f"Could not find the rule body in '{rule_source}'.")
rule_body = "\n".join(rule_lines[start:])
existing_rule = rule_path.read_text(encoding="utf-8") if rule_path.exists() else ""
if "# Anti-fake-work" not in existing_rule:
    backup(rule_path)
    separator = "\n\n" if existing_rule.strip() else ""
    rule_path.parent.mkdir(parents=True, exist_ok=True)
    rule_path.write_text(
        existing_rule + separator + "# Anti-fake-work (agy-skills)\n\n" + rule_body + "\n",
        encoding="utf-8",
    )
    print(f"[+] Added the global Anti-fake-work rule: {rule_path}")
else:
    print("[*] Global Anti-fake-work rule already exists.")

save_object(settings_path, settings)
print(f"[+] Auto-pass settings saved: {settings_path}")
print("    agentMode=accept-edits; toolPermission=always-proceed")
print("    terminal sandbox enabled; non-workspace file access disabled")
print("    explicit Ask rules cleared; existing Allow and Deny rules retained")
print("\nRestart Antigravity CLI to load the global settings, skills, and hooks.")
PY
