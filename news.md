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
