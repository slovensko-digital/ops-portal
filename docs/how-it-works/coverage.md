# Test coverage by flow

Baseline from `bin/rails test:all` on 2026-10-15: **582 runs, 0 failures**.
Line coverage 77.9%, branch coverage 58.2% (SimpleCov, system + unit merged).

Everything is tested inside the portal with WebMock. **No test crosses into a
real Zammad**, and Triage and Backoffice have no tests at all: triggers, core
workflows, schedulers, the email recipient override, the postmaster filter,
and the Ruby patches are all untested. `test/integration/` is empty.

## Flow × tests

✅ covered · 🟡 partly · ❌ none

| Flow | Doc | Tests | Status | Biggest gap |
|---|---|---|---|---|
| Register / login / OAuth / magic link / ban | [08](08-onboarding.md) | `system/authorization_test.rb`, `controllers/rodauth_controller_test.rb` | 🟡 | password reset, login change, close account |
| Phone verification | [08](08-onboarding.md) | `system/profiles/verifications_test.rb`, controller test | 🟡 | `check_code` success/fail; `SendVerificationCodeJob` test file is empty |
| Submission wizard | [03](03-submission-and-triage.md) | `system/issues/drafts_test.rb` (3), `models/issues/draft_test.rb` | 🟡 | `drafts_controller.rb` 61% lines; duplicates step; question flow; Gemini/Nominatim jobs (empty test files); no assert that `SyncIssueToTriageJob` is enqueued |
| Edit while waiting | [03](03-submission-and-triage.md#3-author-edits-while-waiting) | — | ❌ | whole flow |
| Portal → Triage create | [03](03-submission-and-triage.md) | `jobs/sync_issue_to_triage_job_test.rb` (7) | 🟡 | `sync_issue_to_triage_job.rb` 69% lines, 26/70 branches |
| Comment → Triage | [06](06-comments-likes-routing.md) | `jobs/sync_issue_activity_object_to_triage_job_test.rb` (4, updates only) | ❌ | **28.6% lines, 7/84 branches**: article creation, author creation, "already exists" recovery; `SyncEditableActivityToTriageJob` 43%, its test file is empty |
| Triage → portal (state, comments, users) | [02](02-issue-lifecycle.md) | `jobs/triage/*` (all 17 jobs have tests) | ✅ | duplicate failure branches; attachment decode |
| State / RS history in the timeline, backfill | [02](02-issue-lifecycle.md#state-and-rs-history-on-the-portal) | `jobs/triage/backfill_issue_history_job_test.rb` (6), `lib/zammad_api_client_test.rb` (`get_ticket_history`) | 🟡 | `Issue#track_state_change` / `#track_responsible_subject_change` callbacks; the two partials |
| Accept → R-ticket | [02](02-issue-lifecycle.md#process-switch) | `create_issue_resolution_process_ticket_job_test.rb` | ✅ | — |
| Request supplement → author replies → `waiting` | [03](03-submission-and-triage.md#2a-request-supplement-doplnenie-observed) | Triage side untested; portal pieces tested separately | 🟡 | end to end; trigger 148 |
| Reject, duplicate | [03](03-submission-and-triage.md) | job tests | 🟡 | duplicate no-parent / missing-parent branches |
| RS comment / mark resolved | [04](04-resolution.md) | `system/issues/responsible_subject_comments_test.rb` (7) | ✅ | — |
| RS reassign / refer | [04](04-resolution.md) | `system/issues/responsible_subject_changes_test.rb` (4) | 🟡 | the Triage echo ([ops#1321](https://github.com/slovensko-digital/ops/issues/1321)) |
| force_rs_login | [04](04-resolution.md#force_rs_login-edge-cases-observed) | `system/issues/force_rs_login_test.rb` | 🟡 | logged-in citizen case |
| Verification / update | [04](04-resolution.md#4-verification--update-u-ticket) | `system/issues/updates_test.rb` (6), job tests | 🟡 | rejection after publish |
| Praise | [05](05-praise.md) | `system/praises_test.rb` (2), model + client tests | 🟡 | praise callbacks; no RS |
| Likes, votes | [06](06-comments-likes-routing.md#likes) | `system/issue_likes_test.rb`, `system/issues/activity_votes_test.rb` | 🟡 | `activity_vote_test.rb` empty |
| Subscriptions / unsubscribe | [06](06-comments-likes-routing.md#subscriptions) | system + controller tests | ✅ | — |
| Emails (portal) | [09](09-emails.md) | `mailers/notification_mailer_test.rb` (14), notification job tests | ✅ | `RodauthMailer` only indirectly |
| OPS API | [07](07-backoffice-connector.md) | `controllers/api/v1/*` (29) | 🟡 | falsy update ([ops#1338](https://github.com/slovensko-digital/ops/issues/1338)), client without RS |
| Connector inbound webhooks | [07](07-backoffice-connector.md) | controller tests (25) | ✅ | — |
| Connector jobs (Triage → Backoffice, Backoffice → Triage) | [07](07-backoffice-connector.md) | — | ❌ | **all of them**: 17-25% lines; `SendNewActivityToTriageFromBackofficeJob` and `Connector::OpsApiClient` 0% |
| Subtasks | [07](07-backoffice-connector.md#subtasks-podúlohy) | `lib/connector/subtask_parser_test.rb` (16), job test (7) | 🟡 | `<div>`/`<p>` lines |
| Basic activation | [08](08-onboarding.md) | `models/responsible_subjects/basic_activation_test.rb` (14) | ✅ | rake wrapper; partial-failure re-run |
| Citizen rename → Triage/Backoffice | [08](08-onboarding.md) | — | ❌ | 40-67% lines |
| Scheduled (portal) | [10](10-scheduled.md) | — | ❌ | — |
| Scheduled (Triage reminders, 15-day unresolved) | [10](10-scheduled.md) | — | ❌ | — |

## Planned integration scenarios (team list) vs reality

| Scenario | Exists today? | Notes for the test |
|---|---|---|
| portal → triage: submit | yes (observed) | assert T-ticket fields, group `Incoming` and then the 700 routing; also a municipality **without** a rule ([ops#1320](https://github.com/slovensko-digital/ops/issues/1320)) |
| portal → triage: comment | yes (observed) | 5-minute window: freeze time or set `COMMENT_EDITING_WINDOW_SECONDS=0` |
| portal → triage: like / dislike | **no sync** ([ops#1336](https://github.com/slovensko-digital/ops/issues/1336)) | an issue like only reaches Triage on another sync; an activity dislike never does. Decide the intended behaviour first |
| portal → triage: supplement a rejected issue | **no flow** ([ops#1323](https://github.com/slovensko-digital/ops/issues/1323)) | only `waiting_for_author` → author reply → `waiting` exists (trigger 148) |
| triage: volunteer rejects | yes | system note + `issue_rejected` mail; T not closed |
| triage: volunteer requests supplement | yes (observed) | expect 2 emails today ([ops#1328](https://github.com/slovensko-digital/ops/issues/1328)) |
| triage: volunteer accepts (+ RS before) | yes (observed) | RS + "Finálny text" required; R created, T closed, RS email, `issue_accepted` |
| triage admin: onboard municipality | yes (`activate_basic`) | only non-existing municipalities |
| triage admin: 7xx rules for RS / owner | 700 created by code; 750 hand-made | rule order is by name |
| triage → portal: RS change / assignment | RS yes; owner/group **not mirrored** in the portal | |
| portal → backoffice: RS change / assignment | RS via Triage → Connector; owner/group: no | Backoffice → Triage → portal hand-off observed ([ops#1333](https://github.com/slovensko-digital/ops/issues/1333), [ops#1348](https://github.com/slovensko-digital/ops/issues/1348)) |
| triage → backoffice | yes (observed), through the portal Connector | cover the hand-off and the "PRO without Client" failure ([ops#1344](https://github.com/slovensko-digital/ops/issues/1344)) |
| what Triage sets on a praise | answered in [05](05-praise.md#what-triage-sets-on-a-praise) | |
| sub-issues in a Zammad text field | Backoffice only, see [07](07-backoffice-connector.md#subtasks-podúlohy) | |

## Where a test would buy the most

1. `SyncIssueActivityObjectToTriageJob` (28.6%): every comment, RS reply and
   update goes through it.
2. All `Connector::*` jobs, plus `Connector::OpsApiClient` (0-25%): the
   whole PRO path is untested.
3. One end-to-end **contract test per Triage trigger the portal depends on**
   (148, 150/151, 200 portal/PRO, 700). Today a trigger edit in the Zammad UI
   can silently break the portal.
4. The echo/dedupe cases: [ops#1321](https://github.com/slovensko-digital/ops/issues/1321) and the comment races.
5. Retry exhaustion ([ops#1326](https://github.com/slovensko-digital/ops/issues/1326), [ops#1327](https://github.com/slovensko-digital/ops/issues/1327)): a test that a discarded sync job is detectable and recoverable.
