# Expense Tracker

Flutter expense tracker with local wallets and transactions, persistent Firebase
sign-in, and live shared spending groups.

## Firebase setup

Shared groups and sign-in need a Firebase project:

1. Create a Firebase project and register an Android app with package name
   `com.example.expense_tracker`.
2. Enable **Email/Password** under Firebase Authentication providers.
3. Create a Cloud Firestore database.
4. Download the app's `google-services.json` and place it at
   `android/app/google-services.json`.
5. Publish the repository's `firestore.rules` to the project's Firestore
   security rules.
6. Run `flutter pub get`, then build and run the Android app.

The app can still build before the Firebase file is present; it displays a setup
error with a retry action until a matching config is installed. Firebase
Authentication keeps users signed in between launches; logging out from the
profile screen signs them out explicitly.
Existing accounts from the previous device-local login are migrated to Firebase
the first time they sign in on a configured device.

## Shared groups

Open **Groups** from the bottom navigation to create a group or join one using
its 8-character invite code. Members can record their contributions and add
categorized expenses. The member list, contributions, expense history, and
remaining group balance update live across signed-in devices. Each group uses
the currency selected by its creator; members should agree on that currency
before entering amounts. The group creator can permanently delete the group,
including its shared expenses and member links, for everyone.

Personal wallets and transactions remain stored locally on each device.
