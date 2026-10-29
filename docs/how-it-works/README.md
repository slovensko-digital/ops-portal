# How it works: what the system does and why

This folder maps every user flow and every sync between the three apps:

| App | Repo |
|---|---|
| **Portal**: citizens, municipality users, the OPS API and the Connector | `ops-portal` |
| **Triage** (Zammad): volunteers review and route issues | `ops-triage-zammad` |
| **Backoffice** (Zammad, one per PRO municipality): municipality staff | `ops-backoffice-saas` |

Use it to know what exists today, which parts have no tests, which edge
cases are open, and what could be simpler. Every claim points to code
(`file:line`). Claims marked **(observed)** were also clicked through on the
local stack (portal + Triage + Backoffice, with Rajec connected as a PRO
municipality) on 2026-10-15.

## Files

| File | What it covers |
|---|---|
| [glossary.md](glossary.md) | **Read first.** Terms used in these docs, the apps and Zammad (RS, `ops_state`, doplnenie, 700 rule…) |
| [01-overview.md](01-overview.md) | System map, actors, ticket kinds (T/R/U), basic vs PRO |
| [02-issue-lifecycle.md](02-issue-lifecycle.md) | Issue states, the Triage `ops_state` and who moves the issue between them |
| [03-submission-and-triage.md](03-submission-and-triage.md) | Citizen wizard, Triage routing (700 rules), volunteer: accept, reject, request supplement, duplicate |
| [04-resolution.md](04-resolution.md) | R-ticket, responsible subject (RS) in the portal and by email, reassign / refer, verification (U-ticket), automatic "unresolved" |
| [05-praise.md](05-praise.md) | Praise (pochvala) end to end |
| [06-comments-likes-routing.md](06-comments-likes-routing.md) | Which comment goes where: portal, Triage, RS email, Backoffice. Editing window, likes, votes |
| [07-backoffice-connector.md](07-backoffice-connector.md) | PRO municipalities: Triage ⇄ portal Connector ⇄ Backoffice, subtasks (podúlohy) |
| [08-onboarding.md](08-onboarding.md) | `responsible_subjects:activate_basic`, connecting a Backoffice, users and roles in Triage |
| [09-emails.md](09-emails.md) | Every email (portal and Zammad): trigger, recipient, links |
| [10-scheduled.md](10-scheduled.md) | Cron (GoodJob) and Zammad schedulers |
| [11-data-model.md](11-data-model.md) | Main models and how they relate. So far: categories (category → subcategory → subtype, legacy vs current, RS categories) |
| [coverage.md](coverage.md) | Flow × test matrix, gaps, and the planned integration scenarios |

Diagrams are Mermaid, so GitHub renders them inline.

## Keeping it true

- A PR that changes a flow (a job, webhook, Triage trigger, state, or email)
  updates the matching file here.
- The Triage trigger table in [03](03-submission-and-triage.md) and
  [09](09-emails.md) comes from the running config. To refresh it:
  `curl -H "Authorization: Token token=$TRIAGE_ZAMMAD_ADMIN_API_TOKEN" localhost:8080/api/v1/triggers`.
- Known problems are GitHub issues in the private `slovensko-digital/ops`
  repo, collected in the epic
  [ops#1349](https://github.com/slovensko-digital/ops/issues/1349). Each doc
  file lists the ones that touch it under **Open issues**. The PR that fixes
  one updates the affected section (diagram, flow) and removes its row.
