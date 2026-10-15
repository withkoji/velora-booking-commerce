# VELORA GitHub Workspace Plan

This document organizes repository operations for the public **VELORA Booking Commerce** project.

## Workspace Matrix

| Area | Tracking Issue | Purpose | Primary Output | Status |
|---|---:|---|---|---|
| Agents | #14 | Safe agent-assisted development | Agent operating rules | Planned |
| Discussions | #15 | Product/provider collaboration | Categories + routing rules | Planned |
| Actions | #16 | CI and integration validation | Required automated checks | Planned |
| Projects | #17 | Delivery management | Board, table, roadmap | Planned |
| Wiki | #18 | Architecture/runbooks | System documentation | Planned |
| Security & quality | #19 | Repository/integration hardening | Security controls | Planned |
| Insights | #20 | Engineering + launch metrics | Health metrics | Planned |
| Settings | #21 | Repository governance | Review/merge/feature rules | Planned |

## Development Flow

| Phase | Issues | Dependency | Exit Condition |
|---|---|---|---|
| Foundation | #3 | None | Data model and safe configuration defined |
| Customer UX | #4 | #3 | Customer can reach checkout safely |
| Shopify Commerce | #5 | #3, #4 | Verified payment/deposit events supported |
| Apntly Booking | #6 | #3, #5 | Appointment verification and code supported |
| Webhooks/State | #7 | #3, #5, #6 | Idempotent state transitions validated |
| Provider Marketplace | #8 | #3, #4 | Provider/mobile access controls validated |
| Membership/Commission | #9 | #3, #5, #8 | Verified commission/earnings calculation |
| CRM | #10 | #3, #5, #6 | Permitted lifecycle events routed |
| Operations | #11 | #3, #7, #8, #9 | Admin/provider dashboards authorized |
| Launch Readiness | #12 | #3–#11 | Security, integration and E2E tests pass |

## Project Fields

| Field | Values |
|---|---|
| Status | Backlog, Ready, In Progress, In Review, Blocked, Done |
| Priority | P0, P1, P2, P3 |
| Workstream | Booking, Commerce, Appointments, Provider, CRM, Operations, Security, Platform |
| Risk | Critical, High, Medium, Low |
| Target Release | v1.0, Post-launch |
| Dependency | Issue references |
| Owner | GitHub assignee/team |
| Estimate | XS, S, M, L, XL |

## Launch Gate Table

| Gate | Required Evidence |
|---|---|
| Secrets | No production secrets committed |
| Booking integrity | Cart creation never confirms appointment |
| Payment integrity | Deposit Paid requires verified payment |
| Appointment integrity | Appointment Confirmed requires booking verification |
| Idempotency | Duplicate/out-of-order webhooks cannot duplicate transactions |
| Authorization | Providers/admins see only authorized records |
| CI | Required checks pass |
| Documentation | Architecture, state machine, integration and rollback docs complete |

## Repository Section Responsibilities

### Agents
Agents must work from branches based on `main`, link issues, preserve security boundaries, and submit reviewable changes.

### Discussions
Use for ideas, Q&A, provider feedback, customer experience, and integration conversation. Reproducible defects move to Issues. Sensitive security reports never belong in public discussions.

### Actions
CI should test booking state transitions, deposit logic, gift-card exclusions, webhook idempotency, authorization, and secret safety.

### Projects
Create Board, Table, and Roadmap views. Track status, priority, workstream, dependencies, target release, risk, owner, and estimate.

### Wiki
Document system architecture, booking flow, state machine, Shopify, Apntly, Zite roles, HubSpot events, Stripe Connect boundaries, provider marketplace, mobile booking, commissions, security, troubleshooting, releases, and rollback.

### Security and Quality
Protect credentials, validate signatures, review dependencies, enforce authorization, test duplicate-payment prevention, and maintain public-repository data restrictions.

### Insights
Monitor engineering delivery plus booking-integrity metrics such as CI success, launch blockers, failed webhooks, deposit-to-confirmation conversion, active providers, commissions, and earnings.

### Settings
Keep `main` as the default branch, use PR-based material changes, prefer traceable merges, keep secrets server-side, and review repository feature/Actions permissions.

## Parent Epic

All workspace and development work supports **#2 — Build end-to-end VELORA booking commerce flow**.
