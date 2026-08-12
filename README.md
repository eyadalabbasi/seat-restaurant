# SEAT Restaurant

SEAT V1 mobile operations app for authorized restaurant staff. The application is Inbox-first and intentionally excludes dashboards, analytics, POS, CRM, payments, and table-selection interfaces.

## Requirements

- Flutter 3.44.9 / Dart 3.12.2
- Android Studio or Xcode
- A SEAT API v0.12.0 environment

## Run

```sh
flutter pub get
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

For the isolated fixture preview:

```sh
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_FIXTURES=true

Staging, with fixtures disabled:

```bash
flutter run --flavor dev --dart-define-from-file=dart_defines/staging.json
```
```

Fixture OTP: `123456`. Phone suffixes select roles: `1111` OWNER, `2222` MANAGER, `3333` HOST, and `4444` VIEWER.

## Verification

```sh
flutter analyze
flutter test
flutter build apk --flavor dev --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_FIXTURES=true
```

Production builds require real API connectivity, signing, and production push credentials. Development fixtures are rejected outside the DEV environment.
