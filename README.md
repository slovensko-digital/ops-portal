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
cd ../ops-backoffice-saas && docker compose down -v && docker compose up -d   # with a local Backoffice
cd ../ops-portal && bin/rails db:seed:replant
bin/activate-seeded-municipalities   # once Triage is up
bin/dev
```

## Local Backoffice

Run a Backoffice next to the portal and Triage to click through the PRO flow (a municipality with its own
Backoffice). The seeds connect Malacky to it. Clone
[ops-backoffice-saas](https://github.com/slovensko-digital/ops-backoffice-saas) next to this repo
(`../ops-backoffice-saas`). Two Zammads need about 3 GB of Docker memory.

| What | URL |
|---|---|
| Backoffice | http://127.0.0.1:8081, `example@example.org` / `PASSword123` |
| Backoffice emails | http://localhost:8026 (Mailpit) |

Use `127.0.0.1:8081`, not `localhost:8081`. Cookies ignore ports, so Triage on `localhost:8080`
and Backoffice on `localhost:8081` overwrite each other's session and log each other out.

First time, with [Local Triage](#local-triage) set up:

```bash
# Backoffice, settings come from its .env.sample, no .env needed
cd ../ops-backoffice-saas && docker compose up -d --build
```

Every day: `docker compose up -d` in `ops-backoffice-saas` too.

How Malacky is wired:
- The dev seeds create Malacky's `Client` and `Connector::Tenant`, with the Backoffice URL `localhost:8081` and
  the `API_TOKEN` / `WEBHOOK_SECRET` of the Backoffice `.env.sample`. The seeds reset the id sequences, so Malacky is
  always responsible subject 22 and tenant 1, the Backoffice's `OPS_RESPONSIBLE_SUBJECT_ID` and `WEBHOOK_TENANT_ID`.
- `bin/activate-seeded-municipalities` activates Malacky in Triage like the other municipalities, then makes it PRO.
- The portal calls the Backoffice at `localhost:8081`, the Backoffice calls the portal at `host.docker.internal:3000`
  (`/connector/backoffice/webhook`, responsible subject search).

Click-through:
1. Create an issue in Malacky in the portal.
2. Accept the ticket in Triage as `dobrovolnik@example.org`, it shows up in the Backoffice in group Incoming.
3. In the Backoffice, post a public (not internal) note or change the OPS state, it reaches Triage and the portal.

Malacky also has the Triage user `podatelna@malacky.example.com` with role Externý zodpovedný subjekt, so Triage
emails it about Malacky's tickets as well ([ops#1343](https://github.com/slovensko-digital/ops/issues/1343)).

To reset, wipe the Backoffice together with the portal and Triage, see [Reset portal and Triage](#reset-portal-and-triage).

## Testing

Run `bin/rails test:all`. See [docs/TESTING.md](docs/TESTING.md) for what to test at which level.

## Connect new Backoffice instance

What the connection does is described in [docs/how-it-works/07](docs/how-it-works/07-backoffice-connector.md).
The snippet below looks up the responsible subject by `name`, which is not set for ones created by
`responsible_subjects:activate_basic`. For those, change `find_by!(name:)` to `find_by!(subject_name:)`.

Tip: Use [CyberChef](https://gchq.github.io/CyberChef/#recipe=Pseudo-Random_Number_Generator(32,'Raw')To_Base62('0-9A-Za-z')) to generate secrets.

Example:

```ruby
new_backoffice_data = {
  name: "Malacky",
  url: "https://novy.odkazprestarostu.sk/connector/webhook",
  connector_zammad_url: "https://malacky.odkazprestarostu.sk/",
  receive_customer_activities: false,
  connector_zammad_api_token: "tokenvalue",
  connector_zammad_webhook_secret: "secretvalue"
}

def connect_backoffice(data)
  responsible_subject = ResponsibleSubject.find_by!(name: data[:name])

  raise "ResponsibleSubject already PRO" if responsible_subject.pro?

  responsible_subject.update_columns(
    subject_name: data[:name],
    active: true,
    pro: true
  )

  client = Client.find_or_create_by!(name: data[:name])
  tenant = Connector::Tenant.find_or_create_by!(name: data[:name])

  api_key = OpenSSL::PKey::EC.generate("prime256v1")
  webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

  client.update_columns(
    api_token_public_key: api_key.public_to_pem,
    webhook_private_key: webhook_key.to_pem,
    url: data[:url],
    responsible_subject_id: responsible_subject.id
  )

  tenant.update_columns(
    backoffice_api_token: data[:connector_zammad_api_token],
    backoffice_webhook_secret: data[:connector_zammad_webhook_secret],
    ops_api_token_private_key: api_key.to_pem,
    ops_webhook_public_key: webhook_key.public_to_pem,
    ops_api_subject_identifier: client.id,
    backoffice_url: data[:connector_zammad_url],
    receive_customer_activities: data[:receive_customer_activities]
  )
end

connect_backoffice new_backoffice_data
```
