# 09 Emails

## Portal → citizens (`NotificationMailer`)

Recipients are active `IssueSubscription`s with `email_notifiable`. Subject:
"Odkaz pre starostu | <title> (Podnet|Otázka|Pochvala #id)". Header
`List-Unsubscribe` (one-click POST).

| Mail | Trigger | Recipients | Main link |
|---|---|---|---|
| `issue_accepted` | `resolution_external_id` set (accept) | author | `/dopyty/:id` |
| `praise_accepted` | praise waiting → resolved / resolved_private | author | `/dopyty/:id` |
| `issue_rejected` | → rejected | author | `/dopyty/:id`, `/pravidla` |
| `issue_marked_as_duplicate` | → duplicate | all subscribers | `/dopyty/:id` (no link to the original) |
| `issue_waiting_for_author` | → waiting_for_author | all (in practice the author) | `/dopyty/:id#new_issue_activity` |
| `issue_resolved` | → resolved | all | issue + feedback (`/pochvaly/nova`) |
| `issue_unresolved` | → unresolved | all | `#new_issue_activity` |
| `issue_referred` | → referred | all | `#new_issue_activity` |
| `issue_closed` | → closed | all | issue, `#new_issue_activity` |
| `new_issue_user_comment` | user / agent / private agent / duplicate comment, `Issues::Update` | all except the comment author; never for a praise | `#new_issue_activity` |
| `new_issue_responsible_subject_comment` | RS comment | all except the author | `#komentar_<id>` |

No mail: `sent_to_responsible`, `in_progress`, `marked_as_resolved`, RS
reassign/refer, likes.

**Observed:** request supplement sent the author **two** emails at once (new
comment + waiting for author), with the same subject.

Every mail also has `/subscriptions/unsubscribe/:token` (destroys the
subscription on GET) and `/global_subscriptions/unsubscribe/:token` (all
mails off on GET).

## Portal → anyone (`RodauthMailer`)

| Mail | Link | Valid |
|---|---|---|
| verify account | `/verify-account?key=` | |
| reset password | `/reset-password?key=` | |
| verify login change | `/verify-login-change?key=` (to the new address) | |
| email auth (magic link, RS login) | `/email-auth?key=` → confirm page → `session[:login_redirect]` | 10 min |

## Triage → responsible subject (basic)

Sender: the group's email address (`podnety@triaz.odkazprestarostu.sk`).
Recipients: active members, with role "Externý zodpovedný subjekt", of the
organization whose name equals the ticket's RS label. This goes through the
`userid_<template-ext>` recipient override
(`ops-triage-zammad/zammad/lib/ops/ticket_perform_changes_action_notification_email_extensions.rb`).

| Trigger (200 - ops - preposielanie - Zodpovedný subjekt - …) | When | Link |
|---|---|---|
| nový podnet | R created, or RS changed | `portal_url?force_rs_login` **(observed)** |
| komentáre z portálu | public Customer article (not email) on R | `?force_rs_login` |
| komentáre z triáže | public agent article with `[[pre zodpovedny subjekt]]` | `?force_rs_login` |
| nová verejná pochvala | praise → resolved | `portal_url` **(observed)** |
| nová neverejná pochvala | praise → unresolved | `portal_url` |

Every RS email says the RS may reply by email. The reply goes through the
postmaster filter (see [04](04-resolution.md)).

Edge cases:

- No RS on the ticket → the override returns nil for **every** recipient
  type, so the email goes to nobody, silently.
- The override also returns nil for any `userid_N` other than template-ext,
  so an admin-made "email user X" trigger silently does nothing.
- A PRO RS whose staff are also in the Externý organization gets its own
  Backoffice comment back by email (via "komentáre z portálu").
- The subject regex `#R?-?(\d{5,6})` misses issue ids under 10000 (and
  locally, all `R-0xxx`). A reply to such a mail becomes a new ticket.

## Triage → volunteers

Stock Zammad notifications to the owner: "Nový tiket (title) [Tiket#T-…]",
"Aktualizovaný tiket …" **(observed)**. They link to Triage.

## Backoffice

- Stock agent notifications via `NOTIFICATION_*` SMTP.
- "OPS - email public agent article to customer" for **non-OPS** tickets
  only. Subtasks count as non-OPS (`origin=subtask`), so every public note
  on a subtask emails the agent who created it.
