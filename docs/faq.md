# Frequently Asked Questions (FAQ)

## General

### What is the Classmate App?
The Classmate App is a cross-platform Flutter application designed for classroom communication, collaboration, and real-time chat. It connects students and teachers for seamless classroom interactions.

### What platforms does it support?
The app is built with Flutter and supports:
- Android (via APK or Google Play)
- iOS (via App Store)
- Web (optional, via Flutter Web)
- Windows, macOS, Linux (desktop versions planned)

### Is the app open-source?
Yes! The project is open-source and available on GitHub. We welcome contributions from the community.

---

## Getting Started

### How do I run the app?
Use:
```bash
flutter run
```

Make sure you have an emulator running or a physical device connected.

### How do I set up the development environment?
Follow the [Setup Guide](setup.md) for detailed instructions on installing Flutter, cloning the repo, and running the app.

### What version of Flutter do I need?
Flutter 3.x or later is required. Check your version:
```bash
flutter --version
```

### Can I use VS Code instead of Android Studio?
Yes! VS Code works great with Flutter. Just install the Flutter extension.

---

## Development

### How do I add a new screen?
Create a new Dart file in `lib/screens/` or `lib/features/`, add a widget class, and register the route in `main.dart`. See [Developer Guide](developer_guide.md) for details.

### What state management library should I use?
The project supports multiple options:
- **Provider** — lightweight and simple
- **Riverpod** — improved version of Provider
- **Bloc** — powerful for complex apps

Choose based on your use case. See [Architecture](architecture.md).

### How do I contribute to the project?
Follow these steps:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Submit a Pull Request

### How do I report a bug?
Open an issue on GitHub with:
- A clear title
- Steps to reproduce
- Expected vs. actual behavior
- Screenshots (if UI-related)

---

## Firebase & Backend

### How do I set up Firebase?
Run:
```bash
flutter pub add firebase_core firebase_auth cloud_firestore
flutter pub get
```

Then configure Firebase credentials in `lib/firebase_options.dart`.

### Is Firebase required?
No, Firebase is optional. The app includes scaffolding for it, but you can use other backends. See [Architecture](architecture.md).

### How do I test without Firebase?
Yse Firebase Emulator Suite:
```bash
firebase emulators:start
```

---

## Troubleshooting

### "flutter: command not found"
Add Flutter to your PATH environment variable. See [Setup Guide](setup.md#troubleshooting).

### Build fails with "Gradle sync failed"
Run:
```bash
flutter clean
flutter pub get
```

### App crashes on startup
Check:
1. `flutter doctor` for missing dependencies
2. `flutter pub get` to install packages
3. Logcat output: `adb logcat | grep flutter`

### iOS build fails
Try:
```bash
cd ios
pod repo update
pod install
cd ..
flutter run
```

---

## Performance & Optimization

### How do I improve app performance?
- Use `const` constructors for widgets
- Profile with DevTools: `flutter pub global activate devtools && devtools`
- Lazy-load images and data
- Use `ListView.builder()` for large lists

### Can I build for production?
Yes! Use:
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## Features & Roadmap

### What features are planned?
See the [Roadmap](roadmap.md) for a detailed timeline.

### When will feature X be released?
Check the [Changelog](changelog.md) and [Roadmap](roadmap.md) for planned release dates.

### Can I request a new feature?
Yes! Open a GitHub issue with "Feature Request" as the title and describe your idea.

---

## More Questions?

If your question isn't answered here:
- Check the [User Guide](user_guide.md)
- Review the [Developer Guide](developer_guide.md)
- Search existing GitHub issues
- Open a new GitHub discussion
