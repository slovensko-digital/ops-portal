# 02 Issue lifecycle

There is no state machine in code. `Issues::State` is a lookup table and any
code can `update!(state:)`. The Triage attribute `ops_state` holds the same
keys, and the portal copies it on every Triage `ticket.updated`
(`app/jobs/triage/update_portal_issue_from_triage_job.rb:14-32`).

## States

| Key | Name (UI) | Public on portal | Set by |
|---|---|---|---|
| `waiting` | Čakajúci | no | Submit; Triage trigger 148 after the author replies |
| `waiting_for_author` | Čaká na autora | no | Volunteer (request supplement) |
| `rejected` | Zamietnutý | no | Volunteer; Triage scheduler after 21 days in `waiting_for_author` |
| `duplicate` | Duplicitný | no | Volunteer + parent link |
| `resolved_private` | Vyriešený (skrytý) | no | Praise accepted as private (Triage `unresolved` → portal `resolved_private`) |
| `sent_to_responsible` | Zaslaný zodpovednému | yes | Volunteer accept; RS reassignment; Backoffice RS change |
| `in_progress` | V riešení | yes | First RS reply (portal or Triage trigger 150) |
| `referred` | Odstúpený | yes | RS "refer" in portal; `[[odstupene]]` tag in an RS email |
| `marked_as_resolved` | Označený za vyriešený | yes | RS "mark resolved" in portal; `[[vyriesene]]` tag |
| `resolved` | Vyriešený | yes | Verification accepted with `issue_resolved=yes`; author self-resolve; praise accepted public |
| `unresolved` | Neriešený | yes | Triage scheduler 15 days after `sent_to_responsible` with no reply |
| `closed` | Uzavretý | yes | Volunteer |
| `archived` | Archivovaný | (separate) | Legacy import / municipality or RS archived. No runtime flow |

Private keys: `Issues::State::PRIVATE_KEYS` (`app/models/issues/state.rb:14`).
A private issue is visible only to its author (`Issue#viewable_by?`).

## Issue (podnet / otázka)

```mermaid
stateDiagram-v2
  [*] --> waiting: citizen submits (T-ticket created)
  waiting --> waiting_for_author: volunteer asks for supplement
  waiting_for_author --> waiting: author comments (Triage trigger 148, after the 5 min edit window)
  waiting_for_author --> rejected: scheduler, 21 days
  waiting --> rejected: volunteer
  waiting --> duplicate: volunteer + link parent R-ticket
  waiting --> sent_to_responsible: volunteer accepts (RS + final text required) → R-ticket, T closed

  state "Resolution (R-ticket)" as R {
    sent_to_responsible --> in_progress: RS replies
    sent_to_responsible --> unresolved: scheduler, 15 days without reply
    in_progress --> marked_as_resolved: RS marks resolved
    sent_to_responsible --> referred: RS refers
    in_progress --> referred: RS refers
    sent_to_responsible --> sent_to_responsible: RS reassigns to another RS
    marked_as_resolved --> resolved: verification accepted (issue_resolved=yes)
    in_progress --> resolved: author self-resolves (verification)
    resolved --> in_progress: verification says not resolved
    unresolved --> in_progress: RS replies (trigger 150)
  }
  R --> closed: volunteer
```

The diagram shows the intended paths. A volunteer can set any `ops_state`
the core workflow allows (the R-ticket allows all resolution states), and
the portal accepts whatever arrives.

## Who may do what, by state

| State | Author can | RS can | Volunteer can |
|---|---|---|---|
| `waiting` | edit title, description, photos (`Issue#editable_by?`); comment (private) | — | accept / reject / supplement / duplicate |
| `waiting_for_author` | comment (private); **cannot edit** | — | same |
| `rejected` | comment, but Triage trigger 100 answers "Tento tiket je už uzavretý." | — | change it back (no guard) |
| `sent_to_responsible`…`unresolved` | comment (public), like, update / verification | reply, mark resolved, reassign, refer | anything in the R core workflow |
| `resolved`, `closed` | comment, update | blocked from reassign/refer once resolved (`issues_responsible_subject_changes_controller.rb:65-67`) | anything |

## Process switch

```mermaid
sequenceDiagram
  autonumber
  participant V as Volunteer (Triage UI)
  participant TZ as Triage
  participant P as Portal jobs
  V->>TZ: T-ticket: RS + Finálny text + ops_state=sent_to_responsible
  TZ->>P: webhook portal ticket.updated (trigger 200 "upravených podnetov na portál")
  P->>P: UpdatePortalIssueFromTriageJob: state, RS, texts, address
  P->>P: should_create_resolution_process? (not praise, no R yet, state name "Zaslaný zodpovednému", RS present)
  P->>TZ: CreateIssueResolutionProcessTicketJob: create R (same group + owner), link T→R, note, close T
  P->>P: issue.resolution_external_id set → mail issue_accepted to author
  TZ->>TZ: R created → trigger 200 "nový podnet" email to RS org, 200 "nových podnetov PRO" webhook
  TZ->>P: webhook responsible_subject ticket.created → SendNewIssueFromTriageToBackofficeJob (PRO only)
```

Code: `app/jobs/triage/create_issue_resolution_process_ticket_job.rb`,
`app/models/issue.rb:185-193`.
