# Flatpak Packaging

This directory contains Flathub-oriented packaging for Aetherfin.

## Build The Flutter Bundle

Build the Linux release bundle on your machine first:

```bash
flutter build linux --release
```

The Flatpak manifest copies `build/linux/x64/release/bundle` into `/app/aetherfin`.

## Build And Install

```bash
flatpak-builder --force-clean --sandbox --user --install --install-deps-from=flathub build-dir com.vedastacklabs.aetherfin.yml
flatpak run com.vedastacklabs.aetherfin
```

## Lint

```bash
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest com.vedastacklabs.aetherfin.yml
flatpak run --command=flatpak-builder-lint org.flatpak.Builder appstream flatpak/com.vedastacklabs.aetherfin.metainfo.xml
```

## Notes

- The tray icon and desktop icons are derived from `assets/ic_launcher.png`.
- `shared-modules/libappindicator` is required because the locally built `tray_manager` plugin links to `libappindicator3.so.1`.
- Read-only dconf access is granted so Yaru can resolve GNOME's `accent-color` setting instead of falling back to Ubuntu orange.
- This local packaging flow wraps the prebuilt Flutter bundle. It is convenient for your machine, but Flathub generally expects source builds inside `flatpak-builder`.
- `fvp` bundles MDK native binaries. That is preserved to keep the current player backend.
- `flathub.json` currently restricts builds to `x86_64` because the bundled MDK Linux archive used by `fvp` is x86_64.
- Replace screenshot placeholder URLs in `com.vedastacklabs.aetherfin.metainfo.xml` with direct tag or commit-pinned HTTPS URLs before submitting to Flathub.
