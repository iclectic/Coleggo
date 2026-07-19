# Future Backend Requirements

The current implementation is a local prototype with mock repositories and SharedPreferences-backed state. A production backend becomes justified when Coleggo needs secure multi-user coordination, employer-backed verification and auditable operational controls.

## Identity And Verification

- Secure authentication.
- Workplace email domain verification.
- Employer invitation codes.
- Approved worksite membership.
- Verification renewal.
- Account deletion and recovery.

## Commute Data

- Structured profile, commute, shift and circle storage.
- Route calculation from privacy-preserving approximate locations.
- Public meeting-point management.
- Journey occurrence generation from recurring circles.
- Attendance reminders and confirmation deadlines.

## Communication

- Secure messaging after mutual acceptance.
- Push notifications for confirmations, requests, cancellations and backup-driver changes.
- Notification preferences.
- Message retention, deletion and export controls.
- Moderation tooling for reported messages.

## Safety And Moderation

- Incident reporting.
- Moderation queues.
- Abuse prevention.
- Rate limiting.
- Audit logs for sensitive actions.
- Clear insurance guidance without unsupported verification claims.

## Privacy And Compliance

- Fine-grained privacy controls.
- Data retention policy.
- Export and deletion workflows.
- Access logging for administrative actions.
- Protection against employee-directory search patterns.

## Reliability

- Server-side duplicate request prevention.
- Expiry jobs for old requests.
- Cancellation history.
- Backup-driver selection workflow.
- Offline-aware mobile sync.

## Persistence Decision

SharedPreferences is acceptable for this prototype because state is small, local and user-specific. Drift or another structured database becomes justified when the app needs queryable local history, larger datasets, conflict resolution, offline queueing or relational integrity across circles, journeys, requests and attendance.
