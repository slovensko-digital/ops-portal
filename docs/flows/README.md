# Flows: what the system does and why

This folder maps every user flow and every sync between the three apps:

| App | Repo | Local URL |
|---|---|---|
| **Portal**: citizens, municipality users, the OPS API and the Connector | `ops-portal` | http://localhost:3000 |
| **Triage** (Zammad): volunteers review and route issues | `ops-triage-zammad` | http://localhost:8080 |
| **Backoffice** (Zammad, one per PRO municipality): municipality staff | `ops-backoffice-saas` | http://localhost:8081 |

Use it to know what exists today, which parts have no tests, which edge
cases are open, and what could be simpler. Every claim points to code
(`file:line`). Claims marked **(observed)** were also clicked through on the
local stack (portal + Triage + Backoffice, with Rajec connected as a PRO
municipality) on 2026-10-15. How to run all three together is in
[07](07-backoffice-connector.md#running-it-locally).

## Files

| File | What it covers |
|---|---|
| [01-overview.md](01-overview.md) | System map, actors, ticket kinds (T/R/U), basic vs PRO, glossary |
| [02-issue-lifecycle.md](02-issue-lifecycle.md) | Issue states, the Triage `ops_state` and who moves the issue between them |
| [03-submission-and-triage.md](03-submission-and-triage.md) | Citizen wizard, Triage routing (700 rules), volunteer: accept, reject, request supplement, duplicate |
| [04-resolution.md](04-resolution.md) | R-ticket, responsible subject (RS) in the portal and by email, reassign / refer, verification (U-ticket), automatic "unresolved" |
| [05-praise.md](05-praise.md) | Praise (pochvala) end to end |
| [06-comments-likes-routing.md](06-comments-likes-routing.md) | Which comment goes where: portal, Triage, RS email, Backoffice. Editing window, likes, votes |
| [07-backoffice-connector.md](07-backoffice-connector.md) | PRO municipalities: Triage ⇄ portal Connector ⇄ Backoffice, subtasks (podúlohy) |
| [08-onboarding.md](08-onboarding.md) | `responsible_subjects:activate_basic`, connecting a Backoffice, users and roles in Triage |
| [09-emails.md](09-emails.md) | Every email (portal and Zammad): trigger, recipient, links |
| [10-scheduled.md](10-scheduled.md) | Cron (GoodJob) and Zammad schedulers |
| [coverage.md](coverage.md) | Flow × test matrix, gaps, and the planned integration scenarios |
| [findings.md](findings.md) | Broken flows, unhandled cases, races, simplification candidates, ranked |

Diagrams are Mermaid, so GitHub renders them inline.

## Keeping it true

- A PR that changes a flow (a job, webhook, Triage trigger, state, or email)
  updates the matching file here.
- The Triage trigger table in [03](03-submission-and-triage.md) and
  [09](09-emails.md) comes from the running config. To refresh it:
  `curl -H "Authorization: Token token=$TRIAGE_ZAMMAD_ADMIN_API_TOKEN" localhost:8080/api/v1/triggers`.
- When a finding is fixed, delete it from [findings.md](findings.md) in the
  same PR.
