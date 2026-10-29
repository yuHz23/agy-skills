# Prompt cài agy-skills trên máy mới

Gửi khối sau cho Antigravity agent trên máy cần cài:

---

Cài bộ agy-skills toàn cục cho user hiện tại:

1. Xác định hệ điều hành và thư mục home hiện tại.
2. Tải repo https://github.com/yuHz23/agy-skills vào thư mục Downloads/agy-skills. Nếu thư mục đã có, kiểm tra git status trước; không ghi đè thay đổi local.
3. Chạy installer đi kèm repo: Windows dùng install.bat hoặc install.ps1; Linux/macOS dùng bash install.sh. Không chạy với quyền Administrator/sudo.
4. Để installer gộp settings.json, cài skills, rule và global hooks. Không tự chỉnh các file này bằng tay.
5. Nếu installer báo JSON lỗi, dừng và báo nguyên văn lỗi; không tạo file thay thế.
6. Sau khi chạy, báo lệnh đã chạy, exit code và trích output thật. Nêu các đường dẫn đã cài và hướng dẫn khởi động lại Antigravity CLI.

---

Người dùng có thể tải ZIP, giải nén rồi nhấp đúp install.bat trên Windows mà không cần dùng prompt này.
