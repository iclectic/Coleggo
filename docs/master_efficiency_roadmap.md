# Coleggo master efficiency roadmap

**Audience:** Product and engineering leads building Coleggo into a company-scale workplace commuting network.  
**Lens:** Senior platform engineering for an in-house mobility product (Uber-grade reliability and matching discipline, without becoming a public taxi marketplace).  
**Date:** 25 November 2026  
**Status:** Planning synthesis. Does not replace existing slice plans; it ranks what to do next.

## What Coleggo is for

Coleggo exists so verified colleagues can form dependable, recurring workplace journeys with privacy-preserving discovery, explainable matching, confirmation discipline and cancellation resilience.

The everyday story is simple: a colleague at the same company already drives a similar route past your area, and you want a reliable way to share that commute. That is green by design: fewer single-occupancy cars on the same corridor, without turning colleagues into taxi drivers.

It is not a public ride marketplace. Efficiency here means:

- higher seat fill on recurring corridors;
- fewer stranded passengers when a driver cancels;
- faster confirmation of tomorrow’s journey;
- lower privacy and trust risk than open lift-sharing;
- lower employer friction than unmanaged informal WhatsApp groups;
- measurable reduction in single-occupancy commuting where Circles form.

If a feature increases marketplace theatre (dynamic fares, live tracking spectacle, star ratings) without improving fill rate, confirmation rate or backup coverage, it is the wrong investment.

## Current plan stack (what already exists)

| Document | Role |
| --- | --- |
| `docs/two_hour_build_plan.md` | Original local Flutter prototype scope |
| `docs/plans/2026-07-15-001-feat-workplace-commuting-vertical-slice-plan.md` | Flagship product slice: Circles, shifts, matching, privacy |
| `docs/plans/2026-07-17-002-feat-production-readiness-plan.md` | First server-backed P1: auth, circles, journeys API |
| `docs/standout_*` | Audit, implementation order and completion review for the local slice |
| `docs/product_differentiation.md` | Product identity guardrails |
| `docs/domain_model.md` | Domain vocabulary |
| `docs/future_backend_requirements.md` | Backend capability backlog |
| `docs/prototype_validation_plan.md` | User-research validation before wider pilot |
| `docs/staging_deployment.md` | Staging host runbook |
| `docs/v4_migration.md` | Local-to-server migration contract |

**Verdict on the plan set:** Strong product identity and a coherent vertical slice. Weaknesses are fragmentation, incomplete server parity with the Flutter domain, and missing company-scale operating metrics. This roadmap closes those gaps.

## Honest baseline

### Strengths worth keeping

- Clear non-marketplace identity and safety copy boundaries.
- Repository interfaces with mock vs backend seams.
- Commute Circles, journey occurrences, attendance and backup planning as first-class concepts.
- Deterministic explainable matching with limitations, not opaque scores.
- Privacy-preserving location model and audience rules documented.
- Staging Compose path, CI for Flutter and backend, JWT auth and Prisma schema for the first API surface.

### Critical gaps for a company-grade product

1. **Split-brain client.** With `COLEGGO_USE_BACKEND=true`, only circles, journeys, notifications and auth hit the API. Matching, reliability, messaging, workplaces and verification remain mock. That is unsafe for a pilot: users will think the system is coordinated when it is not.
2. **Matching lives on the device.** Company-scale matching must be server-authoritative so scoring, eligibility and worksite boundaries cannot be bypassed, and so ops can measure match quality.
3. **No journey generation job.** Recurring Circles need scheduled occurrence creation, confirmation windows and expiry. Manual or seed-only journeys will not survive a real workplace week.
4. **Enterprise identity is incomplete.** Email/password plus simulated domain verification is fine for demos. In-house deployment needs SSO (OIDC/SAML), invitation codes or HRIS-backed worksite membership, and verification renewal.
5. **Stringly-typed domain states.** Prisma stores circle, journey and request states as free strings. Enums, transition tables and audit events are required before multi-writer clients exist.
6. **No operating metrics.** Without confirmation rate, late-cancellation rate, backup coverage and seat utilisation, the product cannot prove it is efficient at its job.
7. **Messaging and moderation are local placeholders.** Acceptable for demos; not acceptable once colleagues coordinate real journeys.
8. **README under-describes the plan.** Contributors cannot see the product north star, phase order or efficiency metrics from the root README alone.

## Efficiency model (optimise for these outcomes)

Track these as product SLIs. They replace vanity metrics such as “matches viewed”.

| Metric | Definition | Why it matters |
| --- | --- | --- |
| Circle fill rate | Occupied seats / available seats for active Circles | Core utilisation |
| Confirmation rate | Confirmed attendances / expected members before departure window | Dependability |
| Late cancellation rate | Cancellations inside the deadline window / journeys | Stranding risk |
| Backup coverage | Cancelled journeys with an accepted backup / cancelled journeys | Resilience |
| Time-to-confirm | Median minutes from prompt to first confirmation | Habit formation |
| Match eligibility precision | Share of surfaced matches with no hard limitation | Trust in scoring |
| Privacy incident count | Exact-address or contact leaks in API or UI | Non-negotiable guardrail |
| Verification integrity | Share of active users with valid worksite membership | Boundary integrity |

