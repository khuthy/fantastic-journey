# CLAUDE.md

This file provides guidance to AI assistants (Claude and others) working in this repository.

---

## Repository Overview

- **Repository**: khuthy/fantastic-journey
- **Remote**: https://github.com/khuthy/fantastic-journey
- **Primary branch**: `main`
- **Purpose**: Boom gate access management app for Protea Glen Estate, South Africa

### Tech Stack
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.19+ / Dart 3.3+ |
| State management | Riverpod 2 (StateNotifierProvider, FutureProvider) |
| Navigation | GoRouter 13 (ShellRoute for per-role navigation) |
| Database | Neon (Postgres) — accessed via a serverless REST API, **never directly** |
| File storage | Cloudflare R2 (S3-compatible) — presigned URL pattern via API |
| UI | Material 3, Google Fonts (Inter), custom AppTheme |
| Build | flutter pub / flutter build |

### Target Platforms
- **Android** (API 21+)
- **iOS** (iOS 13+)
- **Windows** (Win10+, for security guard desktop console)
- **Linux** (desktop — future)

---

## Project Architecture

### Role-based system (single app)

There are **three roles** and each gets its own navigation shell:

| Role | Shell | Home route |
|------|-------|------------|
| `resident` | `ResidentShell` | `/resident/dashboard` |
| `security` | `SecurityShell` | `/security/dashboard` |
| `admin` | `AdminShell` | `/admin/dashboard` |

The router reads the authenticated user's role and redirects to the correct home.

### Directory layout

```
lib/
├── main.dart                   # Entry point — ProviderScope + app setup
├── app.dart                    # MaterialApp.router + theme + text scale guard
├── core/
│   ├── constants/
│   │   ├── app_colors.dart     # All colour constants + gradients
│   │   └── app_dimensions.dart # Spacing, radii, breakpoints
│   ├── theme/
│   │   └── app_theme.dart      # Light & dark ThemeData + AppThemeExtension
│   ├── router/
│   │   └── app_router.dart     # GoRouter definition + AppRoutes constants
│   └── utils/
│       ├── helpers.dart        # OTP generation, date formatting, initials, etc.
│       └── validators.dart     # Form field validators
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   ├── user_model.dart         # UserModel + UserRole enum
│   │   │   └── visitor_pass_model.dart # VisitorPassModel + PassType/PassStatus
│   │   ├── repositories/auth_repository.dart
│   │   ├── providers/auth_provider.dart  # AuthNotifier (StateNotifier)
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       ├── login_screen.dart        # Responsive: mobile + 2-col desktop
│   │       └── register_screen.dart
│   ├── resident/
│   │   ├── providers/resident_provider.dart
│   │   └── screens/
│   │       ├── resident_shell.dart       # AdaptiveScaffold wrapper
│   │       ├── resident_dashboard_screen.dart
│   │       ├── create_pass_screen.dart   # QR / OTP pass generator
│   │       ├── my_passes_screen.dart
│   │       ├── pass_display_screen.dart  # Shows QrImageView or OTP digits
│   │       └── resident_profile_screen.dart
│   ├── security/
│   │   ├── providers/security_provider.dart
│   │   └── screens/
│   │       ├── security_shell.dart
│   │       ├── security_dashboard_screen.dart
│   │       ├── scan_pass_screen.dart    # MobileScanner + OTP entry, custom overlay
│   │       └── entry_log_screen.dart
│   ├── admin/
│   │   ├── providers/admin_provider.dart
│   │   └── screens/
│   │       ├── admin_shell.dart
│   │       ├── admin_dashboard_screen.dart
│   │       ├── manage_residents_screen.dart
│   │       ├── manage_announcements_screen.dart
│   │       └── manage_cameras_screen.dart
│   ├── cameras/
│   │   ├── models/camera_model.dart    # CameraModel + FootageRecord
│   │   ├── providers/camera_provider.dart
│   │   └── screens/
│   │       ├── camera_list_screen.dart  # Responsive grid
│   │       └── camera_viewer_screen.dart # Chewie player + R2 footage list
│   └── announcements/
│       ├── models/announcement_model.dart
│       ├── providers/announcements_provider.dart
│       └── screens/announcements_screen.dart
└── shared/
    ├── services/
    │   ├── neon_db_service.dart   # REST client (Dio) + token management
    │   └── r2_storage_service.dart # Cloudflare R2 presigned URL client
    └── widgets/
        ├── app_button.dart        # AppButton (5 variants) + AppIconButton
        ├── app_card.dart          # AppCard + StatCard
        ├── app_text_field.dart    # Labelled text form field
        └── responsive_layout.dart # ResponsiveLayout + AdaptiveScaffold
```

