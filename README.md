# MACROS 0.4 — Flutter prototype

MACROS is a prototype for unified music search, playlist transfer UX, discovery and music recognition.

## Current status — read this first

This repository contains a **working UI prototype**, not four completed provider integrations.

Implemented in this starter:
- dark mobile UI with theme accent customization;
- service tiles for Spotify, VK Music, Yandex Music and SoundCloud;
- unified search handoff (opens provider search pages);
- playlist URL input and local saved-link persistence;
- demo track selection screen for the playlist-transfer flow;
- discovery prompt UI;
- Shazam-like feature entry point and recognition-module placeholder;
- settings/sync placeholder;
- GitHub Actions workflow that builds an Android release APK.

Not yet implemented:
- provider OAuth login and API tokens;
- fetching real playlist tracks from provider links;
- matching tracks across provider catalogs;
- creating playlists / adding tracks to Likes in destination accounts;
- actual personalized recommendation engine;
- microphone capture and audio fingerprint recognition;
- background audio engine and lock-screen controls;
- cloud account and cross-device sync.

The transfer screen currently uses **demo tracks** after a URL is pasted. It does not pretend that it has parsed the real playlist. Provider APIs, scopes, review/approval and terms must be checked individually. Never commit API secrets or user tokens to GitHub.

## Build APK using GitHub Actions

1. Create a GitHub account if needed.
2. Create a new repository named `macros`.
3. Upload the contents of this folder to the repository (the `.github` folder must be included).
4. Commit to the `main` branch.
5. Open the repository's **Actions** tab.
6. Choose **Build MACROS APK** and click **Run workflow** (or wait for the push-triggered build).
7. When the run finishes with a green check, open the run and find **Artifacts**.
8. Download `macros-android-apk`, unzip it, and install `app-release.apk` on your Android phone. Android may ask you to allow installation from that source.

If Actions fails, open the failed job and copy the error log. The project may need Android Gradle configuration adjustments as Flutter versions change.

## Local build (optional)

Install Flutter stable and Android Studio / Android SDK, then from this folder:

```bash
flutter create . --platforms=android
flutter pub get
flutter analyze
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## Integration roadmap

Suggested order:
1. Spotify OAuth + playlist read/write scopes.
2. VK authorization + permitted audio/catalog access; verify availability of required endpoints and permissions.
3. Yandex Music integration based on currently permitted developer capabilities.
4. SoundCloud OAuth + playlist/catalog access.
5. Normalize metadata (`title`, `artist`, `album`, duration, ISRC where available).
6. Match tracks with confidence scores and let users review ambiguous matches.
7. Create destination playlist or add to Likes only after user confirmation.
8. Add audio recognition provider + microphone permission.
9. Add background playback only for content MACROS is authorized to play; third-party apps may need to handle their own playback.
10. Add backend sync and secure token storage.

## Product principle

MACROS can help users move playlist metadata and find authorized equivalents. It must not bypass subscription controls, DRM, or provider restrictions, or download protected streams without permission.


## MACROS 0.5 — experimental clips module

Added:
- A dedicated **Клипы** tab.
- Search for music videos by track/artist through YouTube's public search page.
- Opening HTTPS links from `youtube.com`, `m.youtube.com`, and `youtu.be` in the official app/browser.
- A short list of recently opened video links, stored locally.

Important limitations:
- This is an external-player handoff, not an embedded in-app video player.
- It does not download, cache, extract, or redistribute videos.
- Search results and playback are provided by YouTube; availability and playback rules are controlled by that service.
- No automatic matching of a track to an official music video is implemented yet.
- The existing playlist import screen remains a demo; it does not read real VK playlists.

To build: push the updated project to GitHub and run the existing **Build MACROS Android APK** workflow.
