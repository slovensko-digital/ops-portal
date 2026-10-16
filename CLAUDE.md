# ops-portal

Rails 8 app. Tests use Minitest, fixtures, Capybara system tests and WebMock.

Before writing or changing tests read `docs/TESTING.md`. It defines which
level (system, integration, model, job, mailer) each kind of code is tested at
and what a test should assert.

## How it works docs

`docs/how-it-works/` describes every flow between the portal, Triage and Backoffice.
When you change a flow, update the matching file in the same PR:

| Code | Doc |
|---|---|
| `app/jobs/triage/*`, `app/controllers/triage/*`, `app/jobs/sync_*_to_triage_job.rb`, `app/jobs/issues/sync_editable_activity_to_triage_job.rb` | 02, 03, 04, 06 |
| `app/models/issue.rb`, `app/models/issues/*` (states, callbacks) | 02 |
| `app/controllers/issues/*`, `app/jobs/issues/draft/*` (wizard) | 03 |
| `app/controllers/praises_controller.rb` | 05 |
| comments, likes, votes, subscriptions | 06 |
| `app/jobs/connector/*`, `app/controllers/connector/*`, `app/controllers/api/v1/*` | 07 |
| `app/models/responsible_subjects/basic_activation.rb`, `lib/tasks/responsible_subjects.rake`, rodauth / profiles | 08 |
| `app/mailers/*`, `app/views/*_mailer/*`, `app/jobs/notifications/*` | 09 |
| `config/recurring.yml` | 10 |

A new flow, email or scheduled job gets a row in the doc and in
`docs/how-it-works/coverage.md`. When you fix a problem listed under
**Open issues** in a doc file, update the affected section (diagrams, flow)
and remove its row in the same PR. Flow changes made in `ops-triage-zammad` or
`ops-backoffice-saas` (triggers, core workflows, schedulers, patches) are
documented here too.