Target for a healthy workplace pilot: confirmation rate ≥ 80%, backup coverage ≥ 70% on cancellations, zero privacy incidents, and measurable fill-rate improvement vs informal carpool groups.

## North-star architecture

```text
Flutter client (thin, offline-tolerant cache)
        |
   HTTPS + auth (OIDC/JWT)
        |
API gateway / Express (typed contracts, rate limits, audit)
        |
Domain services: Matching | Circles | Journeys | Reliability | Messaging
        |
PostgreSQL (source of truth) + job runner (occurrence generation, expiry)
        |
Event log -> notifications / push / employer-safe aggregates
```

Principles:

- Server owns matching, membership, journey state machines and reliability events.
- Client owns presentation, local cache and optimistic UI with reconciliation.
- Mock repositories remain for demos and tests only; production builds must not mix mock domain truth with live auth.
- Prefer complete vertical slices over half-connected surfaces.

## Phased plan

### Phase 0: Plan clarity and pilot readiness (docs and gates)

**Goal:** One readable story of what Coleggo is, what is done, and what “efficient” means.

- Keep product differentiation and privacy principles as normative docs.
- Point README at this roadmap and the active engineering plans.
- Run `docs/prototype_validation_plan.md` before expanding user volume.
- Gate any external pilot on privacy copy, account deletion and verification-limit comprehension.

**Done when:** A new engineer can answer “what is Coleggo?”, “what is live vs mock?” and “what do we optimise?” from the README and this file in under ten minutes.

### Phase 1: Close the production seam (highest leverage)

**Goal:** One mode, one truth for the commute core.  
**Status:** Executed on 25 November 2026. See `docs/phase1_execution_report.md`.

1. Move matching, workplaces, verification sessions, commute requests and reliability behind the same backend flag path as circles and journeys.
2. Add server-side matching endpoint with the existing 100-point weights, eligibility and limitations.
3. Add journey occurrence generation (daily/cron) from active Circles, plus confirmation-window transitions.
4. Replace free-string states with Prisma enums and explicit transition helpers.
5. Add idempotent write endpoints for confirm, cancel and join.
6. Add refresh tokens or short-lived access tokens; store secrets only in secure storage.
7. Expand integration tests for register → verify → discover → join → confirm → cancel → backup.

**Done when:** A backend-mode build has no mock source of truth for Circles, journeys, matching or membership. Local-only mode remains an explicit demo toggle.

### Phase 2: Workplace operating system

**Goal:** Make Coleggo efficient for a single employer or multi-site organisation.

1. Employer/admin tenancy: organisations, worksites, invitation codes, domain allowlists, verification renewal.
2. Optional SSO (OIDC) for company IdP.
3. Organiser tools: pause Circle, manage seats, nominate backup, view privacy-safe attendance summaries.
4. Reliability computation from server events (confirmations, late cancels, no-shows), still private-by-default.
5. In-app notifications with real push delivery and quiet hours.
6. Secure post-acceptance messaging with retention, report queue and rate limits.
7. Employer-safe analytics: corridor density, fill rate, confirmation rate. Never employee-directory search or surveillance dashboards of individuals’ homes.

**Done when:** One worksite can run Circles for a full fortnight with confirmations, cancellations and backup without engineer intervention.

### Phase 3: Scale and hard reliability

**Goal:** Uber-grade operational discipline for the commuting domain.

1. Event-sourced audit log for membership, attendance, cancellation and moderation actions.
2. Observability: structured logs, traces, SLOs on API latency and error budget, crash reporting in the app.
3. Offline queue with conflict rules for attendance and messages.
4. Approximate routing for corridor scoring without storing exact home coordinates by default.
5. Capacity hints (“this corridor is under-served on Tue/Thu nights”) for organisers, not public heatmaps of homes.
6. Abuse prevention: rate limits, device attestation where justified, report escalation.
7. Data export, retention automation and legal hold hooks aligned with `docs/data_retention_policy_draft.md`.

**Done when:** On-call can diagnose a failed confirmation path from metrics and audit events without reading production database rows by hand.

### Phase 4: Deliberate non-goals (keep saying no)

Do not add these while optimising for workplace commuting efficiency:

- Public marketplace discovery outside verified worksites.
- Dynamic fares, surge pricing, driver earnings dashboards or tips as core mechanics.
- Live GPS tracking as a default product surface.
- Star ratings that imply character or safety.
- Claims of licence, insurance or criminal-record verification.
- Generative “AI matching” that cannot explain limitations.
- Employer surveillance of individual home locations.

Optional peer cost-sharing is allowed later as a Circle agreement, not as a marketplace. See **Funding and money** below.

## Funding and money

Funding is uncertain, and that is fine for the current stage. Do not let payment design redefine the product before Circles, confirmations and trust boundaries work.

