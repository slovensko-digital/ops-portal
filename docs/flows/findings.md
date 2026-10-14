# Findings

Ranked by impact. **Evidence** values:

- **Observed**: reproduced on the local stack (portal + Triage + Backoffice) on 2026-10-15.
- **Code**: read and confirmed in the source.
- **Verify**: needs a check against production config or data.

Fix each one in its own PR and delete its row here when it lands.

## High: users or municipalities are affected today

| # | Finding | Evidence | Where |
|---|---|---|---|
| H1 | **No routing fallback in Triage.** A new ticket whose `address_municipality` doesn't exactly match a 700 rule stays in `Incoming` with no owner and no RS. Volunteers can't see `Incoming`, nobody is notified, and the citizen sees "Čakajúci" forever. Affects city parts (`Mesto::Časť`), renamed municipalities, and any active municipality without a rule. | Observed (Bratislava issue T-300302: volunteer and local admin both got "not authorized") | `basic_activation.rb:204-225`; Triage groups/roles |
| H2 | **RS reassign/refer shows up twice on the portal.** The portal posts the `ResponsibleSubjectChange` to Triage as an RS email article. Triage echoes it back (trigger 200 "nových komentárov na portál"), and `CreateNewPortalActivityFromTriageJob` dedupes only `issue.comments`, so it creates a second `ResponsibleSubjectComment` with the same text and triage id and mails subscribers again. | Observed (issue 300303, both rows have `triage_external_id` 58) | `app/jobs/triage/create_new_portal_activity_from_triage_job.rb`; `sync_issue_activity_object_to_triage_job.rb` |
| H3 | **Duplicate-check dead end in the wizard.** "Zobraziť podobné podnety" redirects to the issue list. Nothing there tells the user how to continue. They must find the header button "Neodoslaný podnet" and resubmit from the summary. | Observed | `drafts_controller.rb:53-57`, `drafts/checks/show.html.erb` |
| H4 | **Rejected issue can't be supplemented.** Only `waiting_for_author` flips back on an author reply (trigger 148). A rejected issue can't be edited, and an author comment changes nothing. The volunteer must notice the comment. The team's planned test "doplnenie odmietnutého podnetu" has no flow to test. | Code + Triage trigger list | `issue.rb:147-160`; Triage trigger 148 |
| H5 | **Praise or ticket without an RS breaks silently.** RS emails go to nobody (the recipient override returns nil), and `ResponsibleSubject.find(nil)` raises in the Backoffice jobs (5 retries). RS is mandatory only for `sent_to_responsible`, not for a praise. | Code | `ops-triage-zammad/zammad/lib/ops/ticket_perform_changes_action_notification_email_extensions.rb:3-8`; `send_new_issue_from_triage_to_backoffice_job.rb:4-6` |
| H6 | **Lost-update race between portal and Triage state.** A portal state change (RS comment → `in_progress`) enqueues `SyncIssueToTriageJob`. If any Triage `ticket.updated` job runs first, it copies the stale Triage state back over the portal, and the sync then pushes the stale state. There are no version checks and no GoodJob concurrency keys. | Code | `update_portal_issue_from_triage_job.rb`, `sync_issue_to_triage_job.rb` |
| H7 | **Backoffice subtasks get lost after a deploy.** Every subtask job failed "Not authorized": the tech account had no access to group "Podúlohy". The role gets new groups only from a 15-minute scheduler, and the rake resets that scheduler's `last_run` on every container start. The jobs gave up after 5 attempts (about 6 min), 20 s before the scheduler would have granted access. No `SUB-` tickets were created, and the note carrying `[[podulohy]]` is never forwarded, so nobody notices. | Observed (OPS-300305, jobs discarded 01:40:20–22) | `ops-backoffice-saas/zammad/lib/tasks/ops/backoffice.rake:1195-1204`; `ops/assign_tech_role_to_all_groups_job.rb`; `ApplicationJob` retry |
| H8 | **Sync jobs give up after about 6 minutes, with no reconciliation.** `ApplicationJob` retries 5 times (polynomially longer). When Triage or Backoffice is down longer than that (a deploy, an outage), the issue, comment or update never arrives, and nothing re-syncs or alerts. Discarded jobs only sit in `/admin/good_job`. | Observed (Triage down: the T-ticket appeared on attempt 4 after 3.5 min; subtasks discarded after attempt 5) | `app/jobs/application_job.rb` |

## Medium: wrong or missing behaviour in a narrower path

