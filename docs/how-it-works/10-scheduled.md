# 10 Scheduled work

## Portal (GoodJob cron, `config/application.rb:35-61`)

| Key | Schedule | Job | Note |
|---|---|---|---|
| `user_stats_daily_refresh` | `0 0 * * *` | `UserStats::CalculatePercentilesJob` | Only percentiles. Nothing schedules `RefreshCountsAllJob`; counts update on issue save |
| `sitemap_daily_refresh` | `0 2 * * *` | `GenerateSitemapJob` | |
| (only if `AUTO_SYNC_LEGACY_USERS=ON`) | hourly | `Import::SyncLegacyUsersJob` | The class doesn't exist, and the setting **replaces** the two crons above |

There is no portal cron for reminders, auto-close or reconciliation with
Triage. A failed sync is retried 5 times (`ApplicationJob`) and then sits in
GoodJob as discarded (`/admin/good_job`). Nothing alerts on it.

## Triage (Zammad schedulers, `ops-triage-zammad/lib/tasks/ops/triage.rake`)

| Name | When | Condition | Action |
|---|---|---|---|
| NEMENIŤ - Neriešený po 15 dňoch od preposlania | Mon–Fri 9:00 | R, `sent_to_responsible`, `responsible_subject_changed_at` > 15 days, not closed | public note `[[ops portal]][[pre zodpovedny subjekt]]`, `ops_state=unresolved` |
| čaká na autora - 1. pripomienka (7 dní) | daily 9:00 | `waiting_for_author`, changed 7–8 days ago | public agent note (author sees it as a private comment + email) |
| čaká na autora - 2. pripomienka (14 dní) | daily 9:00 | 14–15 days ago | same |
| čaká na autora - Zamietnutie po 21 dňoch | daily 9:00 | 21 days | `rejected`, closed, public note |
| OPS - add all groups to tech role | every 15 min | — | tech account gets every group |

The reminder windows are one day wide and run once a day. If a run is
missed (downtime at 9:00), that reminder is skipped. `ops_state_changed_at`
is stored as now + 1 minute (trigger 900), which shifts the windows a little.

## Backoffice

| Name | When | Action |
|---|---|---|
| tech role gets all groups | every 15 min | until then a new group is invisible to the API user, and Connector jobs fail and retry |
