# README

## How it works

[docs/how-it-works/](docs/how-it-works/README.md) maps what users can do and how data syncs between the
portal, Triage and Backoffice: the issue lifecycle, which action triggers what, emails,
scheduled jobs, test coverage per flow, and the open issues that affect each flow.
Update the matching file there when you change a flow.

## Run the portal

Needs Ruby (`.ruby-version`) and Docker (Postgres with PostGIS runs in `docker-compose.yml`).
On a Mac, install this before running `bundle`:

```bash
brew install pkg-config libexif vips
```

First time:

```bash
cp .env.sample .env
docker compose up -d          # Postgres
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
bin/rails db:seed:replant          # empties all tables and seeds again
bin/setup --reset --skip-server    # or drops and recreates the database, e.g. after schema trouble
```

With a local Triage, always reset both together, see [Local Triage](#reset-portal-and-triage).
Resetting only the portal leaves tickets, groups and triggers in Triage for issues and municipalities
the portal no longer has, and `bin/activate-seeded-municipalities` expects a fresh Triage.

## Local Triage

Run the portal together with a local Triage to click through the whole flow. Clone
[ops-triage-zammad](https://github.com/slovensko-digital/ops-triage-zammad) next to this repo
(`../ops-triage-zammad`).

| What | URL |
|---|---|
| Triage | http://localhost:8080, `admin@example.org` / `PASSword123`, volunteer `dobrovolnik@example.org` / `PASSword123` |
| Triage emails | http://localhost:8025 (Mailpit), every email Triage sends, e.g. trigger emails to responsible subjects |

First time:

```bash
# Triage, the first start takes a few minutes (zammad-init)
cd ../ops-triage-zammad && docker compose up -d --build

# Portal, the Triage token and webhook secret in .env.sample already match the Triage ones
cd ../ops-portal && cp .env.sample .env
docker compose up -d && bin/setup --skip-server
bin/activate-seeded-municipalities   # sets up the seeded municipalities in Triage, see below
bin/dev
```

Every day: `docker compose up -d` in `ops-triage-zammad`, `docker compose up -d` and `bin/dev` here.

Who calls whom: the portal calls Triage at `localhost:8080`. Triage calls the portal at
`host.docker.internal:3000` (webhooks signed with `WEBHOOK_SECRET`, responsible subject search),
so `bin/dev` has to be running for Triage changes to reach the portal.

`bin/setup` seeds the portal (`db:prepare` seeds a new database). Only Bratislava (with its city parts) is
seeded active. Banská Bystrica, Trnava, Nitra, Malacky and Pezinok and their responsible subjects are seeded
inactive. `bin/activate-seeded-municipalities` then runs, on the freshly seeded portal and a fresh Triage:

1. a check that Triage is up, that `TRIAGE_ZAMMAD_ADMIN_API_TOKEN` (the local Triage admin's, in `.env.sample`)
   works and that the portal has inactive municipalities. It asks for the token when it doesn't work.
2. `bin/rails municipality_boundaries:import_all`, the activation finds the municipalities' boundaries by it.
3. `bin/rails responsible_subjects:activate_basic EXISTING_MUNICIPALITY=1 NAME=…` for every inactive
   municipality, the way production onboards one ([docs/how-it-works/08](docs/how-it-works/08-onboarding.md)).
   It creates the municipality's group, organization, 700 trigger and users
   (`podatelna@<municipality>.example.com`, `jan.novak@<municipality>.example.com`) in Triage for the volunteer
   `dobrovolnik@example.org`, then activates it.
4. `bin/rails responsible_subjects:activate_pro` for the [local Backoffices](#local-backoffice) you pick, it asks:
   Malacky (yes by default) and Trnava (no by default). Without a terminal it takes the defaults.

New issues in an activated municipality go to the volunteer's group in Triage. The seeded issues stay only in
the portal, the seeds don't send them to Triage.

Click-through:
1. Create an issue in the portal (seeded issues are not in the local Triage).
2. The ticket shows up in Triage (if not, check `/admin/good_job`).
3. Work the ticket in Triage: change the state, add a public comment, change the responsible subject.
4. The issue changes in the portal. Emails from Triage (e.g. to the new responsible subject) are in Mailpit.

### Reset portal and Triage

Stop `bin/dev` first, then wipe Triage (its volumes), reseed the portal and set up the municipalities again.
Wait until Triage answers at http://localhost:8080 before `bin/activate-seeded-municipalities`, the fresh start runs
`zammad-init` again and takes a few minutes. A reset also applies a changed `WEBHOOK_SECRET`, Triage sets
it on webhooks only when seeding.

```bash
cd ../ops-triage-zammad && docker compose down -v && docker compose up -d
cd ../ops-backoffice-saas && dev/compose malacky down -v   # with local Backoffices, also trnava
cd ../ops-portal && bin/rails db:seed:replant
bin/activate-seeded-municipalities   # once Triage is up, then dev/up the Backoffices it prints
bin/dev
```

## Local Backoffice

Run Backoffices next to the portal and Triage to click through the PRO flow (a municipality with its own
Backoffice), and with two of them a hand-off from one PRO municipality to another. Clone
[ops-backoffice-saas](https://github.com/slovensko-digital/ops-backoffice-saas) next to this repo
(`../ops-backoffice-saas`).

| What | URL |
|---|---|
| Backoffice of Malacky | http://malacky.localhost:8081, `example@example.org` / `PASSword123`, emails in Mailpit http://localhost:8026 |
| Backoffice of Trnava (optional) | http://trnava.localhost:8082, `example@example.org` / `PASSword123`, emails in Mailpit http://localhost:8027 |

Each Backoffice has a host name of its own. Cookies ignore ports, so on the same host name Triage and the
Backoffices log each other out. Chrome and Firefox resolve `*.localhost` without any setup. Triage and two
Backoffices need about 4.5 GB of Docker memory.

First time, with [Local Triage](#local-triage) set up: `bin/activate-seeded-municipalities` asks which
municipalities to activate as PRO, runs `responsible_subjects:activate_pro` for them and prints a command per
Backoffice, e.g.:

```bash
cd ../ops-backoffice-saas && dev/up malacky 1 Malacky 22 1 local-dev-malacky-backoffice-api-token-not-a-secret local-dev-malacky-backoffice-webhook-secret-not-a-secret
```

`dev/up` gets the ids and secrets the portal created, so start the Backoffice after the activation. Every day:
`dev/compose malacky up -d` (and `trnava`) in `ops-backoffice-saas`.

Who calls whom: the portal calls the Backoffice at `localhost:<port>`. The Backoffice calls the portal at
`host.docker.internal:3000` (`/connector/backoffice/webhook`, responsible subject search).

Click-through:
1. Create an issue in Malacky in the portal.
2. Accept the ticket in Triage as `dobrovolnik@example.org`, it shows up in the Backoffice of Malacky in group Incoming.
3. In the Backoffice, post a public (not internal) note or change the OPS state, it reaches Triage and the portal.
4. With Trnava: change the responsible subject to Trnava in the Backoffice of Malacky, the ticket shows up in the
   Backoffice of Trnava.

## Testing

Run `bin/rails test:all`. See [docs/TESTING.md](docs/TESTING.md) for what to test at which level.

## Connect new Backoffice instance

What the connection does is described in [docs/how-it-works/07](docs/how-it-works/07-backoffice-connector.md),
the onboarding in [docs/how-it-works/08](docs/how-it-works/08-onboarding.md). Activate the responsible subject as PRO
first, then deploy the Backoffice with the environment the task prints at the end:

```bash
bin/rails responsible_subjects:activate_pro NAME="Malacky" BACKOFFICE_URL=https://malacky.odkazprestarostu.sk/ DRY_RUN=1
```

Run it without arguments for help. It generates `API_TOKEN` and `WEBHOOK_SECRET` unless you pass them. For a
responsible subject activated as BASIC it asks to confirm the changes to its Triage setup first.
