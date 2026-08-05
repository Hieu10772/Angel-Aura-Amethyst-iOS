# AngelAuraAmethyst iOS — 1.1.3-beta.6

## 🇬🇧 English
- Fixed "Insufficient contiguous virtual memory space" and early app kills on non-jailbroken devices — the launcher now reads the real remaining memory allowance via `os_proc_available_memory()`, caps auto RAM at 60% of the remaining allowance (minimum 384 MB) and the memory probe no longer blocks launching.
- Virtual mouse pointer customization — pick from built-in styles (Arrow, Crosshair, Circle, Dot, Beam) or use your own cursor files: Windows `.cur` / `.ani` and common image formats (png, jpg, gif, bmp, tiff, webp…).
- Cursor hotspot from `.cur`/`.ani` files is honored, so the tap point lands exactly on the arrow tip (or the center of centered shapes).
- Custom pointer file is stored in the app's Documents folder; resetting or removing the file falls back to the default pointer.

## 🇻🇳 Tiếng Việt
- Sửa lỗi "Insufficient contiguous virtual memory space" và bị kill sớm trên máy không jailbreak — launcher giờ đọc đúng dung lượng bộ nhớ còn lại qua `os_proc_available_memory()`, giới hạn auto RAM ở 60% phần còn lại (tối thiểu 384 MB) và bước kiểm tra bộ nhớ không còn chặn khởi động.
- Cá nhân hóa con trỏ chuột ảo — chọn kiểu có sẵn (Arrow, Crosshair, Circle, Dot, Beam) hoặc dùng file con trỏ của bạn: `.cur` / `.ani` của Windows và các định dạng ảnh phổ biến (png, jpg, gif, bmp, tiff, webp…).
- Tôn trọng hotspot trong file `.cur`/`.ani` — điểm chạm trỏ đúng mũi tên (hoặc tâm với hình tròn).
- File con trỏ tùy chỉnh lưu trong thư mục Documents của app; xóa/mất file sẽ tự quay về con trỏ mặc định.

---

# AngelAuraAmethyst iOS — 1.1.3-beta.5

## 🇬🇧 English
- Forge 26.x (e.g. Forge for Minecraft 1.21.2) now actually launches — the missing `forge-*-universal.jar` is added to the game classpath so the "forge" system mod is detected and the game no longer crashes with "Failed to find system mod: forge".
- News panel now shows only the changelog of the version you are running (filtered from news.md).
- Improved markdown rendering — headings, bold/italic, lists, code, links and tables are now rendered correctly.

## 🇻🇳 Tiếng Việt
- Forge 26.x (vd. Forge cho Minecraft 1.21.2) giờ chạy được thật sự — bổ sung `forge-*-universal.jar` vào classpath game để nhận diện system mod "forge", không còn crash lỗi "Failed to find system mod: forge".
- Bảng tin chỉ hiển thị changelog đúng phiên bản launcher bạn đang chạy (lọc từ news.md).
- Cải thiện render markdown — tiêu đề, in đậm/nghiêng, danh sách, code, link và bảng hiển thị đúng.

---

# AngelAuraAmethyst iOS — 1.1.3-beta.4

## 🇬🇧 English
- Forge & NeoForge now install correctly — the official installer jar is downloaded and run through the built-in "Execute .jar" environment.
- Import local `.mrpack` modpacks — the launcher downloads everything inside and sets up the loader automatically.
- Fixed Forge installer downloads (moved to the official MinecraftForge Maven repository).
- Modpacks needing Forge/NeoForge now auto-install the loader.
- "Execute .jar" gained an "Install (headless)" option for installer jars.
- Version list refreshes automatically after installing.

Thanks to everyone who tested this build!

## 🇻🇳 Tiếng Việt
- Forge & NeoForge cài đúng cách — tải installer jar chính thức và chạy qua môi trường "Execute .jar" có sẵn.
- Nhập modpack `.mrpack` cục bộ — launcher tự tải toàn bộ nội dung và tự cài loader.
- Sửa lỗi tải installer Forge (dùng kho Maven chính thức của MinecraftForge).
- Modpack cần Forge/NeoForge tự động cài loader.
- "Execute .jar" thêm nút "Install (headless)" cho file installer.
- Danh sách version tự làm mới sau khi cài.

Cảm ơn mọi người đã test bản này!
