# classmate_app_1

## Firestore Setup For Messaging

Deploy Firestore rules and indexes:

```powershell
firebase.cmd deploy --project classmate-app-b63b4 --only firestore:rules,firestore:indexes
```

If prompted to delete extra indexes, choose `No` unless you intentionally want to remove them.

## Seed Demo Data (Two Users + One Message)

Run:

```powershell
dart run tool/seed_demo_data.dart
```

This script will:
- create or reuse two accounts
- create/update `users` docs for both
- create/update one chat document
- insert one test message from Alice to Bob

Optional environment overrides:

```powershell
$env:FIREBASE_PROJECT_ID = "classmates1project"
$env:FIREBASE_API_KEY = "your-web-api-key"
$env:DEMO_PASSWORD = "YourStrongPassword123!"
dart run tool/seed_demo_data.dart
```
