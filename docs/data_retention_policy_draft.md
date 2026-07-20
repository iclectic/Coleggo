# Coleggo Data Retention Policy (Draft)

**Status:** proposed operational schedule for legal and security review before launch.

## Purpose

This schedule is intended to minimise retention while preserving the information required to operate the service, protect users, resolve disputes and meet legal obligations. It must be approved by [Coleggo legal entity name], aligned with backup configuration, and reviewed at least annually.

## Proposed retention schedule

| Data category | Proposed retention | Disposal approach |
| --- | --- | --- |
| Active account and profile data | Until the user deletes their account or the account is closed | Delete from primary database through the account-deletion flow |
| Circle memberships, commute requests, attendance, cancellation and notification data | Until account deletion or feature-specific expiry | Delete through database cascades when the account is deleted; define feature expiry before launch |
| Authentication tokens | Until expiry, logout or account deletion | Delete token from secure device storage; tokens expire according to backend configuration |
| Password hashes | Until account deletion | Delete with the user account; never retain plain-text passwords |
| Workplace verification record | Until account deletion or a justified verification refresh date | Delete with account; document refresh rule before launch |
| Security and operational logs | 30 days by default, unless an incident requires longer retention | Automated log expiry with access controls |
| Abuse or safety reports | 12 months after resolution, subject to legal requirements | Restricted-access deletion workflow |
| Encrypted database backups | 35 days | Automated expiry; deletion from backups may occur on the normal rotation schedule |
| Aggregated and anonymised metrics | Only while they remain genuinely anonymised and useful | Review annually; delete when no longer necessary |

## Account deletion

In server-backed mode, users can select **Settings → Delete account**. After confirmation, the app calls `DELETE /auth/account`. The backend deletes the user, and database cascade rules remove their profile, notifications, commute requests, memberships, attendance and cancellation records. The app then removes the local token and local app state.

Deletion is immediate from the primary application database. Copies in encrypted backups are removed on the next backup-expiry cycle. This statement must be updated if infrastructure or backup retention changes.

## Controls and review

- Restrict production data access to authorised personnel.
- Encrypt data in transit and protect production secrets.
- Test account deletion and backup expiry before launch and after material schema changes.
- Keep a documented record of any legal hold that pauses deletion.
- Review this schedule after changes to product scope, hosting, incident handling or applicable law.

## Before publication

The launch owner must complete the bracketed contact details, confirm jurisdictions, validate backup retention with infrastructure providers, and obtain legal/privacy approval.