| # | Finding | Evidence | Where |
|---|---|---|---|
| M1 | Request supplement sends the author **two emails** for one action (comment + state), with the same subject. | Observed | `PublishNewIssueCommentJob` + `PublishIssueStateChangedJob` |
| M2 | Default Triage note is **internal**. A volunteer who forgets to switch it gets a state change with no visible explanation for the author. | Observed | Zammad UI default |
| M3 | Supplement text is not merged. The volunteer must copy the author's reply into "Finálny text podnetu" by hand, and on accept the portal overwrites the citizen's description with that text. | Observed | `update_portal_issue_from_triage_job.rb` |
| M4 | **5-minute edit window delays Triage.** Comments sync only after `COMMENT_EDITING_WINDOW_SECONDS`, so a supplement flips `waiting` 5 minutes later. RS comment emails go out immediately, before the window ends, so a later edit isn't in the mail. | Observed | `sync_editable_activity_to_triage_job.rb` |
| M5 | `force_rs_login` while logged in as a citizen shows the RS login page with the citizen still logged in. `session[:force_rs_login]` is never cleared. | Observed | `issues_controller.rb:132-140` |
| M6 | No portal email for an RS reassign/refer: `PublishNewIssueCommentJob` has no branch for `ResponsibleSubjectChange` (and H2 then sends a duplicate one instead). | Code | `publish_new_issue_comment_job.rb:12-19` |
| M7 | Hand-off away from a PRO RS isn't propagated. Only the new RS's Backoffice is told. A portal-initiated reassignment also doesn't set `previous_responsible_subject`. | Code | `send_new_issue_update_from_triage_to_backoffice_job.rb`; `zammad_api_client.rb:283-307` |
| M8 | Tag-driven states (`[[vyriesene]]`, `[[odstupene]]`) reach the portal but never Backoffice. The tag list has a typo: Triage `[[vyriešaný]]` vs portal `[[vyriešený]]`. | Code | `triage.rake:1741-1790`; `zammad_api_client.rb:19` |
| M9 | `Issues::Update` is `published: true` and mailed before volunteer approval; a rejected update was already public and emailed. | Code | `issues_updates_controller.rb:39` |
| M10 | Likes are never pushed to Triage/Backoffice on like/unlike. Backoffice 10/100-likes triggers depend on unrelated syncs. | Code | `issue_likes_controller.rb` |
| M11 | Postmaster filter regex `#R?-?(\d{5,6})` misses ids < 10000 and truncates 7+ digits. An RS email reply then becomes a new ticket. | Code | `identify_responsible_subject_sender.rb` |
| M12 | OPS API `show` never fills `responsible_subject_changed_at` / `resolution_started_at` (the Backoffice field stayed empty on OPS-300305). `show` raises on an unknown category; `update` has a double render on falsy update; `index` crashes for a client without an RS. | Observed + code | `api/v1/issues_controller.rb:27-30`; `show.json.jbuilder` |
| M13 | Connector jobs crash on Backoffice tickets the Connector didn't create (manual, subtasks, sample ticket): `nil.triage_external_id`, 5 retries each update. | Code | `update_triage_issue_from_backoffice_job.rb:4`, `update_subtask_from_parent_ticket_job.rb:4` |
| M14 | Subtask parser splits on `<br>` only. The desktop editor emits `<br>` and `&nbsp;-` after a mention, which parses fine (observed). `<div>`/`<p>` lines (other editors), `&nbsp;` before the date, and trailing text silently drop subtasks or dates. | Observed + regex probed | `connector/subtask_parser.rb` |
| M17 | The README `connect_backoffice` snippet uses `ResponsibleSubject.find_by!(name:)`, which raises for every RS made by `activate_basic` (only `subject_name` is set). Basic → PRO upgrades fail at step one. | Observed | `README.md` "Connect new Backoffice instance" |
| M18 | **A PRO RS that keeps its Externý email users gets everything twice.** It gets the Triage email *and* the Backoffice ticket on accept, and an email about **its own** Backoffice comment (trigger 200 "komentáre z portálu"). Nothing turns the email channel off when a municipality becomes PRO. | Observed (`podatelna@rajec.sk`) | Triage triggers 200; `connect_backoffice` |
| M19 | A `pro: true` RS without a `Client` raises "No clients found" in every PRO job (issue, update, activity). They retry until discarded, so the issue never reaches anyone digitally. All seeded RS are `pro: true`, but only two have clients. | Observed (hand-off to Trnava) | `send_new_issue_from_triage_to_backoffice_job.rb:6`, `process_new_activity_from_triage_job.rb` |
| M20 | `::po` in Backoffice matches two text modules, and the highlighted default is "Verejný komentár" (`[[ops portal]]`), not "Vytvorenie podúloh". Enter inserts the wrong tag. | Observed | `backoffice.rake:495-502` text-module keywords |
| M15 | `activate_basic` has no Triage rollback. A failure midway leaves a partial setup, and a re-run fails validation. | Code | `basic_activation.rb:43-76` |
| M16 | `SyncIssueToTriageJob` maps process type by **Slovak state name**. A first sync of `waiting_for_author` / `resolved_private` / `archived` raises `KeyError`, and `Zamietnutý` maps to resolution. Only bulk import or recovery hits this. | Code | `sync_issue_to_triage_job.rb:121-133` |