### What money is allowed to mean here

There are two different money questions. Keep them separate.

1. **How Coleggo the product is funded** (company runway, grants, employer contracts).
2. **Whether colleagues share journey costs** (fuel, parking, congestion charge) inside a Circle.

A passenger contributing towards a driver’s fuel is not the same thing as Coleggo becoming Uber.

### Recommended default for peer money: cost-share, not fare

If colleagues want a fee, model it as **optional journey cost-sharing**, agreed inside the Circle:

- driver and passengers set a simple contribution (for example per journey or per week);
- the amount should aim to share running costs, not create driver profit;
- the app can later help calculate a suggested share from rough distance/corridor and days;
- copy must say this is cost-sharing between colleagues, not a taxi fare and not employment as a driver.

Why this matters (especially in the UK and similar markets): once drivers routinely profit from carrying passengers, the product can look like private hire / commercial passenger transport, with licensing, insurance and tax consequences. Cost-sharing keeps the green carpool story intact. Exact legal thresholds need qualified advice before any live payments launch; this roadmap is product direction, not legal advice.

### Do not build first

- Card payments, wallets, payouts, escrow or platform take-rates on every journey.
- Surge, promotional credits or driver “earnings” leaderboards.
- Making payment required before someone can join a Circle.

Early Circles should work with “settle outside the app” or “no money involved”. Money features are an add-on for Circles that want them.

### How to fund Coleggo itself (preferred order)

| Model | Fit | Notes |
| --- | --- | --- |
| Employer / facilities contract | Best long-term fit | Employer pays for fewer cars on site, sustainability reporting, quieter informal WhatsApp chaos. B2B. |
| Climate / mobility grants and partnerships | Strong for green positioning | Local authorities, employers’ net-zero programmes, transport innovation funds. |
| Freemium workplace pilot | Useful early | Free for a worksite pilot; paid admin, SSO and analytics later. |
| Optional platform fee on cost-share | Possible later only | Small facilitation fee if in-app settlement exists; never the main growth engine. |
| Advertising or public marketplace take-rate | Poor fit | Conflicts with private workplace identity and trust. |

Practical sequence while funding is unclear:

1. Prove Circles work and reduce single-occupancy trips at one worksite.
2. Sell that outcome to the employer (parking pressure, emissions, staff reliability), not to passengers as a ride brand.
3. Add optional cost-share **agreements** in-product (amounts + expectations) before any payment rail.
4. Only then consider in-app settlement, and only if legal review clears cost-sharing vs commercial hire for the launch region.

### Product rule

**Matching and reliability first. Money second. Marketplace never.**

Peer contributions may exist. Driver profit marketplaces should not.

## Engineering quality bar

- British English in user-facing copy; no unsupported safety claims.
- Every repository-backed screen has loading, empty, retry and unavailable states.
- Domain transitions tested before UI tests.
- Mock and production implementations stay clearly separated; production builds fail closed if the API is misconfigured.
- No new production dependency without a concrete Phase 1–3 consumer.
- Prefer one complete corridor vertical slice (one worksite, several Circles) over many unfinished enterprise features.

## Recommended immediate sequence

1. Update README so the plan is discoverable (this roadmap). **Done.**
2. Finish Phase 1 server parity for matching, requests and verification. **Done.**
3. Add occurrence generation and confirmation-window jobs. **Done.**
4. Instrument the efficiency metrics table above. **Done** (`GET /metrics/efficiency`).
5. Run the prototype validation plan with 5–8 real commuters. **Next.**
6. Only then expand to SSO, push and employer admin.

## Critique of earlier plans (keep / change / drop)

| Item | Judgement |
| --- | --- |
| Commute Circles as flagship | Keep. Correct differentiator. |
| Explainable 100-point matching | Keep weights; move execution server-side. |
| Local SharedPreferences prototype | Keep for demos; stop treating it as production architecture. |
| “No chat / no push” honesty | Keep for prototype; Phase 2 must replace placeholders with real systems. |
| Production-readiness P1 scope | Keep direction; widen to full domain parity before calling it pilot-ready. |
| Pilot metric “5 Circles in two weeks” | Keep as a volume gate; add confirmation rate and backup coverage as harder gates. |
| Postponing payments and live maps | Keep for core build; allow later optional cost-share, not marketplace fares. |
| Fragmented docs without a master index | Change. This file plus README become the index. |
| Green colleague carpool story | Elevate. This is the everyday reason people care. |

## Definition of “highest form” for Coleggo

The highest form is not a clone of Uber. It is an in-house commuting fabric where:

- a colleague on your corridor can invite you into a dependable recurring Circle;
- every active Circle has a known driver, backup path and confirmation habit;
- matching is explainable, worksite-bounded and server-enforced;
- privacy defaults survive scale;
- organisers and employers see corridor efficiency and greener commuting without invading home privacy;
- cancellations almost never leave passengers without a plan;
- money, if present, is optional cost-sharing between colleagues, not a public fare market.

That is the efficiency product Coleggo should become.