---

## Development Branch

All AI-assisted changes must be developed on feature branches:

```
claude/<short-description>-<random-suffix>
```

**Never push directly to `main`.**

---

## Git Workflow

### Branching

```bash
git checkout -b claude/<feature>-<suffix>
git push -u origin <branch-name>
```

### Commits

Imperative mood, subject ≤ 72 chars:

```
Add OTP resend countdown to pass display screen
Fix camera status badge colour for maintenance state
```

### Pull Requests

- Open a PR before merging to `main`
- Include a short summary and test plan

---

## Environment & Configuration

All secrets live server-side. The Flutter app only needs the API base URL.

```bash
# Set the API URL when building
flutter build apk --dart-define=NEON_API_URL=https://api.proteaglen.com
```

See `.env.example` for all variables. **Never commit `.env`.**

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run on Windows desktop
flutter run -d windows

# Build release APK
flutter build apk --release --dart-define=NEON_API_URL=https://api.proteaglen.com

# Build iOS
flutter build ipa --dart-define=NEON_API_URL=https://api.proteaglen.com
```

---

## Key Design Patterns

### Data flow
1. **UI** dispatches action via provider notifier or calls `ref.read(serviceProvider)`
2. **Repository** (or service) calls the Neon API via Dio
3. **Notifier** updates state → UI rebuilds

### Visitor pass flow
1. Resident opens *Create Pass*, fills in visitor details + duration
2. App calls `POST /passes` → server generates token (random UUID or 6-digit OTP)
3. `PassDisplayScreen` renders a `QrImageView` (QR mode) or large text (OTP mode)
4. Resident shares pass (clipboard copy with share sheet)
5. Security guard scans QR with `MobileScanner` or enters OTP manually
6. App calls `POST /passes/validate` → server checks validity + increments `use_count`
7. Guard sees green "Access Granted" or red "Access Denied" screen

### Cloudflare R2 footage pattern
- Client **never** holds R2 credentials
- All upload/download goes through presigned URLs fetched from the API
- `R2StorageService.getFootageUrl(key)` → returns a 2h presigned URL → fed to `VideoPlayerController`

### Responsive layout
- `AdaptiveScaffold` renders a persistent sidebar (≥900 px) or bottom nav bar (<900 px)
- `ResponsiveLayout` chooses mobile / tablet / desktop widgets via `LayoutBuilder`
- All screens respect the `maxWidth` constraint (`ConstrainedBox(constraints: BoxConstraints(maxWidth: 560))`)

---

## Coding Conventions

- **Dart style**: follow `analysis_options.yaml` — no linter suppressions without a comment explaining why
- **Immutability**: prefer `@immutable` classes and `const` constructors
- **No direct DB access from Flutter**: all mutations go through `NeonDbService` → your API
- **Providers**: use `FutureProvider` for reads, `StateNotifierProvider` for mutable state
- **No secrets in code**: API keys, passwords, R2 credentials must never appear in Dart files
- **Error handling**: surface human-readable messages via `AppHelpers.showSnackBar` — never swallow exceptions silently

---

## Testing

*(To be documented when test suite is added)*

Planned:
- `flutter_test` for widget tests
- `mocktail` for mocking services
- At minimum: auth flow, QR generation, pass validation logic

Run (once configured):

```bash
flutter test
```

---

## Linting

```bash
flutter analyze
dart fix --apply
```

All PRs must pass `flutter analyze` with zero errors.

---

## CI/CD

*(To be configured — GitHub Actions recommended)*

Planned pipeline:
- `flutter analyze` on every PR
- `flutter test` on every PR
- Release build + signing on merge to `main`

---

## AI Assistant Guidelines

1. **Read before editing**: always read a file with the Read tool before modifying it
2. **Minimal changes**: only touch what the task requires
3. **No speculative features**: don't add code that wasn't asked for
4. **Branch discipline**: develop on `claude/<description>-<suffix>`, never on `main`
5. **Secrets**: never hard-code API keys, passwords, or credentials
6. **Responsive UI**: test that UI works at ≥600 px (tablet/desktop) as well as <600 px
7. **Providers**: add new FutureProviders for new API calls; don't add business logic to widgets
8. **Keep this file current**: update CLAUDE.md when conventions change

---

## Updating This File

Update CLAUDE.md when:
- New screens or features are added
- The API contract changes
- CI/CD is configured
- Test framework is added
- A new platform is targeted (Linux, macOS, web)
