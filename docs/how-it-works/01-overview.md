# 01 Overview

## System map

```mermaid
flowchart TD
  citizen([Citizen])
  rsuser([Municipality user<br/>basic RS])
  vol([Volunteer<br/>Triage Agent])
  staff([Municipality staff<br/>PRO, Backoffice])

  subgraph Portal["ops-portal (Rails)"]
    web[Web UI<br/>/dopyty, /pochvaly, /profil]
    jobs[[GoodJob jobs]]
    conn[Connector<br/>/connector/*]
    api[OPS API<br/>/api/v1]
  end

  subgraph Triage["Triage Zammad"]
    tt[T-ticket<br/>triage]
    rt[R-ticket<br/>resolution]
    ut[U-ticket<br/>verification]
    trig{{Triggers 100-900<br/>schedulers}}
  end

  subgraph BO["Backoffice Zammad, one per PRO RS"]
    bt[OPS-xxxx ticket]
    sub[SUB-… subtasks]
  end

  mail[(Email<br/>Mailpit locally)]

  citizen --> web
  rsuser --> web
  vol --> Triage
  staff --> BO
  web --> jobs
  jobs <-- REST / webhooks --> Triage
  jobs -- webhook --> conn
  conn -- JWT --> api
  api -- REST --> Triage
  conn <-- REST / webhooks --> BO
  trig -- RS emails --> mail
  jobs -- citizen emails --> mail
  rsuser <-.- mail
```

Connections:

| From → To | How | Auth |
|---|---|---|
| Portal jobs → Triage | REST API | `TRIAGE_ZAMMAD_API_TOKEN` |
| Triage → Portal jobs | webhooks `/triage/webhooks/*` | `X-Hub-Signature` |
| Portal jobs → Connector | webhook to `Client.url` | signed, ES256 |
| Connector → OPS API | REST `/api/v1` | JWT, ES256 |
| OPS API → Triage | REST API | `TRIAGE_ZAMMAD_API_TOKEN` |
| Connector → Backoffice | REST API | tenant token |
| Backoffice → Connector | webhook `/connector/backoffice/webhook` | `X-Hub-Signature`, tenant secret |
| Triage triggers → email | RS emails with a `?force_rs_login` link | — |
| Portal jobs → email | citizen emails | — |

Key points:

- Triage never talks to a Backoffice directly. Everything goes
  Triage → portal → Connector (same Rails app) → Backoffice, and back through
  the OPS API.
- The portal is not the source of truth for issue state. A volunteer sets
  `ops_state` in Triage, and the portal copies it on every `ticket.updated`
  webhook (`app/jobs/triage/update_portal_issue_from_triage_job.rb`).
- The portal itself changes state only for actions in its own UI (RS
  comment, RS reassign/refer, citizen verification), and pushes them to
  Triage (`SyncIssueToTriageJob`).

## Actors

| Actor | Where they act | Identity | Notes |
|---|---|---|---|
| Anonymous visitor | Portal | `AnonymousUser` | Browse, search, map |
| Citizen | Portal | `User::Citizen` (Rodauth: password, Google, Facebook) | Writes need a verified phone (`full_access?`) and a finished onboarding |
| Municipality user, basic RS | Portal + email | `User::ResponsibleSubject`, email magic link only | Created from Triage (organization membership), see [08](08-onboarding.md) |
| Volunteer | Triage | Zammad Agent, group access, ticket owner | Sees only groups they belong to |
| Volunteer admin | Triage | role "Administrátor dobrovoľníkov" | Can change the owner |
| Triage admin | Triage | Zammad Admin | |
| Municipality staff, PRO RS | Backoffice | Agent; "Správca podnetov pre OPS" may talk publicly and change state / RS | |
| Portal tech account | Triage + Backoffice | "Aplikácia Odkaz pre starostu" (Triage user id 5) | API token; gets every group every 15 min |
| Admin (portal) | Portal | email in `ADMIN_EMAILS` (any user in dev) | `/admin/good_job`, `/admin/municipality_boundaries` |

How a portal person appears in Triage **(observed)**:

| Portal | Triage login | Triage role |
|---|---|---|
| Citizen #2 | `ops-user-2` | Portal User (customer) |
| Responsible subject #30 | `ops-rs-30` | Zodpovedný Subjekt |
| Municipality email users | their email, organization = RS name | Externý zodpovedný subjekt (first user), Customer (others) |

## Ticket kinds in Triage

One portal issue maps to up to three Zammad tickets:

| Number | `process_type` | When | Portal column |
|---|---|---|---|
| `T-<issue id>` | `portal_issue_triage` | On submit | `issues.triage_external_id` |
| `R-<issue id>` | `portal_issue_resolution` | When the volunteer accepts (`sent_to_responsible` + RS). T is closed and R is linked as its child | `issues.resolution_external_id` |
| `U-<update id>` | `portal_issue_verification` | Citizen or RS posts an update / "mark as resolved" | `issues_updates.external_id` |

`Issue#triage_process?` is simply `resolution_external_id.nil?`
(`app/models/issue.rb:125-131`).

## Basic vs PRO responsible subject

| | Basic (`pro: false`) | PRO (`pro: true`) |
|---|---|---|
| Works in | Portal (magic-link login) + email | Own Backoffice Zammad |
| Gets new issues by | Triage trigger email to org members with role "Externý zodpovedný subjekt" | Connector creates an `OPS-xxxx` ticket in Backoffice |
| Replies by | Portal (`/dopyty/:id/odpovede`) or replying to the email | Public note in Backoffice |
| Set up by | `bin/rails responsible_subjects:activate_basic` | Deploy Backoffice + `connect_backoffice` console snippet (README) |

## Open issues

Known problems in this flow, tracked in the private `slovensko-digital/ops` repo. When one is fixed, update the section above in the same PR and remove its row.

| Issue | Section | Problem |
|---|---|---|
| [ops#1327](https://github.com/slovensko-digital/ops/issues/1327) | [System map](#system-map) | Sync jobs give up after ~6 minutes, nothing re-syncs |
