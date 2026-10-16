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
   `toolPermission`, `permissions.allow` (giữ lại các allow cũ, chỉ thêm phần
   thiếu), và `trustedWorkspaces` = đúng thư mục home của máy này. Giữ nguyên
   mọi key khác. KHÔNG thêm `command(regex:.*)` nếu tôi không yêu cầu.
   Nếu file settings.json chưa tồn tại thì tạo mới từ file example.
6. KHÔNG cài hooks và KHÔNG chỉnh gì khác ngoài các bước trên.
7. Báo cáo cuối: liệt kê từng bước + lệnh + exit code, kèm output thật của
   lệnh liệt kê `~/.gemini/config/skills/` (Windows:
   `dir "$HOME\.gemini\config\skills"`, Unix: `ls -la ~/.gemini/config/skills`).
   Nếu bước nào fail, báo lỗi nguyên văn thay vì bỏ qua.

---

## Cài không qua agent (chạy tay)

```powershell
git clone https://github.com/yuHz23/agy-skills.git $HOME\Downloads\agy-skills
Copy-Item -Recurse -Force $HOME\Downloads\agy-skills\skills\* $HOME\.gemini\config\skills\
# rồi tự dán rule từ rules/anti-fake-work.md vào ~/.gemini/config/GEMINI.md
```

Lưu ý: hooks guardrail (`config/hooks/`) không tự cài — chỉ copy vào `.agents/`
của workspace nào muốn có safety-gate. Windows dùng `py` launcher; Unix đổi
`py` thành `python3` trong `hooks.json`.