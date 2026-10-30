require_relative "seeds/categories"
require_relative "seeds/issue_states"

# start after legacy data
last_id = ActiveRecord::Base.connection.select_value("SELECT last_value FROM issues_id_seq")
if last_id < 300000
  ActiveRecord::Base.connection.execute "ALTER SEQUENCE issues_id_seq RESTART WITH 300000;"
end

if Rails.env.development?
  require_relative "seeds/ai_prompts"
  require_relative "seeds/cms_pages"
  require_relative "seeds/districts"
  require_relative "seeds/municipalities"

  # db:seed:replant empties the tables but keeps their id sequences, start them over, so the ids are the same as in a
  # new database. The local Backoffice's .env.sample expects Malacky's responsible subject and tenant ids.
  [ ResponsibleSubject, Client, Connector::Tenant ].each do |model|
    model.connection.reset_pk_sequence!(model.table_name) if model.none?
  end
  require_relative "seeds/responsible_subjects"

  # the local Backoffice of Malacky (ops-backoffice-saas docker compose), its .env.sample has the same API_TOKEN and
  # WEBHOOK_SECRET, the responsible subject's id as OPS_RESPONSIBLE_SUBJECT_ID and the tenant's id as WEBHOOK_TENANT_ID.
  # Malacky is seeded inactive, bin/activate-seeded-municipalities activates it and makes it PRO.
  responsible_subject = ResponsibleSubject.find_by!(subject_name: "Malacky")

  client = Client.find_or_create_by!(name: responsible_subject.subject_name)
  tenant = Connector::Tenant.find_or_create_by!(name: responsible_subject.subject_name)

  api_key = OpenSSL::PKey::EC.generate("prime256v1")
  webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

  client.update_columns(
    api_token_public_key: api_key.public_to_pem,
    webhook_private_key: webhook_key.to_pem,
    url: "http://localhost:3000/connector/webhook",
    responsible_subject_id: responsible_subject.id
  )

  tenant.update_columns(
    backoffice_api_token: "CsnpmnPAlMZCmbaClOoWE7QlFPgCsElVLsfgkJMZQfs",
    backoffice_webhook_secret: "6fvpqr777ryN9FTqkRH2xYGWFXU1W862R6NUyhQOErN",
    ops_api_token_private_key: api_key.to_pem,
    ops_webhook_public_key: webhook_key.public_to_pem,
    ops_api_subject_identifier: client.id,
    backoffice_url: "http://localhost:8081/"
  )

  require_relative "seeds/users"
  require_relative "seeds/issues"
end
