# agy-skills

Bộ cài một lần cho Antigravity CLI, App và IDE. Gói gồm 5 skill riêng của repo, 24 skill dùng chung từ [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), rule chống báo hoàn thành giả, hook guardrail và cấu hình auto-pass.

## Cài cho người không rành kỹ thuật

### Windows

1. Tải [ZIP mới nhất](https://github.com/yuHz23/agy-skills/archive/refs/heads/main.zip) và giải nén.
2. Mở thư mục vừa giải nén, nhấp đúp `install.bat`.
3. Chờ thông báo hoàn tất, sau đó khởi động lại Antigravity CLI.

Không cần quyền Administrator. Bộ cài chỉ ghi vào hồ sơ user hiện tại.

Nếu đã cài Git, có thể tải và chạy bằng PowerShell:

```powershell
git clone https://github.com/yuHz23/agy-skills.git "$HOME\\Downloads\\agy-skills"
& "$HOME\\Downloads\\agy-skills\\install.ps1"
```

### Linux, macOS hoặc WSL

```bash
git clone https://github.com/yuHz23/agy-skills.git ~/Downloads/agy-skills
bash ~/Downloads/agy-skills/install.sh
```

Lệnh cài đặt cần Python 3 để gộp JSON. Nếu thiếu Python 3, installer dừng trước khi ghi file và chỉ rõ điều kiện cần cài.

## Bộ cài cập nhật những gì

| Thành phần | Đường dẫn toàn cục |
|---|---|
| Skills cho Antigravity CLI | `~/.gemini/antigravity-cli/skills/` |
| Skills cho Antigravity App và IDE | `~/.gemini/config/skills/` |
| Rule chung | `~/.gemini/GEMINI.md` hoặc file global hiện có trong `~/.gemini/config/GEMINI.md` |
| Hooks dùng chung | `~/.gemini/config/hooks.json` |
| Script của hooks | `~/.gemini/config/agy-skills/hooks/scripts/` |
| Settings auto-pass của CLI | `~/.gemini/antigravity-cli/settings.json` |

Installer cài 29 skill, gộp settings mà vẫn giữ các key khác, và tạo bản sao lưu có dấu thời gian trước khi sửa JSON hoặc thêm rule. Nếu settings/hooks JSON hiện có bị lỗi cú pháp, installer dừng và giữ nguyên file đó.

### Cấu hình auto-pass

Installer đặt:

- `agentMode: accept-edits` để tự chấp nhận sửa file trong workspace.
- `toolPermission: always-proceed` và `artifactReviewPolicy: always-proceed` để bỏ prompt mặc định.
- `permissions.ask: []` để xóa các luật hỏi xác nhận toàn cục; giữ nguyên luật `allow` và `deny` đã có.
- `enableTerminalSandbox: true` và `allowNonWorkspaceAccess: false`.
- Thêm thư mục home hiện tại vào `trustedWorkspaces`.

Luật `deny` vẫn chặn thao tác đã bị cấm. Ask/Deny đặt ở cấp project hoặc shared vẫn có thể yêu cầu xác nhận. Hook safety-gate chặn một số lệnh phá hoại phổ biến; danh sách này không bao phủ mọi lệnh nguy hiểm.

> **Lưu ý:** `always-proceed` cho phép CLI tự chạy lệnh, web và MCP mà không hỏi. Sandbox cần được AGY hỗ trợ trên máy; nếu sandbox không khả dụng, cấu hình này vẫn bỏ xác nhận nhưng không tạo được vùng cô lập cho lệnh terminal. Chỉ cài trên máy và workspace mà người dùng tin cậy.

### Kiểm tra sau khi cài

- Khởi động lại `agy`; nhập `/skills` để xem skills đã nạp.
- Nhập `/hooks` để xem hai hook `agy-skills-safety-gate` và `agy-skills-iron-law-reminder`.
- Nếu một skill vừa được cài chưa hiện, chạy `/skills reload`.

## Skills riêng của repo

| Skill | Dùng khi |
|---|---|
| `anti-fake-work` | Ngăn dữ liệu giả và báo hoàn thành khi chưa có bằng chứng. |
| `auto-pass` | Cài đặt auto-approve và hiểu phạm vi quyền của nó. |
| `test-driven-development` | Viết thay đổi theo chu kỳ RED-GREEN-REFACTOR. |
| `token-frugality` | Giữ context gọn, lưu checkpoint cho task dài. |
| `verification-before-completion` | Đòi bằng chứng mới trước khi báo hoàn tất. |

## Skills dùng chung

24 skill được đóng gói từ addyosmani/agent-skills v0.6.13:

`api-and-interface-design`, `browser-testing-with-devtools`, `ci-cd-and-automation`, `code-review-and-quality`, `code-simplification`, `constraint-driven-development`, `context-engineering`, `debugging-and-error-recovery`, `deprecation-and-migration`, `documentation-and-adrs`, `doubt-driven-development`, `frontend-ui-engineering`, `git-workflow-and-versioning`, `idea-refine`, `incremental-implementation`, `interview-me`, `observability-and-instrumentation`, `performance-optimization`, `planning-and-task-breakdown`, `security-and-hardening`, `shipping-and-launch`, `source-driven-development`, `spec-driven-development`, `using-agent-skills`.

Skill `test-driven-development` từ upstream được bỏ qua vì repo đã có bản riêng. Giấy phép và ghi nhận nguồn nằm trong [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Cài bằng prompt

Nếu Antigravity đã chạy và có quyền chạy terminal, mở [install-prompt.md](install-prompt.md), gửi prompt cho agent và để agent chạy installer trong repo đã tải xuống.
