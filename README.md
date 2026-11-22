# MACROS 0.4 — GitHub APK starter

MACROS is a cross-platform music discovery and playlist-transfer app concept.

## Included in this starter
- Flutter app shell with dark theme and accent color choices.
- Service search handoff for Spotify, VK Music, Yandex Music and SoundCloud.
- Demo playlist transfer screen with selectable sample tracks.
- Discovery prompt screen.
- Recognition button placeholder.
- GitHub Actions workflow to build an Android release APK.

## Important: current limitations
This is an **UI starter**, not a fully integrated music-transfer app.
- Service account OAuth is not implemented.
- Playlist URL parsing, track matching, playlist creation and Likes writing are not implemented.
- Recommendations, microphone-based song recognition, background playback and cloud sync are not implemented.
- Service API access and permissions must be reviewed and implemented separately. Do not put API secrets in the Flutter app or public repository.
- The app does not download protected audio or bypass provider restrictions.

## Build APK on GitHub
1. Create a GitHub repository.
2. Upload the **contents** of this folder, including the hidden `.github` folder.
3. Open the repository's **Actions** tab.
4. Choose **Build MACROS Android APK**.
5. Press **Run workflow** (or push to `main`).
6. When the run finishes, open it and download the `macros-android-apk` artifact.
7. Unzip the artifact to get `app-release.apk`.

## Build locally
Install Flutter and Android SDK, then run:

```bash
flutter create . --platforms=android
flutter pub get
flutter analyze
flutter build apk --release
```

The APK has not been prebuilt or device-tested as part of this starter archive.
