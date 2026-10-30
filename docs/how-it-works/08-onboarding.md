# 08 Onboarding municipalities and users

## Basic municipality: `responsible_subjects:activate_basic`

```
bin/rails responsible_subjects:activate_basic \
  BOUNDARY_ID=… NAME="Rajec" DISTRICT="Žilinský" \
  USERS="podatelna@rajec.sk,jan.novak@rajec.sk" \
  TRIAGE_ZAMMAD_AGENT_EMAIL=volunteer@… [DRY_RUN=1]
```

Needs `TRIAGE_ZAMMAD_ADMIN_API_TOKEN`. Code:
`lib/tasks/responsible_subjects.rake`,
`app/models/responsible_subjects/basic_activation.rb`. Tested in
`test/models/responsible_subjects/basic_activation_test.rb`; the rake wrapper
is not tested.

```mermaid
flowchart TD
  V{validate! all checks,<br/>nothing written} -->|errors| X[print errors, abort]
  V -->|DRY_RUN| S[print summary]
  V --> A[Portal tx: Municipality NAME inactive + boundary,<br/>RS subject_name NAME, pro false, inactive]
  A --> B[Triage: RS user ops-rs-id, role Zodpovedný Subjekt]
  B --> C[Triage: group NAME, email podnety@triaz…,<br/>group added to Portal Tech Account]
  C --> D[Triage: organization NAME]
  D --> E[Triage: volunteer gets group NAME]
  E --> F[Triage: trigger 700 - Priradenie podnetu skupine NAME Agent<br/>address_municipality is NAME → group, owner, RS]
  F --> G[Triage: users. First = Externý zodpovedný subjekt, others Customer,<br/>org NAME → UpdatePortalUserFromTriageJob → portal User::ResponsibleSubject]
  G --> H[Portal tx: municipality + RS active]
```

What it refuses, and why:

- **A municipality that already exists in any state.** An existing RS may
  already have issues in the portal. Those issues would have to be imported
  into Triage first, which needs Triage `import_mode` and downtime. The task
  doesn't do that, so it supports only new municipalities.
- An RS with the same `subject_name`, emails already used by an RS user or
  existing in Triage, a group/organization/trigger with the same name.

What it doesn't handle:

- **No rollback for Triage.** If step C–G fails, the portal still has the
  inactive municipality, and Triage has a partial setup. A re-run fails
  validation on the already-created group or organization. The cleanup is
  manual.
- City parts (`Mesto::Časť`). The 700 condition is an exact match on the
  municipality name.
- PRO setup.

### Locally: `EXISTING_MUNICIPALITY=1`

The dev seeds create Banská Bystrica, Trnava, Nitra, Malacky and Pezinok and
their RS inactive. `EXISTING_MUNICIPALITY=1` (development only, the task
aborts elsewhere) activates such a municipality instead of refusing it:
step A reuses the municipality and the RS named NAME, links the boundary to
it, and sets the RS email to the first of USERS and `pro` false. The rest is
the same. `BOUNDARY_ID` and `DISTRICT` default to the municipality's own. It
refuses an active or archived municipality, a missing or active RS, and an
RS that already has a Triage user. The municipality's seeded issues are not
sent to Triage.
`bin/activate-seeded-municipalities` runs it for every seeded inactive
municipality, see "Local Triage" in the README. Then it sets `pro` true on
Malacky, whose `Client` and `Connector::Tenant` the seeds create for the
local Backoffice, see "Local Backoffice" in the README.

## PRO municipality: Backoffice

Manual: deploy a Backoffice with env `WEBHOOK_TENANT_ID`,
`OPS_RESPONSIBLE_SUBJECT(_ID)`, `API_TOKEN`, `WEBHOOK_SECRET`,
`OPS_CONNECTOR_URL`, then run the `connect_backoffice` snippet from the
README in a portal console. It sets `pro: true` and creates the `Client` and
`Connector::Tenant`. Nothing creates a Triage routing rule for a PRO
municipality. Routing them is the "750" admin-made rules, which live only in
the Triage database.

## Users across systems

