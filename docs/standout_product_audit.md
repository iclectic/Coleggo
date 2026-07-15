# Coleggo standout product audit

**Date:** 2026-07-16  
**Branch:** `feat/workplace-commuting-slice`  
**Scope:** Current Flutter prototype before standout product implementation

## Baseline Commands

| Command | Result | Notes |
|---|---|---|
| `flutter pub get` | Pass | Dependencies resolved. Flutter reported newer compatible-major packages are unavailable under current constraints. |
| `flutter analyze` | Pass | No issues found. |
| `flutter test` | Pass | 10 tests passed. |

## Repository Structure

Coleggo is a single Flutter application with a feature-first structure:

- `lib/app/` contains app shell, router and theme.
- `lib/features/` contains onboarding, workplace verification, profile, commute, home, matches, requests and shell screens.
- `lib/data/models/` contains `AppState`, commute, profile, workplace, request and match models.
- `lib/data/repositories/` contains repository interfaces and local mock implementations.
- `lib/data/services/` contains matching and local storage services.
- `lib/data/mock/mock_data.dart` contains fictional workplaces, areas, commuters and seeded requests.
- `test/` contains focused data and widget tests.

The current architecture is local-only: Material 3, Riverpod, `go_router`, `shared_preferences`, `intl`, repository interfaces and Dart fixtures.

## What Already Feels Distinctive

- Workplace verification is present as a product boundary, even though it is simulated.
- Matching is deterministic and displays human-readable reasons.
- The safety screen avoids unsupported claims about driving ability, insurance and criminal history.
- The profile setup asks for approximate area rather than exact address.
- Repository interfaces and a single persisted state snapshot provide a useful seam for a future backend.
- The app already uses calm workplace-oriented copy more than taxi-marketplace copy.

## What Feels Generic

- The product centres on individual matches and ride requests, which makes it resemble a generic lift-sharing prototype.
- Recurring commuting exists only as an accepted request detail, not as a first-class group arrangement.
- Matching still feels like a score attached to people rather than a transparent decision about shared work patterns.
- The Home screen leads with broad statistics and top matches rather than operational questions about the next commute.
- Profiles are compatibility-light and do not yet express shift patterns, accessibility needs, public meeting-point preferences or recurring circles.
- Reliability is not modelled beyond request status, so dependable commuting is asserted rather than demonstrated.

## Trust Breakpoints

- Workplace verification copy is responsible, but verification is not connected to discovery rules or worksite boundaries.
- Accepted recurring commutes do not have confirmation, cancellation or backup states.
- A request can become accepted without creating a richer agreement, journey occurrence or reliability event.
- There is no distinction between a late cancellation, a normal decline, a no-show or an expired request.
- There is no actor boundary for who can accept circle membership, cancel a journey or choose a backup driver.

## Privacy Gaps

- `CommuterProfile` stores `homeArea` and `corridor`, but there is no explicit privacy model for postcode district, approximate centre, privacy radius, precise sharing state or meeting-point preference.
- Screens still read `MockData` directly in several places, increasing the chance of privacy rules being bypassed by a future widget.
- Accepted journey screens continue to use public meeting-point copy, but the product does not define what acceptance unlocks.
- Activity history, cancellation history and reliability could leak sensitive routines if added without an audience matrix.
- Free-text request messages and commuting notes are not yet constrained by privacy guardrails.

## Matching Gaps

- The existing score uses area, time, worksite, days and role, but not shift pattern compatibility.
- Overnight shifts cannot be represented safely with the current `arrivalMinutes` and `departureMinutes` fields alone.
- The score breakdown does not include limitations, eligibility or estimated/approximate flags.
- Seat availability is partly represented through role compatibility rather than as an explainable score factor.
- A weak match can still appear if it clears the low threshold, but the UI does not strongly explain essential conflicts.

## Interface Overpromises

- "Recurring commute" suggests an ongoing arrangement, but the app only shows accepted request details.
- "Compatible colleagues" implies robust commute compatibility, but matching lacks shift awareness and limitations.
- The app has no fake chat, which is good, but it also has no honest placeholder for future messaging around circles.
- The current dashboard suggests the work week is "coming together" without confirmation or resilience states.

## Missing Important States

- Commute Circle states: forming, active, full, paused and archived.
- Journey states: scheduled, awaiting confirmation, confirmed, completed, cancelled, missed and archived.
- Attendance states: confirmed, not travelling and undecided.
- Request expiration and richer request types.
- Backup-driver selection and no-backup-available state.
- Loading, empty, retry and unavailable states for repository-backed screens.

## Remove, Simplify Or Postpone

- Postpone payments, fares, earnings and any marketplace language.
- Postpone live maps, exact routing, exact distances and live location tracking.
- Postpone real-time chat and push notifications; use activity records and honest placeholders.
- Postpone employer dashboards, incident reporting implementation and moderation tooling.
- Simplify the first delivery to one strong Commute Circle and one confirmation/cancellation path before broadening.

## Ranked Findings

### P0: Breaks The Core Experience

- The app lacks first-class Commute Circles, so the strongest product differentiator is absent.
- Accepted recurring commutes lack date-specific journey occurrences, confirmation and cancellation states.
- Shift patterns cannot represent rotating, irregular or overnight work, which conflicts with the intended audience.

### P1: Required For A Credible Product

- Matching needs explicit eligibility, limitations and the requested 100-point scoring model.
- Privacy rules need a reusable `PrivateCommuteLocation` model and audience-specific display rules.
- Requests need richer commuting context, duplicate prevention and expiration.
- Persistence needs a v2 schema migration that preserves existing local progress.
- Home needs to become an operational commute dashboard rather than a generic card feed.

### P2: Strong Differentiator

- Behavioural reliability should summarise confirmations, completed journeys and cancellations without ratings.
- Backup planning should show that Coleggo is designed for dependable commuting, not only initial matching.
- Accessibility requirements can make matching more practical while staying privacy-conscious.
- Fictional data should include care, warehouse, hospital, hybrid, early, late and night-shift examples.

### P3: Future Improvement

- Secure backend authentication and real workplace verification.
- Secure messaging, push notifications and moderation workflows.
- Route calculation, public transport integration and employer-approved partner worksites.
- Account deletion, data export, audit logs and production retention policies.

## Five Highest-Value Improvements

1. Add Commute Circles as the core recurring group model and flow.
2. Add shift-aware scheduling and explainable matching with limitations.
3. Add journey confirmation, cancellation and backup planning for the next commute.
4. Add privacy-preserving location and audience display boundaries.
5. Redesign Home around next journey, action centre, circle, matches and reliability.

## Working Tree Note

The implementation started on `main` with the plan document untracked. Work moved to `feat/workplace-commuting-slice` before code changes. No unrelated uncommitted work was overwritten.
