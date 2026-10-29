# agy-skills

Bộ skill cho **Google Antigravity** (IDE + CLI) — chữa các "bệnh" đã được ghi
nhận rộng rãi của Gemini agent: **giả vẽ công việc** (simulated work), tự
certify kết quả, hallucinate completion summary, tốn token, chết vì hết
context, và hỏi yes/no liên tục.

Bộ skill dựa trên pattern từ các repo nhiều sao nhất trong cộng đồng agent
skills (xem [Nguồn tham khảo](#nguồn-tham-khảo)) và bộ skill builtin +
settings thật đang chạy trên máy (`~/.gemini/antigravity-cli/`).

## Map: bệnh → thuốc

| Bệnh của Antigravity | Thuốc |
|---|---|
| Giả vẽ: hardcode data, mock JSON, sleep loop rồi báo "done" | `skills/anti-fake-work` |
| Tự certify / hallucinate completion summary | `skills/verification-before-completion` |
| Báo "fixed" mà không chạy lại repro | `skills/test-driven-development` (chu kỳ RED-GREEN có verify) |
| "Prompt is too long" — agent chết vì không có compaction; tốn ~30% token hơn | `skills/token-frugality` (+ `PROGRESS.md` checkpoint) |
| Hỏi yes/no mọi lệnh | `skills/auto-pass` + `config/settings.example.json` |
| Auto-pass mà sợ agent phá máy | `config/hooks/` — safety-gate denylist + iron-law reminder |
| Không tuân kế hoạch, làm trộn task | `rules/anti-fake-work.md` (rule always_on) |

## Cài đặt nhanh (Khuyên dùng)

### Cách 1: Script tự động 1-click (Tự nhận diện môi trường & Auto-Pass)

Script sẽ tự động copy toàn bộ `skills/`, thêm rule vào `GEMINI.md`, và **tự động cấu hình `settings.json`** nhận diện đúng thư mục Home của máy hiện tại vào `trustedWorkspaces` kèm bật Auto-pass:

- **Windows (PowerShell):**
  ```powershell
  git clone https://github.com/yuHz23/agy-skills.git $HOME\Downloads\agy-skills
  & "$HOME\Downloads\agy-skills\install.ps1"
  ```
- **Linux / macOS / WSL (Bash):**
  ```bash
  git clone https://github.com/yuHz23/agy-skills.git ~/Downloads/agy-skills
  bash ~/Downloads/agy-skills/install.sh
  ```

### Cách 2: Cài đặt tự động qua Antigravity Agent
Mở Antigravity trên máy cần cài, copy toàn bộ nội dung trong [install-prompt.md](install-prompt.md) rồi dán vào khung chat và nhấn Enter. Agent sẽ tự chạy các bước và báo cáo bằng bằng chứng thực tế.

---

## Cài đặt thủ công (Từng bước)

### 1. Skills (chọn 1 trong 2 scope)

- **Toàn máy**: copy `skills/*` vào `~/.gemini/config/skills/`
  ```powershell
  Copy-Item -Recurse .\skills\* $HOME\.gemini\config\skills\
  ```
- **Theo project (commit vào repo để cả team dùng)**: copy vào `<repo>/.agents/skills/`

Skill dùng progressive disclosure — chỉ frontmatter (~100 token) được nạp
vào context; body chỉ load khi trigger. Skill tự thành slash command:
`/anti-fake-work`, `/verification-before-completion`, ...

### 2. Rule always_on

Thêm nội dung `rules/anti-fake-work.md` vào `~/.gemini/config/GEMINI.md`
(global) hoặc `AGENTS.md` / `.agents/rules/` (project). Rule luôn nằm trong
context nên phải ngắn — file đã viết gọn để dán thẳng.

### 3. Auto-pass (settings)

Copy các key từ `config/settings.example.json` vào
`~/.gemini/antigravity-cli/settings.json`:

```json
{
  "agentMode": "accept-edits",
  "artifactReviewPolicy": "always-proceed",
  "toolPermission": "always-proceed",
  "trustedWorkspaces": ["C:\\Users\\<thay_bằng_username_thật_của_máy>"]
}
```

> [!IMPORTANT]
> `trustedWorkspaces` bắt buộc phải là đường dẫn thật của máy bạn (ví dụ `C:\Users\Admin`). Nếu để sai, Auto-pass sẽ không có hiệu lực và CLI sẽ vẫn hỏi Yes/No. Thêm `"command(regex:.*)"` vào `permissions.allow` để cho phép mọi lệnh chạy tự động.

### 4. Hooks (auto-pass có guardrail)

Copy `config/hooks/hooks.json` + `config/hooks/scripts/` vào `.agents/` của
workspace (hooks chạy với thư mục chứa `hooks.json` làm working dir, qua
`cmd /c` trên Windows; file dùng sẵn `py` launcher — trên Unix đổi `py`
thành `python3`):

- **safety-gate** (`PreToolUse`): tự cho phép MỌI lệnh trừ denylist phá hoại
  (mkfs, `dd of=/dev/...`, `rm -rf /`, shutdown, `curl | sh`, fork bomb,
  force-push main...). Lệnh bị chặn trả về kèm reason, không hỏi yes/no.
- **iron-law-reminder** (`PreInvocation`): chèn 1 dòng nhắc "không được báo
  done khi chưa có evidence" trước mỗi lần gọi model — bù cho việc Antigravity
  không có compaction, rule không bị trôi trong session dài.

## Cấu trúc repo

```
agy-skills/
├── README.md
├── rules/
│   └── anti-fake-work.md          # rule always_on, dán vào GEMINI.md/AGENTS.md
├── skills/
│   ├── anti-fake-work/SKILL.md            # cấm giả vẽ: hardcode, mock, self-certify
│   ├── verification-before-completion/SKILL.md  # cổng evidence trước khi claim "done"
│   ├── test-driven-development/SKILL.md    # RED-GREEN-REFACTOR, test phải fail trước
│   ├── token-frugality/SKILL.md            # đọc file chọn lọc, PROGRESS.md, trả lời gọn
│   └── auto-pass/SKILL.md                  # dừng hỏi yes/no: settings + grants + hooks
└── config/
    ├── settings.example.json       # file settings auto-pass known-good
    └── hooks/
        ├── hooks.json              # safety-gate + iron-law-reminder
        └── scripts/
            ├── pretooluse_guard.py  # allow mọi thứ trừ denylist phá hoại
            └── preinv_reminder.py   # nhắc Iron Law mỗi invocation
```

## Nguồn tham khảo

Pattern (không copy nguyên văn — viết lại cho Antigravity/Gemini):

- **[obra/superpowers](https://github.com/obra/superpowers/)** — skill
  `verification-before-completion` ("no completion claims without fresh
  verification evidence") và `test-driven-development` (RED-GREEN với bảng
  anti-rationalization). Repo skill framework cho agent được nhiều sao nhất.
- **[anthropics/skills](https://github.com/anthropics/skills/)** — official
  repo định nghĩa format Agent Skills (SKILL.md + progressive disclosure),
  sau này thành open standard (agentskills.io) mà Antigravity dùng.
- **[ComposioHQ/awesome-claude-skills](https://github.com/composiohq/awesome-claude-skills)**
  — curated list 1000+ skills chạy trên Claude Code, Cursor, Codex, Gemini
  CLI, Antigravity.
- **[VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-claude-skills/)**
  — 1000+ skills của các team thật (Google, Stripe, Cloudflare, Sentry...),
  kèm quality standard cho SKILL.md.
- **[sickn33/agentic-awesome-skills](https://github.com/sickn33/agentic-awesome-skills)**
  — 2690+ playbook cài được qua CLI.
- **[travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills/)**
  — list skills chính thức + cộng đồng, security best practices.
- **Builtin Antigravity** trên máy này (`~/.gemini/antigravity-cli/builtin/skills/`):
  `agy-customizations` (cấu trúc customization, hooks, plugins),
  `permissioned-github` (format grant `gh.*`/`git.*`), `automation`
  (sidecar + access_grants), `run-workflow`, `plugin` — các skill đó của
  Google, không copy vào repo này, chỉ tham khảo format.

## Ghi chú

- Workflow cũ (`.agents/workflows/*.md`) bị Antigravity bỏ hỗ trợ từ
  19/10/2026 — dùng skills (thư mục) thay thế, có lệnh `/migrate-workflows`
  builtin để chuyển.
- Auto-pass không thay được verification: cho agent chạy tự do MÀ KHÔNG hỏi
  thì bắt buộc phải cài `anti-fake-work` + `verification-before-completion`
  cùng lúc — chúng là compensating control của nhau.
- Skill format tương thích chéo với Claude Code (`.claude/skills/`) vì cùng
  open standard — có thể dùng lại 2 chiều.