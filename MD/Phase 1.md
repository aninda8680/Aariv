Phase 1 Build Spec — Neo-Brutalist Productivity App
(Todo + Study Timer + Expense Tracker + Profile/Settings — Flutter, fully local, no login)
1. Vision
A single, tightly-connected productivity app for students/freelancers that combines task management, focused work sessions, and spend tracking — with an honest, raw, high-contrast neo-brutalist visual identity that still feels usable, not chaotic. No accounts, no cloud, no login — everything lives on-device, fast and private.
Design north star: bold, structural, confident — like a well-designed zine or Swiss poster, not a "trendy Dribbble shot with broken UX." If a design choice hurts usability, drop it.
2. Design System
Neo-brutalism rules:

Borders: 2–3px solid near-black (#1A1A1A) on all interactive containers — cards, buttons, inputs, dialogs
Shadows: hard offset shadows, no blur (e.g. 4px 4px 0px #1A1A1A); shadow shrinks on tap for a "pressed into place" feel
Corners: mostly sharp (0–4px); slightly rounded (8px) only on primary CTAs and bottom nav, so the UI doesn't feel visually aggressive everywhere
Flat, saturated color blocks — no gradients, no glassmorphism
Bold headers, but body text stays fully legible (never sacrifice readability for style)

Palette (adjust to taste, keep the discipline):

Background: off-white #FAF9F6
Ink/borders: #1A1A1A
Todo accent: electric yellow #FFD93D
Timer accent: coral #FF6B4A
Expense accent: mint #3DDC97
Error: #FF3B3B
Each core screen gets one dominant accent as its identity anchor — quiet wayfinding so users always know which section they're in

Type scale: Display titles 28–32px bold/extrabold; section headers 18–20px bold; body 15–16px (never below 14px); captions 12–13px medium weight (avoid thin weights — they fight the aesthetic and hurt readability). Generous line-height (1.4–1.5x).
Motion: fast directional slides (200–250ms), no fades/bounce. Button press = shadow-collapse, not opacity fade. Task complete = strike-through + color flash, then sort to bottom (don't fade content away — feels glitchy).
3. Navigation
Bottom nav, 4 tabs, always visible: Todo (default) / Timer / Expense / Profile. Active tab = solid color-block behind icon, not just icon color change — needs to read at a glance.
4. Screens
Todo: top bar with date + completion counter ("3/7 done today"). Filter chips: All/Today/Upcoming/Completed. Task cards show checkbox, title, due date, priority tag, category tag. Add-task bottom sheet: title, notes, due date/time, priority, category, optional "link to timer session" toggle. Full detail page per task (not just dialog), shows linked focus time if attached. Proper empty state, not a blank screen.
Timer: Mode toggle — Pomodoro / Stopwatch / Countdown. Pomodoro: bold ring/bar progress, customizable 25/5 default. Stopwatch: big digital display, large bordered controls. Optional task-linking dropdown. Secondary stats tab: daily/weekly bar chart of focus time, session history with linked tasks. Must keep running accurately in background (foreground service/notification on Android).
Expense: Top summary card (balance, income vs. expense, color-coded). Add-transaction bottom sheet: amount, type toggle, category (preset icons + custom), date, note. List grouped by date. Secondary insights tab: category breakdown chart, monthly comparison — keep factual, no AI needed yet. Default currency ₹, configurable in settings.
Profile/Settings: Editable local display name + emoji/icon avatar (no photo upload needed yet, no account). Grouped settings cards: Appearance (light/dark, both properly tuned for the brutalist palette — don't just invert colors), Timer defaults, Currency/expense defaults, Data management (local export as JSON/CSV, clear-all with strong confirmation), About (version, credit, short blurb). No dead "Sign In" button — omit login UI entirely.
5. Technical Architecture

Framework: Flutter/Dart
State management: Riverpod, feature-modularized (todo, timer, expense, settings)
Pattern: MVVM — View → ViewModel (Notifier) → Repository → local data source
Storage: Drift (SQLite) for tasks/sessions/transactions as proper relational tables (enables cross-feature queries like "focus time per task"); shared_preferences only for lightweight flags (theme, currency, Pomodoro defaults)
Core tables: tasks (id, title, notes, due_date, priority, category, is_completed, created_at), focus_sessions (id, task_id nullable FK, duration_seconds, mode, started_at, completed_at), transactions (id, type, amount, category, note, date), settings (key-value)
Security note: no accounts means "secured" = no unnecessary permissions, no analytics/tracking SDKs, data never leaves device
Responsiveness: use LayoutBuilder/MediaQuery breakpoints, no hardcoded pixel widths; test at ~360dp, ~412dp, ~600dp+ before calling a screen done

6. Explicit Phase 1 boundaries (don't build yet)
❌ Password manager (flagged earlier as a security/architecture mismatch) ❌ Cloud sync/login ❌ AI features ❌ Collaboration/sharing ❌ Notifications beyond local timer reminders
Phase 1's only job: nail a smooth, good-looking, fully offline daily utility. Phase 2 layers in smarter stuff once this is solid.