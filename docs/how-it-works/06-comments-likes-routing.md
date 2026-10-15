# 06 Comments, likes and where they go

## Portal comment kinds

| Kind | Who writes it | Public on portal | Goes to Triage as | Mail to subscribers |
|---|---|---|---|---|
| `UserPrivateComment` | Citizen while in triage | no (author only) | Customer web article on T | after sync (`triage_external_id` set) |
| `UserComment` | Citizen in resolution | yes | Customer web article on R | after sync |
| `AgentPrivateComment` | Volunteer's public article on T | no (author only) | (comes from Triage) | immediately |
| `AgentComment` | Volunteer's tagged article on R | yes | (comes from Triage) | immediately |
| `ResponsibleSubjectComment` | RS in portal, RS email reply, Backoffice public note | yes | RS article (email type) on R | immediately |
| `DuplicateIssueComment` | Duplicate's text moved to the parent | yes | article on parent R | after sync |
| `Issues::Update` | Citizen or RS update / verification | yes (`published: true`) | U-ticket, later an article on R | when the U-ticket is created |

Article-type classification: `ZammadApiClient#get_article_type`
(`app/lib/zammad_api_client.rb:852-891`).

## Editing window

Citizen comments, RS comments and updates can be edited for
`COMMENT_EDITING_WINDOW_SECONDS` (300). `Issues::SyncEditableActivityToTriageJob`
re-enqueues itself until the window closes, then syncs. **(observed)**

Consequences:

- Triage sees the comment about 5 minutes late. For a supplement, that means
  the state flips back to `waiting` 5 minutes later.
- An RS comment mails subscribers **immediately**, so an edit within the
  window isn't reflected in that email.
- Triage-side edits of an article body never reach the portal. Only the
  internal/public toggle syncs (`UpdatePortalActivityFromTriageJob` sets
  `hidden`).

## Triage R-ticket article routing (tags)

| Article in Triage (R-ticket) | Portal | RS email (basic) | Backoffice (PRO) |
|---|---|---|---|
| internal | — | — | — |
| public, no tag | — | — | — |
| public `[[ops portal]]` (text module `::ops`) | AgentComment | — | only if `receive_customer_activities` |
| public `[[pre zodpovedny subjekt]]` (`::zodpovedny`) | — | yes (200 "komentáre z triáže") | yes, if newer than `responsible_subject_changed_at` |
| both tags | AgentComment | yes | yes |
| Customer article from citizen | UserComment | yes (200 "komentáre z portálu") | only if `receive_customer_activities` |
| Customer article from RS (email / portal / Backoffice) | ResponsibleSubjectComment | yes, the RS gets its own comment back | never (no echo to its own Backoffice) |
| made internal later | hidden | — | — |

On T-tickets every public agent article becomes `AgentPrivateComment`, and
no tags are needed.

The default note box in Triage is **internal** (observed). A volunteer who
forgets to switch it to public writes something nobody but Triage sees.

## Likes

| Action | Route | Stored | Synced |
|---|---|---|---|
| Like / unlike an issue | `POST/DELETE /dopyty/:id/issue_like` | `IssueLike`, `issues.likes_count` | **Not pushed.** `likes_count` reaches Triage/Backoffice only on the next `SyncIssueToTriageJob` for some other reason |
| Like / dislike an activity | `POST/DELETE /dopyty/activities/:id/activity_vote` | `ActivityVote` (+1/−1, any integer accepted) | never |

Backoffice has triggers at 10 and 100 likes (`ops_likes_count`), which are
fed only by those indirect syncs. The trigger condition uses a date operator
on an integer and may never fire (verify).

## Subscriptions

- The author is subscribed on submit.
- "Sledovať podnet" / "Zrušiť sledovanie" toggles `IssueSubscription`.
- Duplicates copy subscribers to the parent.
- Email unsubscribe links are GET requests that change state
  (`/subscriptions/unsubscribe/:token` destroys the subscription;
  `/global_subscriptions/unsubscribe/:token` turns off all mails). Mail
  scanners that prefetch links can trigger them.
