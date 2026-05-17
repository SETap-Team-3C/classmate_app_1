# Project Setup Guide

This guide explains how to set up the Classmate App development environment on your machine.  
Follow these steps if you want to contribute, modify, or run the project locally.

---

## 1. Prerequisites

Before starting, make sure you have the following installed:

### Required Software
- **Flutter SDK (3.x or later)**
- **Git**
- **Android Studio** or **VS Code**
- **Java JDK 11+** (for Android builds)
- **Xcode** (for iOS development on macOS)
- **Android Emulator** or physical Android device

### Check Flutter Installation
```bash
flutter doctor
```

This command will verify that Flutter, Dart, and other dependencies are correctly installed.
Fix any issues reported by `flutter doctor` before proceeding.

---

## 2. Clone the Repository

Clone the Classmate App repository to your local machine:

```bash
git clone https://github.com/yourusername/classmate-app.git
cd classmate-app
```

---

## 3. Install Dependencies

### Dart/Flutter Packages
Install all Dart packages defined in `pubspec.yaml`:

```bash
flutter pub get
```

### System Dependencies (Firebase)
If using Firebase, configure Firebase CLI:

```bash
npm install -g firebase-tools
firebase login
```

Then initialize Firebase for your project:

```bash
flutter pub add firebase_core firebase_auth cloud_firestore
flutter pub get
```

---

## 4. Run the App

### On Android Emulator
```bash
flutter emulators --launch Pixel_5  # or your emulator name
flutter run
```

### On iOS Simulator (macOS)
```bash
open -a Simulator
flutter run
```

### On Physical Device
Enable USB Debugging on your device and run:

```bash
flutter devices  # List connected devices
flutter run -d <device_id>
```

### Run with Specific Flavor
If your project has build flavors (dev, staging, prod):

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

---

## 5. Project Structure

```
lib/
├── main.dart              # App entry point
├── core/                  # Core utilities, constants, themes
├── models/                # Data models
├── screens/               # UI screens
├── services/              # Firebase, API services
├── widgets/               # Reusable widget components
└── features/              # Feature modules (chat, auth, etc.)
```

---

## 6. Development Workflow

### Run Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Format Code
```bash
flutter format lib/
```

### Build Release APK (Android)
```bash
flutter build apk --release
```

### Build iOS App
```bash
flutter build ios --release
```

---

## 7. Troubleshooting

### "flutter: command not found"
Add Flutter to your PATH. See [Flutter Installation Guide](https://flutter.dev/docs/get-started/install).

### Build failures
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter pub upgrade`
4. Check `flutter doctor` for missing dependencies

### Android build issues
- Update Android SDK: `flutter upgrade`
- Sync Gradle: `./gradlew clean` (in `android/` folder)
- Check Java version: `java -version` (should be 11+)

### iOS build issues
- Update pods: `cd ios && pod repo update && pod install && cd ..`
- Clear Xcode build: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

---

## 8. Next Steps

- Read the [Developer Guide](developer_guide.md) for contributing
- Check [Architecture](architecture.md) for project structure
- Review [Features](features.md) for current and planned features
- See [Roadmap](roadmap.md) for development timeline
