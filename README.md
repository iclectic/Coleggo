# Coleggo

**Go to work together**

Coleggo is a local-only Flutter prototype for voluntary workplace lift sharing. It demonstrates workplace verification, commuter profiles, explainable estimated matching, requests and recurring commutes using fictional data.

## Run locally

```bash
flutter pub get
flutter run
```

The simulated workplace verification code is `246810`.

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Architecture

The app uses Material 3, Riverpod, `go_router`, `shared_preferences`, `intl`, repository interfaces and local Dart fixtures. Important state is stored as one versioned JSON snapshot. No network service or API key is required.

## Prototype safety boundary

All organisations, worksites and commuter profiles are fictional. Workplace verification confirms simulated access to a workplace email, not a person’s identity or character. Coleggo does not verify driving ability, licences, vehicle condition, insurance or criminal history. Drivers remain responsible for their vehicle, licence and insurance, and users should choose safe public meeting points.

See `docs/two_hour_build_plan.md` for the complete implementation scope and exclusions.
