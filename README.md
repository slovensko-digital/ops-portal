# Odkaz pre starostu

The citizen portal of [Odkaz pre starostu](https://novy.odkazprestarostu.sk), a Rails app on PostgreSQL with
PostGIS. Issues reported here are worked by volunteers in Triage and by municipalities in their own Backoffice, both
Zammad.

## How it works

[docs/how-it-works/](docs/how-it-works/README.md) maps what users can do and how data syncs between the
portal, Triage and Backoffice: the issue lifecycle, which action triggers what, emails,
scheduled jobs, test coverage per flow, and the open issues that affect each flow.
Update the matching file there when you change a flow.

## Prerequisites

Tested on macOS and Linux.

1. **Ruby** through a version manager: mise (the [Installing Ruby on Rails](https://guides.rubyonrails.org/install_ruby_on_rails.html)
   guide sets it up), asdf or rbenv. The repo pins the version in `.ruby-version` and `.tool-versions`, don't
   install Ruby or Rails by hand.
2. **System libraries**, including the PostgreSQL client: `db:prepare` loads `db/structure.sql` with `psql`.

   ```bash
   # macOS, with Homebrew (https://brew.sh)
   brew install pkg-config libexif vips libpq && brew link --force libpq

   # Ubuntu, Debian
   sudo apt install pkg-config libexif-dev libvips libpq-dev postgresql-client libcurl4-openssl-dev tzdata
   ```

3. **[Docker](https://docs.docker.com/get-started/get-docker/)**, `docker compose up -d` starts PostgreSQL 17 with
   PostGIS 3.6 from `docker-compose.yml`.

   <details>
   <summary>Use your own PostgreSQL instead of Docker</summary>

   It has to be PostgreSQL 17 with PostGIS 3.6, e.g. Postgres.app, on port 5432. Create the role from
   `DATABASE_URL` in `.env`, it has to be a superuser to create the PostGIS extension:

   ```bash
   # macOS (Homebrew, Postgres.app)
   psql postgres -c "CREATE ROLE ops LOGIN SUPERUSER PASSWORD 'ops';"
   # Linux
   sudo -u postgres psql -c "CREATE ROLE ops LOGIN SUPERUSER PASSWORD 'ops';"
   ```

   Then skip `docker compose up -d`. A Postgres listening on port 5432 takes it first, the portal then uses it, and
   `bin/ops` leaves the Docker one off.

   </details>

## Run only the portal

To work on the portal itself, e.g. the frontend, without Triage and the Backoffices:

1. Clone the repo and install Ruby:

   ```bash
   git clone https://github.com/slovensko-digital/ops-portal.git && cd ops-portal
   mise install   # or asdf install, rbenv install; check with ruby -v
   ```

2. Copy the local settings:

   ```bash
   cp .env.sample .env
   ```

3. Start Postgres:

   ```bash
   docker compose up -d
   ```

4. Install the gems, create and seed the database:

   ```bash
   bin/setup --skip-server
   ```

5. Import the municipality boundaries, the new issue wizard finds the municipality by them. It downloads them from
   ZBGIS once (to `tmp/`), it takes a few minutes:

   ```bash
   bin/rails municipality_boundaries:download_and_import_municipalities
   ```

6. Start the portal (Rails server and the Sass watcher, `Procfile.dev`) on http://localhost:3000:

   ```bash
   bin/dev
   ```

Log in as a [seeded user](#seeded-data), emails are at http://localhost:3000/letter_opener. Every day:
`docker compose up -d`, then `bin/dev`. `bin/setup --reset --skip-server` wipes the database and seeds it again,
import the boundaries again after it.

What doesn't work without the rest of the stack, and in both setups:

- New issues can be reported only in Bratislava, the only municipality the seeds activate. Nothing reaches Triage:
  the jobs that send issues there fail in http://localhost:3000/admin/good_job. To work on a flow between the
  portal, Triage and a Backoffice, run the whole stack instead.
- The new issue wizard's suggestions and checks need `GEMINI_API_KEY` and `CMS_AI_CATEGORY_ID` in `.env`, set before
  seeding: the seeds create the AI prompts under that category.
- Google and Facebook login need `GOOGLE_*` and `FACEBOOK_*`.

## Run the stack locally

The portal, a local Triage and local Backoffices, to click through the whole flow:

1. Install the [prerequisites](#prerequisites). Docker is needed here even with your own PostgreSQL, Triage and the
   Backoffices run in it. Give it about 4.5 GB of memory (about 1.5 GB per Zammad: Triage and two Backoffices).

2. Clone [ops-triage-zammad](https://github.com/slovensko-digital/ops-triage-zammad) and
   [ops-backoffice-saas](https://github.com/slovensko-digital/ops-backoffice-saas) next to this repo:

   ```bash
   cd .. && git clone https://github.com/slovensko-digital/ops-triage-zammad.git \
     && git clone https://github.com/slovensko-digital/ops-backoffice-saas.git && cd ops-portal
   ```

3. Install the gems:

   ```bash
   bundle install
   ```

4. Start the stack. It copies `.env` from `.env.sample`, starts Postgres, creates and seeds the database, starts
   Triage and Malacky's Backoffice and waits until they answer. The first start takes a few minutes.

   ```bash
   bin/ops up
   ```

5. Set up the seeded municipalities in the fresh Triage, see [Seeded data](#seeded-data):

   ```bash
   bin/activate-seeded-municipalities
   ```

6. Start the portal (Rails server and the Sass watcher, `Procfile.dev`) and open http://localhost:3000,
   see [Local URLs](#local-urls):

   ```bash
   bin/dev
   ```

Every day: `bin/ops up`, then `bin/dev`.

`bin/ops` starts the Docker Postgres unless your own server answers on its port.

## bin/ops commands

`bin/ops` starts, stops and resets the local stack: the portal's Postgres and database, Triage and the Backoffices.
It never starts the portal itself, that is `bin/dev`. Run it without arguments to see its commands:

```
$ bin/ops
Commands:
  bin/ops up [--backoffices=LIST] [--build]   # Start Postgres, Triage and the Backoffices, prepare the database
  bin/ops down                                # Stop them all, keep the data
  bin/ops status                              # Show what runs, its URLs and Docker memory
  bin/ops reset [--backoffices=LIST] [--yes]  # Wipe them all and the portal's data, then start them like a first up
  bin/ops logs TARGET [SERVICE]               # Follow the logs of portal, postgres, triage or a Backoffice

Then bin/activate-seeded-municipalities on a fresh Triage, and bin/dev.

Without --backoffices, up and reset start the Backoffices set up before, running or stopped, Malacky when there are
none. reset always wipes every Backoffice, then starts only these.

Options:
        --backoffices=LIST           up, reset: Backoffices to start, e.g. malacky,trnava or none
        --build                      up: rebuild the Zammad images
        --yes                        reset: don't ask
```

`up` and `reset` start the Backoffices in `--backoffices` (`none`: only Triage). Without it they start the ones set
up before, running or stopped (each has a `.env.<instance>` in `../ops-backoffice-saas`), Malacky when there are
none. So after `up --backoffices=none` a plain `reset` starts the stopped Backoffices again. The list of Backoffices
is in `config/local_backoffices.yml`.

`bin/ops` only touches the compose projects `ops-triage-zammad`, `ops-backoffice-<instance>` and the container
`ops-postgres`, other projects (e.g. `ops-triage-e2e`) keep running. The worktrees of this repo share its ports and
Postgres, run `bin/ops` and `bin/dev` in one of them at a time.

### up

Gets the stack ready, also on a fresh clone: Postgres, `db:prepare` (creates and seeds a new database, migrates an
existing one), Triage and the Backoffices, all at once, then waits until each Zammad answers. It stops the
Backoffices that are not picked, they keep their data. `--build` rebuilds the Zammad images after a pull in
`ops-triage-zammad` or `ops-backoffice-saas`.

```bash
bin/ops up
bin/ops up --backoffices=malacky,trnava
bin/ops up --backoffices=none
bin/ops up --build
```

With `--backoffices=none` the PRO municipalities stay PRO in the portal, their issues' Connector jobs fail in
`/admin/good_job` until their Backoffice runs. Use the other municipalities, or `bin/ops reset --backoffices=none`
and `bin/activate-seeded-municipalities` to have all of them BASIC. A Backoffice added by `up` after the activation
stays unused, its municipality is BASIC: `bin/ops reset --backoffices=malacky,trnava`, then activate.

### down

Stops Triage, the Backoffices and the Docker Postgres, the data stays. Stop `bin/dev` with Ctrl-C.

```bash
bin/ops down
```

### status

Shows what runs, its URLs and how much Docker memory it uses.

```
$ bin/ops status
Portal              stopped (bin/dev)  http://localhost:3000
Postgres            running            localhost:5432                                                0.1 GB
Triage              ready              http://localhost:8080, Mailpit http://localhost:8025          1.2 GB
Backoffice malacky  ready              http://malacky.localhost:8081, Mailpit http://localhost:8026  1.1 GB
Backoffice trnava   ready              http://trnava.localhost:8082, Mailpit http://localhost:8027   1.1 GB

Docker memory: 3.6 GB used of 8.2 GB (about 1.5 GB per Zammad)
```

### reset

Wipes Triage and every Backoffice with their volumes, the portal's uploaded files (`storage/`), logs, `tmp/` and the
portal database (`db:reset`), then gets everything ready like a first `up`. It asks first, `--yes` doesn't. Stop
`bin/dev` first, `bin/ops` refuses while port 3000 is in use. Then run `bin/activate-seeded-municipalities` and
`bin/dev`.

It always wipes every Backoffice, also the ones it doesn't start again. Without `--backoffices` it starts again
the ones set up before, e.g. both after `up --backoffices=malacky,trnava`. `--backoffices` changes which ones, for
the activation that follows: `malacky,trnava` makes both municipalities PRO, `none` makes all of them BASIC. A
Backoffice left out is not set up any more (its `.env.<instance>` is removed), the next `up` and `reset` don't start
it.

```bash
bin/ops reset                                  # the Backoffices set up before
bin/ops reset --backoffices=malacky,trnava     # both, Malacky and Trnava become PRO
bin/ops reset --backoffices=none               # no Backoffice, every municipality becomes BASIC
bin/ops reset --yes                            # don't ask
```

Always reset the portal, Triage and the Backoffices together, with their volumes. Resetting only the portal leaves
tickets, groups and triggers in Triage for issues and municipalities the portal no longer has. The reseeded portal
starts its issue ids at 300300 again, and a Backoffice that kept its tickets refuses a ticket number `OPS-<id>` it
already has: the Connector job then fails in `/admin/good_job` with "Please contact your administrator". A reset
also applies a changed Triage `WEBHOOK_SECRET`, Triage sets it on webhooks only when seeding.

Portal only, without Triage: `rm -rf storage/[!.]* && bin/rails db:reset`, with `bin/dev` and consoles stopped.

### logs

Follows the logs of the portal (`log/development.log`), Postgres, Triage or a Backoffice, optionally of one compose
service.

```bash
bin/ops logs portal
bin/ops logs triage zammad-railsserver
bin/ops logs malacky
```

## Local URLs

| What | URL | Login |
|---|---|---|
| Portal | http://localhost:3000 | [seeded users](#seeded-data) |
| Portal jobs | http://localhost:3000/admin/good_job | |
| Portal emails | http://localhost:3000/letter_opener | |
| Triage | http://localhost:8080 | `admin@example.org` or volunteer `dobrovolnik@example.org`, `PASSword123` |
| Triage emails (Mailpit) | http://localhost:8025 | |
| Backoffice of Malacky | http://malacky.localhost:8081 | `admin@example.org` / `PASSword123` |
| Backoffice of Malacky emails (Mailpit) | http://localhost:8026 | |
| Backoffice of Trnava (`--backoffices=malacky,trnava`) | http://trnava.localhost:8082 | `admin@example.org` / `PASSword123` |
| Backoffice of Trnava emails (Mailpit) | http://localhost:8027 | |

Each Backoffice has a host name of its own. Cookies ignore ports, so on the same host name Triage and the
Backoffices log each other out. Chrome and Firefox resolve `*.localhost` without any setup.

Who calls whom: the portal calls Triage at `localhost:8080` and a Backoffice at `localhost:<port>`. Triage and the
Backoffices call the portal at `host.docker.internal:3000` (webhooks signed with `WEBHOOK_SECRET`,
`/connector/backoffice/webhook`, responsible subject search), so `bin/dev` has to be running for their changes to
reach the portal.

## Seeded data

After `bin/activate-seeded-municipalities`:

| Municipality | Responsible subject | In Triage |
|---|---|---|
| Banská Bystrica, Nitra, Pezinok | BASIC | group and 700 trigger of the volunteer `dobrovolnik@example.org`, organization with `podatelna@<municipality>.example.com` and `jan.novak@<municipality>.example.com` |
| Malacky | PRO when its Backoffice runs, otherwise BASIC | group and 700 trigger, no organization when PRO |
| Trnava | PRO with `--backoffices=malacky,trnava` (activated BASIC, then upgraded), otherwise BASIC | group and 700 trigger, no organization when PRO |
| Bratislava and its city parts | BASIC, seeded active | nothing, `activate_basic` doesn't support city parts yet |

New issues in an activated municipality go to the volunteer's group in Triage. The seeded issues stay only in the
portal, the seeds don't send them to Triage.

Portal users, all with the password `password`: `admin@example.com`, `jana@example.com`, `peter@example.com`,
`anonym@example.com`, `novy@example.com` (phone not verified), `citizen1@example.com` … `citizen20@example.com` and
the responsible subject's `stare-mesto@example.com`. Set `DEFAULT_USER_EMAIL` in `.env` to seed a verified account
with your own email too.

## Responsible subject activation

A municipality joins as BASIC or PRO. BASIC works its tickets through Triage's emails, PRO in a Backoffice of its
own. What each task changes is in [docs/how-it-works/08](docs/how-it-works/08-onboarding.md), the Backoffice
connection in [docs/how-it-works/07](docs/how-it-works/07-backoffice-connector.md).

```
$ bin/rails -T responsible_subjects
bin/rails responsible_subjects:activate_basic      # Activate a new BASIC municipality in the portal and Triage
bin/rails responsible_subjects:activate_pro        # Activate a new PRO municipality with its own Backoffice
bin/rails responsible_subjects:downgrade_to_basic  # Downgrade a PRO responsible subject to BASIC
bin/rails responsible_subjects:upgrade_to_pro      # Upgrade a BASIC responsible subject to PRO with its own Backoffice
```

Run a task without arguments for its help. Every task needs `TRIAGE_ZAMMAD_ADMIN_API_TOKEN`, a Triage admin's token
(deployed apps get it as a Kamal secret, `.env.sample` has the local Triage's). Each validates everything first and
changes nothing when something is wrong, `DRY_RUN=1` stops after the validation. Triage changes cannot be rolled
back: when a step fails, the steps printed before it are done.

### BASIC

`activate_basic` creates the municipality and its responsible subject in the portal, and in Triage the volunteer's
group, the 700 trigger and the municipality's organization with its users, then activates it. Triage emails the
municipality's users about its tickets.

```bash
bin/rails responsible_subjects:activate_basic BOUNDARY_ID=1273 NAME="Nižná" DISTRICT="Žilinský kraj" \
  USERS="podatelna@nizna.sk, starosta@nizna.sk" TRIAGE_ZAMMAD_AGENT_EMAIL=… DRY_RUN=1
```

### PRO

`activate_pro` creates the same without the organization and users, plus the Backoffice's `Client` and
`Connector::Tenant`. `upgrade_to_pro` makes an active BASIC one PRO and deletes its Triage organization.
`downgrade_to_basic` goes back: it creates the organization again and disables the Backoffice's `Client` and
`Connector::Tenant`, a later `upgrade_to_pro` enables them again. Both ask to confirm, `YES=1` doesn't.

```bash
bin/rails responsible_subjects:activate_pro BOUNDARY_ID=… NAME="Stupava" DISTRICT="Bratislavský kraj" \
  TRIAGE_ZAMMAD_AGENT_EMAIL=… BACKOFFICE_URL=https://stupava.odkazprestarostu.sk/ DRY_RUN=1
bin/rails responsible_subjects:upgrade_to_pro NAME="Malacky" BACKOFFICE_URL=https://malacky.odkazprestarostu.sk/ DRY_RUN=1
bin/rails responsible_subjects:downgrade_to_basic NAME="Malacky" USERS="podatelna@malacky.sk, jan.novak@malacky.sk"
```

`activate_pro` and `upgrade_to_pro` generate the Backoffice's `API_TOKEN` and `WEBHOOK_SECRET` unless you pass
`BACKOFFICE_API_TOKEN` and `BACKOFFICE_WEBHOOK_SECRET`, and print the environment to deploy the Backoffice with at
the end. After `downgrade_to_basic`, stop the Backoffice, the portal no longer accepts it.

## Testing

Create the test database once with `RAILS_ENV=test bin/rails db:prepare`, then run `bin/rails test:all` (system
tests need Chrome). `bin/ci` runs everything CI runs. See [docs/TESTING.md](docs/TESTING.md) for what to test at which
level.

### Click through the flow

A manual end-to-end check across the portal, Triage and the Backoffices, with the stack running.

Triage:
1. Create an issue in an activated municipality, e.g. Nitra (seeded issues are not in the local Triage).
2. The ticket shows up in Triage (if not, check `/admin/good_job`).
3. Work the ticket in Triage: change the state, add a public comment, change the responsible subject.
4. The issue changes in the portal. Emails from Triage (e.g. to the new responsible subject) are in Mailpit.

Backoffice (a PRO municipality), and with Trnava a hand-off from one PRO municipality to another:
1. Create an issue in Malacky in the portal.
2. Accept the ticket in Triage (as `admin@example.org` or `dobrovolnik@example.org`), it shows up in the Backoffice
   of Malacky in group Incoming.
3. In the Backoffice, post a public (not internal) note or change the OPS state, it reaches Triage and the portal.
4. With Trnava: change the responsible subject to Trnava in the Backoffice of Malacky, the ticket shows up in the
   Backoffice of Trnava.
5. Downgrade and upgrade again: `bin/rails responsible_subjects:downgrade_to_basic NAME=Trnava
   USERS=podatelna@trnava.example.com,jan.novak@trnava.example.com`, Triage emails Trnava again (Mailpit). Then
   `upgrade_to_pro` with Trnava's `BACKOFFICE_*` values from `config/local_backoffices.yml`, the Backoffice of
   Trnava works again.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `role "ops" does not exist`, `password authentication failed for user "ops"`, `extension "postgis" is not available`, or port 5432 already allocated | Another Postgres has port 5432, the portal reaches it instead of the Docker one. Stop it, or set it up as your own server ("Use your own PostgreSQL" in [Prerequisites](#prerequisites)). |
| `unrecognized configuration parameter "transaction_timeout"` | Your Postgres is older than 17. Use the Docker one or upgrade. |
| `failed to execute: psql` | Install the PostgreSQL client, see [Prerequisites](#prerequisites). |
| `docker compose`: `permission denied` (Linux) | `sudo usermod -aG docker $USER`, then log out and in. |
| `bin/rails db:test:prepare` drops the development database | Use `RAILS_ENV=test bin/rails db:prepare`. `db:test:prepare` reads `DATABASE_URL` from `.env`, which names the development database. |
| The new issue wizard says "Samospráva nie je zatiaľ zapojená do portálu Odkaz pre starostu" | The municipality boundaries are missing (step 5 of [Run only the portal](#run-only-the-portal)), or the place is outside an active municipality. |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Only maintainers can push to this repo, open pull requests from a fork.
