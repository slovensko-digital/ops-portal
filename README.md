# README

## How it works

[docs/how-it-works/](docs/how-it-works/README.md) maps what users can do and how data syncs between the
portal, Triage and Backoffice: the issue lifecycle, which action triggers what, emails,
scheduled jobs, test coverage per flow, and the open issues that affect each flow.
Update the matching file there when you change a flow.

## Run the portal

Needs Ruby (`.ruby-version`) and Postgres with PostGIS: in Docker (`docker-compose.yml`), or a local one such as
Postgres.app on port 5432 with the role from `DATABASE_URL` in `.env` (`createuser --superuser ops`, PostGIS needs
a superuser to create its extension). A local Postgres takes the port first, the portal then uses it, and
`bin/ops` leaves the Docker one off. On a Mac, install this before running `bundle`:

```bash
brew install pkg-config libexif vips
```

First time:

```bash
cp .env.sample .env
docker compose up -d          # Postgres, unless a local one runs
bin/setup                     # bundle, db:prepare (creates and seeds the database), then bin/dev
```

Every day: `docker compose up -d`, then `bin/dev` (Rails server and the Sass watcher, `Procfile.dev`).

| What | URL |
|---|---|
| Portal | http://localhost:3000 |
| Jobs | http://localhost:3000/admin/good_job |
| Emails the portal sends | http://localhost:3000/letter_opener |

Seeded users, all with the password `password`: `admin@example.com`, `jana@example.com`,
`peter@example.com`, `anonym@example.com`, `novy@example.com` (phone not verified),
`citizen1@example.com` … `citizen20@example.com` and the responsible subject's `stare-mesto@example.com`.

