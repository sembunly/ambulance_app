# Ambulance App

Flutter ambulance app built with GetX for navigation and state, and Dio for API calls. This repository is a migration in progress: login is implemented, while Dashboard and the other feature modules are placeholders.

## Run locally

Use a Flutter SDK compatible with the Dart constraint in `pubspec.yaml`, then run:

```sh
flutter pub get
flutter run
```

The login API defaults to `http://192.168.102.24:8085/ems-api`. Set `API_BASE_URL` when the backend runs at another address:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_BACKEND_HOST:8085/ems-api
```

The app posts to `/api/v1/auth/login`. The device must be able to reach the configured backend. There are no Flutter flavors; `lib/main.dart` is the only entry point.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Login access and refresh tokens are saved with `flutter_secure_storage`. Keep local configuration and signing credentials out of Git; the repository ignores common secret file formats.
