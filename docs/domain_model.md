# Coleggo Domain Model

## Profiles

`CommuterProfile` represents a verified colleague’s commute-facing profile: first name, initials, role, workplace, worksite, approximate area, broad corridor, days, preferred times, vehicle summary, shift pattern, practical requirements and commute preferences.

## Workplaces

`Workplace` and `Worksite` bound discovery to verified communities. A worksite is the practical destination for matching and circles.

## Shifts

`ShiftPattern` supports named templates and custom patterns: early, late, night, standard office and custom. It stores start time, end time, arrival buffer, departure window, recurring days, optional rota week and day or night indicator. Overnight ranges are valid and tested.

## Commutes

`Commute` stores the local user’s broad commute setup: home area, worksite, days, arrival time, departure time and optional public meeting point. It intentionally avoids exact home address storage.

## Matches

`MatchingService` implements `CommuteMatchingService`. `MatchResult` contains score, level, eligibility, weighted breakdown, positive reasons, limitations and estimated-data markers. Ineligible matches are labelled as limited even when non-essential factors score well.

## Requests

`CommuteRequest` covers request seat, offer seat, join circle, invite to circle and become backup driver. Requests include intended days, time window, worksite, seat requirement, message, one-off or recurring intent, status and expiry.

## Circles

`CommuteCircle` models recurring groups with primary driver, optional backup driver, passengers, days, departure window, arrival target, public meeting area, available seats, rules, activity, reliability summaries and states: forming, active, full, paused and archived.

## Journeys

`JourneyOccurrence` represents a dated journey generated from a recurring circle. Prototype states are scheduled, awaiting confirmation, confirmed, completed, cancelled, missed and archived.

## Attendance

`JourneyAttendance` stores each member’s confirmation: confirmed, not travelling or undecided. The prototype persists these responses without real scheduling or push notifications.

## Reliability

`CommuteReliabilityProfile` separates positive signals from warnings. Signals include completed commutes, recurring participation, late cancellation, no-show, response consistency and profile completion.

## Cancellation

`CancellationRecord` preserves cancellation history: journey, actor, cancelling profile, timestamp, affected members and reason.

## Backup Plans

`JourneyBackupPlan` stores primary driver, optional backup driver, cancellation deadline, alternative colleague matches and a public transport note placeholder.

## Messaging

`MessageThread` stores asynchronous prototype messages for accepted contexts such as Commute Circles. Threads are only accessible to participants. `CommuteMessage` stores sender, body, timestamp and delivery state. Messages are local in the prototype and are not real-time chat.

## Moderation Reports

`MessageModerationReport` records a local moderation report against a message with reporter, reason, timestamp and status. This provides a future backend boundary without claiming active production moderation in the prototype.
