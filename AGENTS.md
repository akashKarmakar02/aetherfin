# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

Aetherfin is a Flutter Jellyfin client with:

- platform-adaptive app shells
- a stateless Jellyfin API layer under `lib/api`
- routed auth, home, player, and series features
- Ubuntu/Yaru-style Linux desktop integration

Primary entrypoint:

- `lib/main.dart`
- bootstrap in `lib/app/app_bootstrap.dart`

## Architecture

### App structure

- `lib/app/`
  - bootstrap, platform detection, router, session state, shell widgets
- `lib/api/`
  - stateless transport, DTOs, and service classes
- `lib/features/`
  - feature-specific screens, loaders, models, widgets
- `lib/shared/`
  - reusable shared widgets
- `lib/theme/`
  - platform theme definitions

Keep business logic out of screen widgets when possible.

### Routing

- Use `go_router`
- Keep route names and paths in `lib/app/router/app_routes.dart`
- New full-screen experiences should be routed features, not inline overlays

### Session state

- App session state lives in `lib/app/session/`
- Use the existing `AppSessionController` and `AppSessionScope`
- Do not add persistence or account logic inside `lib/api`

## Platform Rules

### Linux

- Use Yaru/libadwaita-style presentation
- Keep Linux app chrome in `LinuxWindowShell`
- Use `YaruWindowTitleBar` for normal app screens
- Do not add custom flat/material-looking cards that fight the native Linux look
- Avoid decorative gradients for Linux page backgrounds unless explicitly requested
- Rounded decoration comes from the native runner/window stack, not fake in-app borders

### Android / iOS / macOS

- Use the Cupertino shell and theme direction already established in the app
- Mobile layouts should feel intentional and media-forward, not desktop layouts squeezed down

### Windows

- Use Material styling

## API Layer Rules

- `lib/api` must stay stateless
- Callers provide base URL, access token, and client metadata explicitly
- Prefer typed service methods and DTOs over ad hoc JSON use in feature code
- Keep Jellyfin-specific request logic in service classes, not in widgets

## Player Rules

- The active player backend is `fvp` + `video_player`
- Do not reintroduce `media_kit` / `media_kit_video`
- Register `fvp` in `lib/app/app_bootstrap.dart`
- Keep Jellyfin playback flow unchanged:
  - resolve item through Jellyfin
  - resolve resume position
  - fetch playback info
  - build stream URL
  - report started / progress / stopped
- Audio/subtitle switching is Jellyfin-driven by regenerating the stream URL with stream indices
- Keep player UI custom; do not use backend-provided controls
- Player runtime abstraction lives under `lib/features/player/playback/`

## UI / UX Preferences

- Keep theme definitions separate from screens
- Keep each screen in its own file
- Reuse existing feature folders instead of growing `main.dart`
- Preserve the current Apple TV-inspired media layout direction where already established
- On Linux, prefer Yaru/libadwaita visual patterns over generic Material cards
- When changing player or titlebar behavior, verify both:
  - player route has no normal app titlebar
  - titlebar returns immediately after exiting player

## Coding Conventions

- Prefer small focused files and feature-local helpers
- Follow the existing naming style and folder organization
- Default to ASCII unless a file already needs Unicode
- Add comments only when code is non-obvious
- Reuse existing abstractions before adding new ones
- Avoid broad refactors unless required by the task

## Verification

Run the smallest relevant checks first, then broader checks if the change is cross-cutting.

Common commands:

```bash
flutter analyze
flutter test
flutter test test/features/player test/app/router
flutter build linux
```

## Linux Build Note

`fvp` may fail to fetch its Linux SDK from SourceForge in some environments. If that happens, use:

```bash
FVP_DEPS_URL=https://github.com/wang-bin/mdk-sdk/releases/latest/download flutter build linux
```

## Current High-Value Files

- `lib/app/app.dart`
- `lib/app/app_bootstrap.dart`
- `lib/app/router/app_router.dart`
- `lib/app/shell/platform_shell.dart`
- `lib/features/player/player_controller.dart`
- `lib/features/player/screens/player_screen.dart`
- `lib/features/series/screens/series_details_screen.dart`
- `lib/features/home/screens/home_screen.dart`

