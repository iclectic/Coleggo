# Coleggo

**Go to work together**

Coleggo is a private workplace commuting network for verified colleagues. The everyday idea is simple: someone at your company already drives a similar route to work, and you want a reliable, greener way to share that commute.

It is **not** a public taxi marketplace, fare product or live-tracking app. The product optimises for seat fill, journey confirmation, backup coverage and trust boundaries inside an organisation. Optional peer cost-sharing may come later; marketplace driver earnings should not. See `docs/master_efficiency_roadmap.md` (Funding and money).

## Product plan (start here)

| Phase | Intent | Primary docs |
| --- | --- | --- |
| Prototype | Local Flutter vertical slice: Circles, shifts, matching, privacy | `docs/two_hour_build_plan.md`, `docs/standout_implementation_plan.md` |
| Distinctive slice | Commute Circles, confirmation, cancellation backup, reliability | `docs/plans/2026-07-15-001-feat-workplace-commuting-vertical-slice-plan.md` |
| Server P1 | Auth, Circles, journeys, server matching, jobs, reliability, metrics | `docs/phase1_execution_report.md`, `backend/README.md` |
| Workplace ops P2 | Invites, verification renewal, organiser tools, secure messaging | `docs/phase2_execution_report.md` |
| Company scale | SSO, real push delivery, deeper employer admin | **`docs/master_efficiency_roadmap.md`** |

**North star:** verified colleagues form recurring Commute Circles that survive real working weeks (confirmations, cancellations, backups) without exposing exact home addresses or pretending to verify licences, insurance or character.

Read `docs/master_efficiency_roadmap.md` for the ranked improvement plan, efficiency metrics and what to build next. Read `docs/product_differentiation.md` for identity guardrails.

## Current capability

- Flutter client with Material 3, Riverpod, `go_router` and repository interfaces.
- Local demo mode with fictional workplaces, Circles, matching and persistence.
- Optional backend mode (`COLEGGO_USE_BACKEND`) with Node.js/Express, PostgreSQL/Prisma, JWT auth, Circles, journeys and notifications.
- Simulated workplace verification code in local mode: `246810`.

Prototype safety boundary: all organisations and profiles in fixtures are fictional. Workplace verification confirms simulated access to a workplace email, not identity or driving fitness. Drivers remain responsible for their vehicle, licence and insurance. Prefer public meeting points.

## Run locally (Flutter)

```bash
flutter pub get
flutter run
```

### Backend-backed client

```bash
# terminal 1
cd backend && cp .env.example .env && docker compose up -d
npm install && npx prisma migrate dev && npx prisma db seed && npm run dev

# terminal 2
flutter run --dart-define=COLEGGO_USE_BACKEND=true --dart-define=COLEGGO_API_BASE_URL=http://localhost:3000
```

See `backend/README.md` and `docs/staging_deployment.md` for API and staging details.

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Backend:

```bash
cd backend && npm test
```

## Architecture snapshot

```text
Screens → Riverpod controllers → repository interfaces
                                      ├─ local mock repos + SharedPreferences
                                      └─ backend API client (optional)
```

Important local state is one versioned JSON snapshot. Production direction is server-authoritative Circles, journeys and matching, with the client as a cache and UI layer. Mock and production implementations stay separated on purpose.

## Documentation map

- `docs/master_efficiency_roadmap.md` – master plan and senior critique
- `docs/domain_model.md` – domain vocabulary
- `docs/privacy_product_principles.md` – discovery and location rules
- `docs/future_backend_requirements.md` – backend backlog
- `docs/prototype_validation_plan.md` – user validation before pilot
- `docs/v4_migration.md` – local-to-server migration
- `AGENTS.md` – contributor rules
