# Todo Demo (Flutter)

A responsive Todo application showcasing tasks management, dashboard charts, authentication, theming (light/dark), local persistence, and a modern UI. Targets Web, iOS, Android, macOS, Windows, and Linux.


### Production Live URL: https://flutter-task-dev-crm.netlify.app/


## Prerequisites

- Flutter 3.22+ installed and on PATH
- Dart SDK bundled with Flutter
- Xcode (iOS/macOS), Android Studio + SDKs (Android), or Chrome (Web)

Verify:

```bash
flutter --version
flutter doctor -v
```

## Quick Start

```bash
# 1) Get dependencies
flutter pub get

# 2) Run on web (Chrome)
flutter run -d chrome

# Or run on a device/emulator
flutter devices
flutter run -d <device_id>

# 3) Build production web
flutter build web --release
```

If you hit caching issues on web:

```bash
flutter clean && flutter pub get
flutter run -d chrome
```

## Project Structure (key files)

```
lib/
  main.dart                   # Entry, routes, themes, auth guard
  models/
    todo.dart                 # Todo + SubTask models
  screens/
    landing_screen.dart       # Public landing page
    sign_in_screen.dart       # Login
    sign_up_screen.dart       # Registration
    home_screen.dart          # Tasks list (sort/filter/paginate)
    dashboard_screen.dart     # Stats, line & bar charts, recent tasks
    task_detail_screen.dart   # Inline edit, subtasks
  services/
    api_service.dart          # Mock API (optional helpers)
    kv_store.dart             # Platform-agnostic KV abstraction
    kv_store_web.dart         # Web localStorage + cookie fallback
    kv_store_io.dart          # IO shared_preferences
    kv_store_stub.dart        # In-memory
    local_storage_service.dart# Persists tasks
    task_store.dart           # ValueNotifier for tasks
    theme_service.dart        # Theme persistence
  widgets/
    app_shell.dart            # Sidebar, header, routing frame
    add_task_modal.dart       # Create/Edit task modal
    confirm_dialog.dart       # Delete confirm dialog
    task_card.dart            # Task UI primitives
    toast.dart                # Toaster + ToastService
assets/
  icons/task.svg              # App icon (ensure registered in pubspec)
  shots/                      # Landing page screenshots
```

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.9
  fl_chart: ^0.68.0
  intl: ^0.19.0
  shared_preferences: ^2.2.2

flutter:
  uses-material-design: true
  assets:
    - assets/icons/task.svg
    - assets/shots/
```

Install/update packages:

```bash
flutter pub get
```

## Common Commands

```bash
# Format
flutter format .

# Analyze (lints)
flutter analyze

# Run tests
flutter test

# Build (Web/Android/iOS examples)
flutter build web --release
flutter build apk --release
flutter build ios --release
```

## App Workflow Overview

- Authentication: Sign In/Up with in-memory users, persisted via `KVStore` (web: localStorage/cookies; IO: shared_preferences). Default demo: `admin@demo.com` / `admin123`.
- Routing: Unauthenticated users see `LandingScreen`. Protected routes redirect to sign-in.
- Tasks: Created via `AddTaskModal` (title, description, start/due dates, priority, tags, subtasks). Stored in `LocalStorageService` and reflected in `HomeScreen` and `Dashboard`.
- Dashboard: Line and bar charts via `fl_chart`; counts for total/pending/completed; recent tasks table with actions.
- UI: Responsive layout via `AppShell` (collapsible sidebar, header, profile menu), dark/light theme via `ThemeService`.
- Toaster: Global `ToastService` for success/error/info notifications.

## Sample Snippets

Minimal app entry (from `lib/main.dart`):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await ThemeService.init();
  runApp(const MyApp());
}
```

Showing a toast anywhere:

```dart
ToastService.success('Task created successfully');
```

Open Add Task modal:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => AddTaskModal(
    onTaskAdded: (todo) async {
      final all = await LocalStorageService.loadAllTasks();
      all.insert(0, todo);
      await LocalStorageService.saveAllTasks(all);
    },
  ),
);
```

Line & Bar charts (using `fl_chart` in `dashboard_screen.dart`) are already wired to local tasks.

## Troubleshooting

- Asset not found (e.g., `assets/icons/task.svg`): ensure path registered in `pubspec.yaml`, run `flutter clean && flutter pub get`, then rebuild.
- Web reload loses data: ensure `KVStore` web implementation is used; avoid Incognito which disables persistent storage.
- `MissingPluginException(shared_preferences)` on web: this project uses `KVStore` abstraction; ensure `kv_store_web.dart` is present and imported via `kv_store.dart` conditional imports.

## License

MIT (for demo purposes).
