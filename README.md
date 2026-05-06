# Classmate App

A Flutter + Firebase classmate messaging app with authentication, real-time chat, profile management, contact calling, and theme support.

## Final Submission Summary

- Authentication works with Firebase
- Real-time chat is implemented with Firestore
- Profile editing saves name, email, and phone number
- Contact calling opens the device dialer using saved phone numbers
- Firestore rules are included for secure access
- Tests are included for core flows

## Firestore Setup For Messaging

Deploy Firestore rules and indexes:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

If prompted to delete extra indexes, choose `No` unless you intentionally want to remove them.

## Seed Demo Data (Two Users + One Message)

Run:

```powershell
dart run tool/seed_demo_data.dart
```

This script will:

- create or reuse two demo accounts
- create or update `users` documents for both
- create or update one chat document
- insert one test message from Alice to Bob

Optional environment overrides:

```powershell
$env:FIREBASE_PROJECT_ID = "classmates1project"
$env:FIREBASE_API_KEY = "your-web-api-key"
$env:DEMO_PASSWORD = "YourStrongPassword123!"
dart run tool/seed_demo_data.dart
```

## Project highlights for submission

- Real-time student messaging with Firebase
- Secure Firestore rules for users, chats, and messages
- Message delete, edit, star, and read receipt actions
- Typing indicator and image attachments
- Profile settings and contact calling
- Theme persistence and cleaner navigation flows

## Why this project is good for marks

- Practical real-world use case
- Clear separation of screens, services, models, and widgets
- Analyzer-clean codebase during development
- Usability improvements added to chat and settings flows
- Includes tests and demo data tooling

## Run locally

```powershell
flutter pub get
flutter run
```

## Testing and validation

- Flutter analyzer was cleaned up during development
- Widget and unit test files are included
- Firestore rules are provided for secure user and message access

## Suggested demo flow

1. Open the app and sign in
2. Open the chat list
3. Send a message
4. Show typing and read receipt behavior
5. Edit or delete a message
6. Open profile settings and change a field
7. Show the Firestore rules file as security evidence

## Repository structure

- `lib/screens` — app screens
- `lib/services` — Firebase and business logic
- `lib/models` — data models
- `lib/widgets` — reusable UI components
- `firestore.rules` — Firestore security rules
- `test` — unit and widget tests
- `tool` — demo and helper scripts

## Final submission note

This app is intended as a polished student messaging project with technical depth, security, and usability improvements suitable for grading and presentation.
