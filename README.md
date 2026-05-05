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

- create or reuse two accounts
- create or update `users` documents for both
- create or update one chat document
- insert one test message from Alice to Bob

Optional environment overrides:

```powershell
$env:FIREBASE_PROJECT_ID = "classmates1project"
$env:FIREBASE_API_KEY = "your-web-api-key"
$env:DEMO_PASSWORD = "YourStrongPassword123!"
dart run tool/seed_demo_data.dart