## Low: hygiene, dead code, security hardening

| # | Finding | Where |
|---|---|---|
| L1 | `ChecksController#confirm` renders nothing when not confirmable; no double-submit lock on confirm | `drafts/checks_controller.rb` |
| L2 | `Connector::WebhooksController` uses `render text:` (invalid); `Backoffice::WebhooksController#set_tenant` guard is dead | controllers |
| L3 | Unsubscribe GET endpoints mutate state (link prefetchers) | `subscriptions_controller.rb`, `global_subscriptions_controller.rb` |
| L4 | JWT `jti` replay not enforced; JWT sent in query string; Connector `v1,` HMAC keyed with a public key; no webhook timestamp tolerance | `api_token_authenticator.rb:28`, `connector/webhooks_controller.rb:48-51` |
| L5 | Unauthenticated `/api/v1/issues/search`, `/api/v1/responsible_subjects`, anonymous `/uploads` | routes |
| L6 | `AvatarsController` lacks `require_user`; `/profil/overene` has no action | controllers |
| L7 | Comment/update controllers use `require_user` instead of `require_full_access_user`; updates on triage issues allowed server-side | `issues_user_comments_controller.rb:3`, `issues_updates_controller.rb:3` |
| L8 | `AUTO_SYNC_LEGACY_USERS=ON` replaces all crons and points at a missing class; several legacy import jobs reference missing classes | `config/application.rb:53-60`, `app/jobs/import/*` |
| L9 | Triage: dead core workflow (`portal_issue_resolved_verification`); triggers reference non-existent `address_municipality_district`. Backoffice: core workflow sets `ticket.investment` (should be `ops_investment`); `origin=subtask` isn't a select option; two core workflows share priority 120 | `triage.rake:873-891`; `backoffice.rake:847,360` |
| L10 | Seed data typo "nefunknčné" shown to users in the wizard | categories seed |
| L11 | Backoffice `API_TOKEN` applied only when `User.count <= 3`, so a rotation silently does nothing | `backoffice.rake:306` |
| L12 | Local dev: the Backoffice `.env.sample` has `OPS_PORTAL_URL=https://…` (RS autocomplete fails against the HTTP portal) and RS id `1`, while portal seeds have Staré Mesto as `9`. Triage and Backoffice on `localhost:8080`/`:8081` share cookies and log each other out; use `127.0.0.1:8081` | `ops-backoffice-saas/.env.sample` |
| L13 | The RS value is an integer when the portal or 700 rules write it (`30`) and a string when it comes from Backoffice (`"20"`, observed on R-300305). Triggers that compare `{label, value}` (800 "Iný subjekt" = `"410"`, Backoffice "different RS" core workflow) may match one form only | Triage 800 triggers; `backoffice.rake:578-583` |

## Corrections to assumptions

- "The supplement state never changes back automatically" is wrong. Triage
  trigger 148 sets `waiting` when the author replies (observed). Only a
  *rejected* issue has no way back (H4).
- Sub-issues (`::po → [[podulohy]]`, `@@user … - date`) exist only in
  **Backoffice**, not in Triage.

## Simplification candidates

1. **One "create or adopt existing" helper** for Zammad objects. The
   catch-"already exists"-then-search pattern is copy-pasted about 9 times
   across `SyncIssueToTriageJob`, `CreateIssueResolutionProcessTicketJob`,
   `SyncIssueActivityObjectToTriageJob` and `Connector::ZammadApiClient`.
2. **State keys, not names.** Drop the Slovak-name maps in
   `SyncIssueToTriageJob` and the `state.name == "Zaslaný zodpovednému"`
   check in `Issue#should_create_resolution_process?`.
3. **Send the RS id and pro flag in the Triage webhook payload.** That saves
   a Triage API round-trip on every R-ticket event just to learn the RS isn't
   PRO, and removes the `find(nil)` crash.
4. **Dedupe inbound articles by `triage_external_id` across all activity
   objects** (comments, updates, RS changes) with a unique index. That fixes
   H2 and the comment races.
5. **Generate Triage triggers from a table.** `triage.rake` is around 2000
   lines of hash boilerplate. Merge 150/151 into one trigger.
6. **Replace `[[tags]]` with article attributes** (or at least one shared
   tag list in both repos) to end the typo class of bugs (M8).
7. **One Zammad API base client** shared by `ZammadApiClient` and
   `Connector::ZammadApiClient`. Both have their own `raw_api_request`,
   `check_import_mode!`, user lookup and group add.
8. **Routing as data.** One "municipality → group/owner/RS" table (portal
   side or a single Triage trigger with a lookup) plus an `Incoming` fallback
   owner, instead of one 700 trigger per municipality. That fixes H1.