A user is created either in the portal (citizen registration) or in Triage
(an agent adds them, e.g. when onboarding an RS). The portal sends a user to
Triage on their first activity, and Triage sends changes back through the
`user.updated` webhook → `Triage::UpdatePortalUserFromTriageJob`. There are no
agreed rules for the resulting state of a user in both systems, so the table
below describes what the code does today, gaps included. Deciding those rules
is the epic [ops#1350](https://github.com/slovensko-digital/ops/issues/1350).

| Event | Where it starts | Effect |
|---|---|---|
| Citizen registers (password / Google / Facebook) | Portal (Rodauth) | `User::Citizen`; email verify; onboarding; SMS phone verification (AWS) for full access |
| Citizen's first issue | Portal → Triage | customer `ops-user-<id>`, role Portal User, `origin=portal` |
| Citizen renames | Portal | `SyncUserUpdateToTriageJob` + `SyncUserUpdateToBackofficeJob` (all active tenants) |
| Citizen closes account | Portal | `User#anonymize!` changes `firstname`, which fires the rename sync: the Triage customer becomes "Anonym …" with an empty last name (`zammad_api_client.rb:523-530`). Their articles in Triage (including the original description) stay |
| Volunteer bans a user | Triage user `banned` → `user.updated` | portal `banned`, and `check_banned_user` logs them out. Only for Triage users with `origin=portal` (citizens). RS users created in Triage (`create_user!`) have no `origin`, so the ban is not copied and they keep logging in |
| Volunteer deactivates a user | Triage user `active` → `user.updated` | nothing. The job ignores `active` |
| User added to an organization named like an RS | Triage → `user.updated` | only the organization counts, the Triage role is ignored. The portal user (matched by `external_id`, then by email) becomes or is created as `User::ResponsibleSubject` (verified, onboarded, random password, magic-link login only). First name, last name and email are copied from Triage. A user matched by email keeps its old `external_id` |
| Portal citizen added to that organization | Triage → `user.updated` | same as above. The citizen's Triage customer has `firstname = display_name`, no last name and no email, so the portal name is mangled and the email is overwritten with an empty value unless the agent fills it in. Password login stops working without notice |
| User removed from that organization | Triage → `user.updated` | back to `User::Citizen`. Their RS comments and subscriptions stay as they are |
| Name or email changed in Triage | Triage → `user.updated` | copied only while the user is in an RS organization. Citizens are not updated |
| RS user edits their profile | Portal | `SyncUserUpdateToTriageJob` looks up the login `ops-user-<id>` only. RS users created in Triage have their email as login, so nothing is synced |
| RS renamed | — | `subject_name` is the join key to the Triage organization and the `responsible_subject` label. A rename breaks the email recipients and the RS user mapping |

## Open issues

Known problems in this flow, tracked in the private `slovensko-digital/ops` repo. When one is fixed, update the section above in the same PR and remove its row.

| Issue | Section | Problem |
|---|---|---|
| [ops#1341](https://github.com/slovensko-digital/ops/issues/1341) | [Basic municipality: `responsible_subjects:activate_basic`](#basic-municipality-responsible_subjectsactivate_basic) | `activate_basic` has no Triage rollback |
| [ops#1343](https://github.com/slovensko-digital/ops/issues/1343) | [PRO municipality: Backoffice](#pro-municipality-backoffice) | A PRO RS with Externý email users gets everything twice |
| [ops#1347](https://github.com/slovensko-digital/ops/issues/1347) | [PRO municipality: Backoffice](#pro-municipality-backoffice) | Backoffice `API_TOKEN` rotation is ignored after the first deploy |
| [ops#1350](https://github.com/slovensko-digital/ops/issues/1350) | [Users across systems](#users-across-systems) | Epic: no agreed sync rules for users between the portal and Triage, so bans, deactivation, organization and role changes leave inconsistent data |
| [ops#1315](https://github.com/slovensko-digital/ops/issues/1315) | [Users across systems](#users-across-systems) | An RS user deactivated in Triage can still log in to the portal |
| [ops#1304](https://github.com/slovensko-digital/ops/issues/1304) | [Users across systems](#users-across-systems) | An RS comment crashes when the RS has no `external_id` in Triage |
| [ops#1306](https://github.com/slovensko-digital/ops/issues/1306) | [Users across systems](#users-across-systems) | The "user already exists" fallback never runs on a duplicate Triage login |
