# README

## How it works

[docs/flows/](docs/flows/README.md) maps what users can do and how data syncs between the
portal, Triage and Backoffice: the issue lifecycle, which action triggers what, emails,
scheduled jobs, test coverage per flow, and [known problems](docs/flows/findings.md).
Update the matching file there when you change a flow.

## Install on Mac

Install this before running `bundle`:
- `brew install pkg-config`
- `brew install libexif`
- `brew install vips`


## Local Triage

Run the portal together with a local Triage to click through the whole flow. Clone
[ops-triage-zammad](https://github.com/slovensko-digital/ops-triage-zammad) next to this repo.

| What | URL |
|---|---|
| Portal | http://localhost:3000 (GoodJob: `/admin/good_job`) |
| Triage | http://localhost:8080, `example@example.org` / `PASSword123` |
| Triage emails | http://localhost:8025 (Mailpit), every email Triage sends, e.g. trigger emails to responsible subjects |
| Portal emails | http://localhost:3000/letter_opener |

First time:

```
# Triage, the first start takes a few minutes (zammad-init)
cd ../ops-triage-zammad && docker compose up -d --build

# Portal, the Triage token and webhook secret in .env.sample already match the Triage ones
cd ../ops-portal && cp .env.sample .env
docker compose up -d && bin/setup --skip-server
bin/dev
```

Every day: `docker compose up -d` in `ops-triage-zammad`, `bin/dev` here.

Who calls whom: the portal calls Triage at `localhost:8080`. Triage calls the portal at
`host.docker.internal:3000` (webhooks signed with `WEBHOOK_SECRET`, responsible subject search),
so `bin/dev` has to be running for Triage changes to reach the portal.

Click-through:
1. Create an issue in the portal (seeded issues are not in the local Triage).
2. The ticket shows up in Triage (if not, check `/admin/good_job`).
3. Work the ticket in Triage: change the state, add a public comment, change the responsible subject.
4. The issue changes in the portal. Emails from Triage (e.g. to the new responsible subject) are in Mailpit.

Keep both sides in sync: reset them together. A reset also applies changed `WEBHOOK_SECRET`, Triage sets it on webhooks only when seeding.

```
cd ../ops-triage-zammad && docker compose down -v && docker compose up -d
cd ../ops-portal && bin/rails db:seed:replant
```

To run a Backoffice next to them, see [docs/flows/07](docs/flows/07-backoffice-connector.md#running-it-locally).

## Testing

Run `bin/rails test:all`. See [docs/TESTING.md](docs/TESTING.md) for what to test at which level.

## Connect new Backoffice instance

What the connection does is described in [docs/flows/07](docs/flows/07-backoffice-connector.md).
The snippet below looks up the responsible subject by `name`, which is not set for ones created by
`responsible_subjects:activate_basic` (finding M17 in [docs/flows/findings.md](docs/flows/findings.md)).

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
