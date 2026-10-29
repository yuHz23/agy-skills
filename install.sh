#!/usr/bin/env bash
# ==============================================================================
#  AGY-SKILLS AUTO INSTALLER & AUTO-PASS (Linux / macOS / WSL)
# ==============================================================================

set -e

echo "=========================================="
echo "   AGY-SKILLS AUTO INSTALLER & AUTO-PASS  "
echo "=========================================="

HOME_DIR="$HOME"
echo "[+] Môi trường Home hiện tại: $HOME_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Cài đặt Skills
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DEST="$HOME_DIR/.gemini/config/skills"
if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DEST"
    cp -rf "$SKILLS_SRC/"* "$SKILLS_DEST/"
    echo "[+] Đã copy toàn bộ skills vào: $SKILLS_DEST"
else
    echo "[!] Không tìm thấy thư mục skills trong $SKILLS_SRC"
fi

# 2. Cài đặt Rule Anti-fake-work vào GEMINI.md
RULES_SRC="$SCRIPT_DIR/rules/anti-fake-work.md"
CONFIG_DIR="$HOME_DIR/.gemini/config"
GEMINI_MD="$CONFIG_DIR/GEMINI.md"

if [ -f "$RULES_SRC" ]; then
    mkdir -p "$CONFIG_DIR"
    if [ -f "$GEMINI_MD" ]; then
        if ! grep -q "Anti-fake-work" "$GEMINI_MD"; then
            echo -e "\n\n# Anti-fake-work (luật luôn bật — từ bộ skill agy-skills)\n" >> "$GEMINI_MD"
            cat "$RULES_SRC" >> "$GEMINI_MD"
            echo "[+] Đã thêm Anti-fake-work rule vào: $GEMINI_MD"
        else
            echo "[*] Rule Anti-fake-work đã có trong $GEMINI_MD (bỏ qua)"
        fi
    else
        echo -e "# Anti-fake-work (luật luôn bật — từ bộ skill agy-skills)\n" > "$GEMINI_MD"
        cat "$RULES_SRC" >> "$GEMINI_MD"
        echo "[+] Đã tạo GEMINI.md với rule Anti-fake-work: $GEMINI_MD"
    fi
fi

# 3. Cấu hình tự động settings.json (Auto-Pass)
AGY_CLI_DIR="$HOME_DIR/.gemini/antigravity-cli"
SETTINGS_PATH="$AGY_CLI_DIR/settings.json"
mkdir -p "$AGY_CLI_DIR"

# Chạy script Python (hoặc Python3) để merge JSON chuẩn xác
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
fi

if [ -n "$PYTHON_CMD" ]; then
    $PYTHON_CMD - <<EOF
import json, os

home_dir = os.path.expanduser("~")
settings_path = os.path.join(home_dir, ".gemini", "antigravity-cli", "settings.json")

default_allows = [
    "command(git)", "command(python)", "command(npm)", "command(npx)", "command(node)",
    "command(dotnet)", "command(cargo)", "command(make)", "command(cmake)", "command(docker)",
    "command(podman)", "command(ls)", "command(cat)", "command(grep)", "command(find)",
    "command(curl)", "command(wget)", "command(pip)", "command(pipx)", "command(go)",
    "command(rustc)", "command(flutter)", "command(dart)", "command(adb)", "command(ffmpeg)",
    "command(7z)", "command(tar)", "command(mkdir)", "command(cp)", "command(mv)",
    "command(chmod)", "command(echo)", "command(pwd)", "command(which)", "command(env)",
    "command(whoami)", "command(date)", "command(cd)", "command(tmux)", "command(ssh)",
    "command(scp)", "command(rsync)", "command(ping)", "command(netstat)", "command(ss)",
    "command(jq)", "command(yq)", "command(regex:.*)"
]

data = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        with open(settings_path + '.bak', 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        print("[*] Đã backup settings cũ sang: " + settings_path + ".bak")
    except Exception:
        data = {}

data["agentMode"] = "accept-edits"
data["artifactReviewPolicy"] = "always-proceed"
data["toolPermission"] = "always-proceed"

trusted = data.get("trustedWorkspaces", [])
if not isinstance(trusted, list):
    trusted = []
if home_dir not in trusted:
    trusted.append(home_dir)
data["trustedWorkspaces"] = trusted

if "permissions" not in data or not isinstance(data["permissions"], dict):
    data["permissions"] = {}

allows = data["permissions"].get("allow", [])
if not isinstance(allows, list):
    allows = []
for cmd in default_allows:
    if cmd not in allows:
        allows.append(cmd)
data["permissions"]["allow"] = allows

with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)

print("[+] Cấu hình settings.json Auto-pass thành công tại: " + settings_path)
EOF
else
    echo "[!] Không tìm thấy Python để merge JSON, vui lòng kiểm tra thủ công $SETTINGS_PATH"
fi

echo ""
echo "===> HOÀN TẤT CÀI ĐẶT! Khởi động lại Antigravity CLI để áp dụng."