Without a local Triage the portal runs, but the jobs that send issues to Triage fail. To click
through the whole flow, set up [Local Triage](#local-triage).

## Reset the dev data

Portal only (no local Triage):

```bash
rm -rf storage/[!.]* && bin/rails db:reset    # the uploaded files, then drops, recreates and seeds the database
```

Not `db:seed:replant`: it also empties PostGIS's `spatial_ref_sys`, the boundary import then fails with
"Cannot find SRID (4326) in spatial_ref_sys". `db:reset` needs `bin/dev` and consoles stopped, it drops the database.

With a local Triage, always reset both together, see [Local Triage](#reset-portal-and-triage).
Resetting only the portal leaves tickets, groups and triggers in Triage for issues and municipalities
the portal no longer has, and `bin/activate-seeded-municipalities` expects a fresh Triage.

## Local Triage

Run the portal together with a local Triage and [local Backoffices](#local-backoffice) to click through the whole
flow. Clone [ops-triage-zammad](https://github.com/slovensko-digital/ops-triage-zammad) and
[ops-backoffice-saas](https://github.com/slovensko-digital/ops-backoffice-saas) next to this repo.

| What | URL |
|---|---|
| Triage | http://localhost:8080, `admin@example.org` / `PASSword123`, volunteer `dobrovolnik@example.org` / `PASSword123` |
| Triage emails | http://localhost:8025 (Mailpit), every email Triage sends, e.g. trigger emails to responsible subjects |

First time:

```bash
bundle install
bin/ops up                           # Postgres, the database, Triage and Malacky's Backoffice, all at once
bin/activate-seeded-municipalities   # sets up the seeded municipalities in the fresh Triage, see below
bin/dev
```

Every day `bin/ops up` and `bin/dev`. `bin/ops` gets the stack ready and waits until it answers:

```bash
bin/ops up       # Postgres, db:prepare, Triage and the Backoffices, also the first time, then start bin/dev
bin/ops up --backoffices=none      # only Triage, or e.g. --backoffices=malacky,trnava, stops the other Backoffices
bin/ops down     # stops them, keeps the data (stop bin/dev with Ctrl-C)
bin/ops status   # what runs, the URLs, Docker memory
bin/ops reset    # wipes everything, see below
bin/ops logs triage zammad-railsserver   # or portal, postgres, malacky, trnava
```

With `--backoffices=none` the PRO municipalities stay PRO in the portal, their issues' Connector jobs fail in
`/admin/good_job` until their Backoffice runs. Use the other municipalities, or `bin/ops reset --backoffices=none`
and `bin/activate-seeded-municipalities` to have all of them BASIC.

`up --build` rebuilds the Zammad images after a pull in `ops-triage-zammad` or `ops-backoffice-saas`. `.env` is
copied from `.env.sample` when it's missing. `bin/ops` only touches the compose projects `ops-triage-zammad`,
`ops-backoffice-<instance>` and the container `ops-postgres`, other projects (e.g. `ops-triage-e2e`) keep running.
The worktrees of this repo share its ports and Postgres, run `bin/ops` and `bin/dev` in one of them at a time.

Who calls whom: the portal calls Triage at `localhost:8080`. Triage calls the portal at
`host.docker.internal:3000` (webhooks signed with `WEBHOOK_SECRET`, responsible subject search),
so `bin/dev` has to be running for Triage changes to reach the portal.

The seeds (`db:prepare` seeds a new database) activate only Bratislava (with its city parts) is
Banská Bystrica, Trnava, Nitra, Malacky and Pezinok and their responsible subjects wait inactive.
`bin/activate-seeded-municipalities` then runs, on the freshly seeded portal and a fresh Triage:

1. a check that Triage is up, that `TRIAGE_ZAMMAD_ADMIN_API_TOKEN` (the local Triage admin's, in `.env.sample`)
   works and that the portal has inactive municipalities. It asks for the token when it doesn't work.
2. `bin/rails municipality_boundaries:download_and_import_municipalities`, the activation finds the municipalities'
   boundaries by it. Then `download_and_import_districts` (city parts from GKÚ ZBGIS), only a
   warning when no district data is found.
3. `bin/rails responsible_subjects:activate_basic EXISTING_MUNICIPALITY=1 NAME=…` for every inactive
   municipality, the way production onboards one ([docs/how-it-works/08](docs/how-it-works/08-onboarding.md)).
   It creates the municipality's group, organization, 700 trigger and users
   (`podatelna@<municipality>.example.com`, `jan.novak@<municipality>.example.com`) in Triage for the volunteer
   `dobrovolnik@example.org`, then activates it.
   A municipality whose [local Backoffice](#local-backoffice) answers becomes PRO instead:
   - Malacky by `bin/rails responsible_subjects:activate_pro EXISTING_MUNICIPALITY=1`.
   - Trnava is activated as BASIC, then upgraded by `bin/rails responsible_subjects:upgrade_to_pro`.
4. full access to every Triage group for `admin@example.org`, so the admin sees and works all tickets too,
   without logging in as the volunteer.
5. a check that each of these Backoffices runs with the portal's ids, `dev/up` again for one that doesn't, see
   [Local Backoffice](#local-backoffice).

New issues in an activated municipality go to the volunteer's group in Triage. The seeded issues stay only in
the portal, the seeds don't send them to Triage.

Click-through:
1. Create an issue in the portal (seeded issues are not in the local Triage).
2. The ticket shows up in Triage (if not, check `/admin/good_job`).
3. Work the ticket in Triage: change the state, add a public comment, change the responsible subject.
4. The issue changes in the portal. Emails from Triage (e.g. to the new responsible subject) are in Mailpit.

### Reset portal and Triage

```bash
bin/ops reset                          # asks first, --yes doesn't
bin/ops reset --backoffices=malacky,trnava    # or none
```

Then `bin/activate-seeded-municipalities` and `bin/dev`. It wipes Triage and every Backoffice with their volumes,
the portal's uploaded files (`storage/`, they belong to the dropped database), logs and `tmp/` (`log:clear
tmp:clear`) and the portal database (`db:reset`), then gets everything ready like a first `bin/ops up`, all at once.
Without `--backoffices` it starts the Backoffices that ran before, Malacky when none did. Stop `bin/dev` first,
`bin/ops` refuses while port 3000 is in use. When Docker runs out of memory, it stops and names the container.

Always reset the portal, Triage and the Backoffices together, with their volumes. The reseeded portal starts its
issue ids at 300300 again, and a Backoffice that kept its tickets refuses a ticket number `OPS-<id>` it already has:
the Connector job then fails in `/admin/good_job` with "Please contact your administrator". A reset also applies a
changed Triage `WEBHOOK_SECRET`, Triage sets it on webhooks only when seeding.

## Local Backoffice

Run Backoffices next to the portal and Triage to click through the PRO flow (a municipality with its own
Backoffice), and with two of them a hand-off from one PRO municipality to another. Clone
[ops-backoffice-saas](https://github.com/slovensko-digital/ops-backoffice-saas) next to this repo
(`../ops-backoffice-saas`).

| What | URL |
|---|---|
| Backoffice of Malacky | http://malacky.localhost:8081, `admin@example.org` / `PASSword123`, emails in Mailpit http://localhost:8026 |
| Backoffice of Trnava (optional) | http://trnava.localhost:8082, `admin@example.org` / `PASSword123`, emails in Mailpit http://localhost:8027 |

Each Backoffice has a host name of its own. Cookies ignore ports, so on the same host name Triage and the
Backoffices log each other out. Chrome and Firefox resolve `*.localhost` without any setup. Triage and two
Backoffices need about 4.5 GB of Docker memory.

`bin/ops up` starts Malacky's Backoffice, `--backoffices=malacky,trnava` both, the list is in
`config/local_backoffices.yml`. Then `bin/activate-seeded-municipalities` makes their municipalities PRO.

A Backoffice starts before the activation, so it gets the portal's ids from `config/local_backoffices.yml`
(`ops-backoffice-saas` `dev/up` writes them to `.env.<instance>`): the responsible subject id, fixed in
`db/seeds/responsible_subjects.rb`, and the tenant id, the `Connector::Tenant` the activation creates. With both
Backoffices it creates Malacky's first, then Trnava's. When it gets another id (e.g. only Trnava runs and gets
tenant 1), it starts the Backoffice again with it. A Backoffice added by `bin/ops up` after the activation stays
unused, its municipality is BASIC: `bin/ops reset --backoffices=malacky,trnava`, then activate.

Who calls whom: the portal calls the Backoffice at `localhost:<port>`. The Backoffice calls the portal at
`host.docker.internal:3000` (`/connector/backoffice/webhook`, responsible subject search).

Click-through:
1. Create an issue in Malacky in the portal.
2. Accept the ticket in Triage (as `admin@example.org` or `dobrovolnik@example.org`), it shows up in the Backoffice of Malacky in group Incoming.
3. In the Backoffice, post a public (not internal) note or change the OPS state, it reaches Triage and the portal.
4. With Trnava: change the responsible subject to Trnava in the Backoffice of Malacky, the ticket shows up in the
   Backoffice of Trnava.
5. Downgrade and upgrade again: `bin/rails responsible_subjects:downgrade_to_basic NAME=Trnava
   USERS=podatelna@trnava.example.com,jan.novak@trnava.example.com`, Triage emails Trnava again (Mailpit). Then
   `upgrade_to_pro` with Trnava's `BACKOFFICE_*` values from `config/local_backoffices.yml`, the Backoffice of Trnava works again.

## Testing

Run `bin/rails test:all`. See [docs/TESTING.md](docs/TESTING.md) for what to test at which level.

## Connect new Backoffice instance

What the connection does is described in [docs/how-it-works/07](docs/how-it-works/07-backoffice-connector.md),
the onboarding in [docs/how-it-works/08](docs/how-it-works/08-onboarding.md). Activate the municipality as PRO, or
upgrade a BASIC one, then deploy the Backoffice with the environment the task prints at the end:

```bash
bin/rails responsible_subjects:activate_pro BOUNDARY_ID=… NAME="Stupava" DISTRICT="Bratislavský kraj" \
  TRIAGE_ZAMMAD_AGENT_EMAIL=… BACKOFFICE_URL=https://stupava.odkazprestarostu.sk/ DRY_RUN=1
bin/rails responsible_subjects:upgrade_to_pro NAME="Malacky" BACKOFFICE_URL=https://malacky.odkazprestarostu.sk/ DRY_RUN=1
```

Run them without arguments for help. They generate `API_TOKEN` and `WEBHOOK_SECRET` unless you pass them.
`upgrade_to_pro` asks to confirm the changes to the Triage setup first. `responsible_subjects:downgrade_to_basic`
goes back to BASIC.
