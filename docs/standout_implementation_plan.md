# Coleggo standout implementation plan

**Date:** 2026-07-16  
**Source plan:** `docs/plans/2026-07-15-001-feat-workplace-commuting-vertical-slice-plan.md`

## Objective

Deliver a complete concept-demonstration slice that makes Coleggo feel like a private workplace commuting network rather than a generic lift-sharing app.

The P0 slice is:

- one active Commute Circle;
- one join request and acceptance path;
- shift-aware explainable matching;
- one upcoming journey confirmation path;
- one driver cancellation and backup path;
- privacy-safe location display;
- private-by-default reliability summaries;
- v2 local persistence;
- a dashboard and match detail update that make the value visible.

## Implementation Order

### Phase 1: Foundation

1. Add P0 domain models:
   - `ShiftPattern`
   - `PrivateCommuteLocation`
   - `CommuteCircle`
   - `CommuteRequest`
   - `JourneyOccurrence`
   - `JourneyAttendanceStatus`
   - `CancellationRecord`
   - `JourneyBackupPlan`
   - `CommuteReliabilityProfile`
   - `AccessibilityRequirement`
2. Extend `AppState` to schema version 2 while keeping the current `coleggo_app_state_v1` storage key.
3. Add v1-to-v2 migration and persisted restoration tests.
4. Convert setup routing from initial-location-only to real `go_router` redirects.
5. Define async-shaped repository results for circles, journeys, requests and reliability.

### Phase 2: Matching And Circles

1. Evolve matching into a `CommuteMatchingService` boundary.
2. Implement the 100-point scoring table from the plan.
3. Add shift compatibility, including overnight shifts.
4. Add circle fixture data and repository methods.
5. Build circle discovery, details, member list and join/acceptance flow.

### Phase 3: Dependability

1. Add journey confirmation for the next circle journey.
2. Persist attendance: confirmed, not travelling and undecided.
3. Add cancellation for one upcoming occurrence.
4. Add backup-driver suggestions from compatible colleagues.
5. Record cancellation history and local activity without fake push notifications.

### Phase 4: Privacy, Trust And Dashboard

1. Add reusable privacy notice and match explanation widgets.
2. Make reliability private-by-default and show only non-personal journey summaries publicly.
3. Add actor and audience checks in repository/controller flows.
4. Redesign Home around next journey, action centre, active circle, recommended matches and reliability.
5. Update match details to show reasons, limitations and approximate information.

### Phase 5: Documentation And Verification

1. Create product differentiation, privacy principles, domain model, future backend and final review docs.
2. Add accessibility tests for large text, semantics, status labels and action-heavy flows.
3. Run final formatting, analysis, tests and debug Android build.

## Current Baseline

- `flutter pub get`: pass.
- `flutter analyze`: pass.
- `flutter test`: pass, 10 tests.

## Quality Gates

- Do not add production dependencies unless the existing stack cannot support a planned behaviour.
- Do not expose exact home addresses, phone numbers, private emails or precise coordinates.
- Do not describe users as safe, trustworthy, insured, background checked or approved drivers.
- Do not add fake live tracking, fake chat or fake push notifications.
- Keep mock and production seams clear through repository interfaces.
- Add tests for domain behaviour before relying on UI tests.

## Definition Of Done For This Slice

- The next commute is visible and actionable from Home.
- A user can discover a Commute Circle and request to join.
- A join request can be accepted and creates membership plus upcoming journeys.
- Shift-aware matching handles overnight work and explains limitations.
- A user can confirm tomorrow's journey.
- A driver cancellation records history and offers backup suggestions.
- Privacy notices and display rules prevent exact-address or contact leakage.
- Reliability is descriptive, private-by-default and does not make safety claims.
- Important state restores after a simulated restart.
- Analysis, tests and debug Android build results are recorded in `docs/standout_final_review.md`.
