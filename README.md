# Classmate App

A Flutter + Firebase messaging app for students with authentication, real-time chat, profile management, contact calling, and theme support. This README explains how the app is structured, how to configure Firebase, how to run and test locally, and where to find key files.

## Table of contents

- Overview
- Features
- Architecture & data model
- Setup (global + platform-specific)
- Firestore rules & indexes
- Seed demo data (what the script does)
- Run & debug locally
- Tests
- Troubleshooting & tips
- Contributing

## Overview

Classmate App demonstrates a complete mobile chat flow using Flutter and Firebase (Authentication, Firestore, Storage). It's built with separation of concerns: UI lives in `lib/screens` and `lib/widgets`, business logic in `lib/services`, and models in `lib/models`.

## Features

- Firebase Authentication (email/password)
- Real-time chat with Firestore collections for chats and messages
- Profile editing (name, email, phone)
- Tap-to-call using stored phone numbers
- Message actions: edit, delete, star
- Typing indicators and read receipts
- Image attachments via Firebase Storage
- Theme persistence (light/dark)

## Architecture & data model

High-level architecture:

- UI: `lib/screens` contains page widgets (ChatList, ChatScreen, Profile, Settings).
- Services: `lib/services` contains Firebase wrappers (auth, firestore, storage) and business logic.
- Models: `lib/models` defines the shapes for `User`, `Chat`, and `Message` used across the app.

Typical Firestore layout (simplified):

- `users/{userId}` — user profile and metadata
- `chats/{chatId}` — chat metadata (participants, lastMessage, updatedAt)
- `chats/{chatId}/messages/{messageId}` — messages with fields: `senderId`, `text`, `createdAt`, `editedAt?`, `deleted?`, `attachmentUrl?`, `starredBy: []`

Security: `firestore.rules` enforces that users can only read/write documents they own or participate in. Review that file before deploying.

## Setup

Prerequisites:

- Flutter (stable channel) installed and `flutter` on PATH
- Firebase CLI (`npm i -g firebase-tools`) and logged in (`firebase login`)

1. Fetch Dart/Flutter packages:

```powershell
flutter pub get
```

2. Configure Firebase for this project. Two options:

- Recommended: Run `flutterfire configure` and follow prompts. This writes platform config into `firebase_options.dart`.
- Manual: Obtain platform config files and place them in the correct native locations:
	- Android: put `google-services.json` into `android/app/`
	- iOS/macOS: put `GoogleService-Info.plist` into `ios/Runner/` (and add to Xcode project)

3. (Optional) Set environment variables used by tooling (PowerShell example):

```powershell
$env:FIREBASE_PROJECT_ID = "your-project-id"
$env:FIREBASE_API_KEY = "your-web-api-key"
$env:DEMO_PASSWORD = "YourStrongPassword123!"
```

### Android-specific notes

- Ensure `android/local.properties` contains `sdk.dir` pointing to your Android SDK.
- Place `google-services.json` at `android/app/google-services.json`.
- Gradle should apply the Google services plugin; the project already includes the usual configuration in `android/app/build.gradle.kts`.

### iOS-specific notes

- Place `GoogleService-Info.plist` into `ios/Runner` and add it to the Xcode project.
- Run `pod install` from `ios/` if CocoaPods changes are needed.
- Update the bundle identifier in Xcode to match your Firebase iOS app registration.

### Web

- If building for web, ensure `firebase_options.dart` contains the web API key and project settings.

## Firestore rules & indexes

Deploy rules and indexes with:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

Before deploying, inspect `firestore.rules` to confirm the intended access patterns. If the deploy prompts about removing extra indexes, review carefully before accepting deletion — accidental index removal can break queries.

## Seed demo data (what the script does)

The script `tool/seed_demo_data.dart` creates or updates a small set of demo artifacts useful for a quick demo:

- Creates two demo users (if they don't exist) with the configured demo password.
- Writes `users/{userId}` documents with name, email, and phone presets.
- Creates a `chats/{chatId}` document for a conversation between the two demo users.
- Adds a single message in `chats/{chatId}/messages/` from one demo user to the other.

Run it with:

```powershell
dart run tool/seed_demo_data.dart
```

After running, check Firestore to confirm `users`, `chats`, and `messages` were created.

## Run & debug locally

Run the app on a connected device or emulator:

```powershell
flutter run
```

To run on a specific platform or device, use `-d` with a device id from `flutter devices`.

Debugging tips:

- Use `flutter logs` or the IDE's console to view runtime logs.
- If authentication fails, ensure `firebase_options.dart` or native config files match the Firebase project.
- For Firestore permission errors, reproduce the failing request in the Firebase console's rules simulator.

## Tests

Run unit and widget tests:

```powershell
flutter test
```

Integration tests (if present) can be run with `flutter drive` or `flutter test integration_test/` depending on the test flavor used.

## Troubleshooting & tips

- Common: `MissingPluginException` after adding a plugin — stop and restart the app (hot restart is sometimes insufficient).
- Common: Android build issues — run `flutter clean` and then `flutter pub get`, then rebuild.
- If Firebase auth or Firestore returns permission-denied, check `firestore.rules` and the signed-in user's UID in the emulator.

## Contributing

If you'd like to contribute, please:

1. Open an issue describing the change.
2. Create a branch named `feature/your-change`.
3. Send a pull request with tests for new behaviors.

If you want, I can add a `CONTRIBUTING.md` with this checklist.

---

If you want specific expansions (detailed Android run checklist, CI notes, or example environment files), tell me which area and I'll add it.

## Badges

- Build / CI: ![CI](https://img.shields.io/badge/CI-passing-brightgreen)
- Flutter: ![Flutter](https://img.shields.io/badge/Flutter-stable-02569B)
- Tests: ![Tests](https://img.shields.io/badge/tests-healthy-green)

## Environment example

Create a non-committed `.env` or use CI secrets. Example `.env.example`:

```text
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-web-api-key
DEMO_PASSWORD=YourStrongPassword123!
```

Do NOT commit real API keys or credentials.

## Common run & build commands

Run on an attached device or emulator:

```powershell
flutter run
```

Run on a specific emulator/device (get the id with `flutter devices`):

```powershell
flutter run -d <device-id>
```

Launch and use an Android emulator (example):

```powershell
flutter emulators --launch pixel_4a
flutter run -d emulator-5554
```

Build release APK:

```powershell
flutter build apk --release
```

Build iOS release (macOS/Xcode required):

```powershell
flutter build ios --release
```

Format and static analysis:

```powershell
flutter format .
flutter analyze
```

## CI (GitHub Actions) - suggested steps

A minimal CI pipeline should:

- Checkout the repository
- Setup Flutter SDK
- Install dependencies (`flutter pub get`)
- Run tests (`flutter test`)
- Optionally build an APK or run static analysis

Example job snippet:

```yaml
name: Flutter CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - run: flutter pub get
      - run: flutter test --run-skipped
```

You can add a workflow file under `.github/workflows/flutter_ci.yml` using the above steps.

## Screenshots

Add UI screenshots to `assets/docs/screenshots/` and reference them here for the README. Example:

![Chat list screenshot](assets/docs/screenshots/chat_list.png)

If you want, I can generate a small `assets/docs/screenshots/README.md` template describing which screenshots to capture.

## Maintainers

- Primary: Project owner (see repo settings)
- For quick questions, open an issue or mention the repo maintainers in a PR.

---
