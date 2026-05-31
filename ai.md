# UntisPlus - AI Context & Guidelines

Welcome! If you are an AI assistant helping to build or modify UntisPlus, this document is your primary source of truth for the project's architecture, state management, and critical rules.

## 1. Golden Rules
1. **Always keep the `README.md` updated!** Whenever you make architectural changes, add new features, or modify setup instructions, you MUST update the `README.md` to reflect these changes.
2. **"Idiotensicher" (Idiot-proof) UX:** Every UI element, setting, and menu should be highly intuitive. Always add subtitles to list tiles, tooltips to icon buttons, and maintain accessibility (Semantics).
3. **Beautiful UI:** Use glassmorphism (`_glassContainer`, blur effects), dynamic background animations, and modern typography (`GoogleFonts.outfit`). Never use plain or boring colors.

## 2. Architecture & State Management
- **State Management:** The app relies on `ValueNotifier` for global state management (e.g., `appLocaleNotifier`, `themeModeNotifier`, `homeworksNotifier`). These are defined globally in `lib/main.dart` or related service files.
- **Main File (`lib/main.dart`):** This is a large file containing the core initialization, the main `WeeklyTimetablePage`, and many global variables. When modifying the timetable, look for `_WeeklyTimetablePageState` and `_buildGridView`.
- **Navigation:** The main navigation is handled in `lib/screens/main_navigation_screen.dart`. It uses an `IndexedStack` and a custom floating `_buildFloatingNavBar`. 

## 3. Key Services
- **WebUntis API:** `lib/services/webuntis_homework_api.dart` handles fetching homework.
- **AI Chat:** The AI chat is built into the app and spans fullscreen when selected (`_selectedIndex == 6`). It uses the `aiProvider`, `aiModel`, and API keys stored in `SharedPreferences`.

## 4. Building & CI/CD
- The project uses GitHub Actions for CI/CD.
- Releases are automatically signed using a base64-encoded keystore stored in GitHub Secrets (`ANDROID_KEYSTORE_BASE64`).
- When bumping versions, update `pubspec.yaml` and create a matching git tag (e.g., `v5.2.1`).
