# Fix AI Timetable, Navbar Clutter & App Logo

## 1. Fix AI Chat Timetable Recognition
- The AI chat currently loads its context (_weekData) in initState synchronously alongside MainNavigationScreen. Since pp_state globals (schoolUrl, personId) are populated asynchronously, the AI receives empty variables and thus fails to load the cached timetable.
- I will modify _AiAssistantPageState._send() to wait _loadContext(); right before calling _resolvedSystemPrompt() to ensure the latest globals and cached timetable are injected into the prompt.

## 2. Redesign App Logo
- The current AI-generated logo is too detailed. The user wants a clean, simple, SVG-like orange 'U' with a 'Neo' badge centered at the bottom.
- I will write a PowerShell script using System.Drawing to programmatically draw a high-quality (1024x1024) PNG logo matching these exact specifications.
- I will then distribute this new PNG to ssets/icon.png and all Android es/mipmap-* and es/drawable-* folders.

## 3. Fix Bottom Navigation Bar Clutter
- The bottom floating nav bar contains 6 buttons in a Row, plus the timetable FAB. On smaller screens, this squishes everything and causes tap targets to overlap or become unclickable.
- I will wrap the Row inside the navigation pill with a SingleChildScrollView(scrollDirection: Axis.horizontal) so users can easily scroll through the options without squishing the icons or blocking the Timetable button.
