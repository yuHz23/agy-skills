# Prompt tự cài agy-skills (paste vào agent trên máy mới)

Copy toàn bộ khối dưới đây, paste vào Antigravity (CLI/IDE) hoặc Claude Code
trên máy cần cài rồi Enter:

---

Cài bộ skill **agy-skills** cho Antigravity trên máy này. Làm đúng từng bước,
báo cáo bằng EVIDENCE (lệnh đã chạy + exit code + trích output thật), tuyệt
đối không báo "done" khi chưa chạy thật — đây chính là rule mà bộ skill này
cài vào:

1. Xác định OS và thư mục home thật của máy (Windows / Linux / macOS).
2. Clone `https://github.com/yuHz23/agy-skills.git` vào `~/Downloads/agy-skills`.
   Nếu thư mục đã tồn tại thì vào đó `git pull` để lấy bản mới.
3. Skills: tạo `~/.gemini/config/skills/` nếu chưa có, copy đè toàn bộ
   `skills/*` của repo vào đó.
4. Rule: đọc `~/.gemini/config/GEMINI.md`. Nếu CHƯA có dòng `Anti-fake-work`
   thì append phần rule (từ dòng `- Never claim a task is done...` trở xuống)
   của `rules/anti-fake-work.md` vào cuối file. Nếu đã có thì bỏ qua bước này.
5. Settings auto-pass: đọc `~/.gemini/antigravity-cli/settings.json` nếu tồn
   tại. SAU KHI backup thành `settings.json.bak`, merge các key sau từ
   `config/settings.example.json`: `agentMode`, `artifactReviewPolicy`,
   `toolPermission`, `permissions.allow` (giữ lại các allow cũ, thêm phần thiếu
   và thêm `"command(regex:.*)"` để auto-pass mọi lệnh không bị dừng hỏi Yes/No),
   và `trustedWorkspaces` = mảng chứa đúng thư mục home thật của máy này (ví dụ
   `C:\Users\<username>` trên Windows hoặc `/home/<username>` trên Unix).
   Giữ nguyên mọi key khác. Nếu file settings.json chưa tồn tại thì tạo mới.
6. KHÔNG cài hooks và KHÔNG chỉnh gì khác ngoài các bước trên.
7. Báo cáo cuối: liệt kê từng bước + lệnh + exit code, kèm output thật của
   lệnh liệt kê `~/.gemini/config/skills/` (Windows:
   `dir "$HOME\.gemini\config\skills"`, Unix: `ls -la ~/.gemini/config/skills`).
   Nếu bước nào fail, báo lỗi nguyên văn thay vì bỏ qua.

---

## Cài không qua agent (chạy script tự động 1-click)

**Trên Windows (PowerShell):**
```powershell
git clone https://github.com/yuHz23/agy-skills.git $HOME\Downloads\agy-skills
& "$HOME\Downloads\agy-skills\install.ps1"
```

**Trên Linux / macOS / WSL (Bash):**
```bash
git clone https://github.com/yuHz23/agy-skills.git ~/Downloads/agy-skills
bash ~/Downloads/agy-skills/install.sh
```

*Script sẽ tự động copy skills, add rule vào GEMINI.md, và tự lấy biến môi trường `$HOME` để cập nhật `settings.json` Auto-pass chuẩn 100% cho máy đó.*

Lưu ý: hooks guardrail (`config/hooks/`) không tự cài — chỉ copy vào `.agents/`
của workspace nào muốn có safety-gate. Windows dùng `py` launcher; Unix đổi
`py` thành `python3` trong `hooks.json`.