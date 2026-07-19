# Coleggo v4 local-state migration

## Background

The Coleggo Flutter prototype stores a local `AppState` snapshot in `SharedPreferences`. The current schema version is `4`. This document describes how that local state is moved to the server-backed backend when a user upgrades to the server-enabled build.

## What is migrated

When backend mode is enabled (`--dart-define=COLEGGO_USE_BACKEND=true`) and the user has a valid access token, the app attempts to upload the local v4 snapshot once on startup.

The backend `POST /auth/migrate` endpoint migrates the following fields if present:

- **Profile**: `firstName`, `initials`, `homeArea`, `corridor`, `days`, `arrivalMinutes`, `departureMinutes`, `role`, `availableSeats`, `vehicleSummary`.
- **Commute**: `days`, `arrivalMinutes`, `departureMinutes` (used as fallback profile values).
- **Circles**: local `CommuteCircle` records that belong to the user's worksite are recreated on the server. The current user is added as the circle organiser.

Items that are intentionally not migrated:

- Message threads and reports (P1 uses local-only secure messaging placeholders).
- Local ride requests and mock reliability profiles.
- Notification history.
- Cancellation history and past journeys.

## How it works

1. The app starts and `_restore()` loads the local v4 snapshot.
2. If backend mode is enabled, a token exists, and the snapshot contains a profile and commute, the app calls `AuthRepository.migrateLocalState(state)`.
3. The repository serialises the local fields and sends them to `POST /auth/migrate`.
4. The server updates the authenticated user's profile and creates circles at the user's server worksite when no circle with the same name already exists.
5. If migration fails, the app keeps the local snapshot and surfaces an error message. The user can continue in local-only mode until the server is reachable.

## Backend endpoint

`POST /auth/migrate` (requires authentication)

Example payload:

```json
{
  "profile": {
    "firstName": "Alex",
    "initials": "AL",
    "homeArea": "Bearwood",
    "corridor": "West Birmingham to city centre",
    "days": [1, 3, 5],
    "arrivalMinutes": 510,
    "departureMinutes": 1050,
    "role": "passenger",
    "availableSeats": 0,
    "vehicleSummary": null
  },
  "commute": {
    "days": [1, 3, 5],
    "arrivalMinutes": 510,
    "departureMinutes": 1050
  },
  "circles": [
    {
      "name": "Bearwood early shift",
      "shiftLabel": "early",
      "days": [1, 3, 5],
      "departureWindow": "06:40-06:55",
      "seats": 2
    }
  ]
}
```

Response:

```json
{
  "migrated": true,
  "circlesCreated": 1,
  "membershipsCreated": 1,
  "user": { ... }
}
```

## Prototype hardening notes

- The backend API base URL is now read from the `COLEGGO_API_BASE_URL` dart-define variable; it still defaults to `http://localhost:3000` for local development.
- Backend-mode circle pause and leave operations no longer silently return unchanged data. They return an explicit failure so the UI can show a "not yet supported" message.
- The v4 `AppState` schema loader continues to accept schemas versions 1-4. New builds will keep writing `schemaVersion: 4` until a future local schema change is required.

## Verification

- `npx tsc --noEmit` and `npm test` must pass in `backend/`.
- `flutter analyze --no-pub` and `flutter test --no-pub` must pass in the project root.
- For a manual migration test, register a backend account, build the app with `--dart-define=COLEGGO_USE_BACKEND=true`, and confirm that local profile and circle data appear in the server database after login.
