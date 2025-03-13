# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

webhook_url = ENV.fetch "CONNECTOR_WEBHOOK_URL", "http://localhost:3000/connector/webhook"
default_connector_zammad_api_token = ENV.fetch("CONNECTOR__ZAMMAD_API_TOKEN")
default_connector_zammad_webhook_secret = ENV.fetch("CONNECTOR__ZAMMAD_WEBHOOK_SECRET")


# TODO: only run in development
[
  {
    name: "MÚ Staré Mesto",
    subject: "1",
    url: webhook_url,
    triage_user_id: 120,
    connector_zammad_url: "https://staremesto-ba.ops.dev.slovensko.digital/",
    connector_zammad_api_token: default_connector_zammad_api_token,
    connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
  },
  {
    name: "Hlavné mesto SR Bratislava",
    subject: "19",
    url: webhook_url,
    triage_user_id: 121,
    connector_zammad_url: "https://magistrat-ba.ops.dev.slovensko.digital/",
    connector_zammad_api_token: default_connector_zammad_api_token,
    connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
  }
].each do |data|
  client = Client.find_or_create_by!(name: data[:name])
  tenant = Connector::Tenant.find_or_create_by!(name: data[:name])

  api_key = OpenSSL::PKey::EC.generate("prime256v1")
  webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

  client.update_columns(
    api_token_public_key: api_key.public_to_pem,
    webhook_private_key: webhook_key.to_pem,
    url: data[:url],
    responsible_subject_zammad_identifier: data[:subject],
    triage_external_author_identifier: data[:triage_user_id]
  )

  tenant.update_columns(
    backoffice_api_token: data[:connector_zammad_api_token],
    backoffice_webhook_secret: data[:connector_zammad_webhook_secret],
    ops_api_token_private_key: api_key.to_pem,
    ops_webhook_public_key: webhook_key.public_to_pem,
    ops_api_subject_identifier: client.id,
    backoffice_url: data[:connector_zammad_url]
  )
end

[ "Zaslaný zodpovednému", "Odstúpený", "Čakajúci", "Vyriešený", "Neriešený", "V riešení", "Neprijatý", "Uzavretý", "Označený za vyriešený" ].each do |state_name|
  Issues::State.find_or_create_by!(name: state_name)
end

[
  { triage_external_id: 1, name: "Cesty a chodníky", name_hu: "Közutak és közterület", alias: "cesty-a-dopravne-znacenie", description: "cesty, cyklotrasy, schody, oplotenie", description_hu: "utak, kerékpárutak, lépcsők, kerítések", weight: 1000, legacy_id: 16 },
  { triage_external_id: 2, name: "Zeleň a životné prostredie", name_hu: "Zöldterületek", alias: "priroda-a-zivotne-prostredie", description: "stromy, neporiadok, znečisťovanie", description_hu: "fák, rendetlenség, szennyezés", weight: 900, legacy_id: 1 },
  { triage_external_id: 3, name: "Dopravné značenie", name_hu: "Közúti jelzések", alias: "dopravne-znacenie", description: "značky, semafory, stĺpiky", description_hu: "jelzőtáblák, közlekedési lámpák, pollerek", weight: 800, legacy_id: 25 },
  { triage_external_id: 4, name: "Mestský mobiliár", name_hu: "Közterületek berendezései ", alias: "Mestský mobiliár", description: "koše, ihriská, lavičky, zastávky MHD", description_hu: "szemétkosarak, játszóterek, padok, tömegközlekedési megállók", weight: 700, legacy_id: 9 },
  { triage_external_id: 5, name: "Automobily", name_hu: "Gépjármûvek", alias: " Automobily", description: "parkovanie, dlhodobo odstavené vozidlá", description_hu: "parkolás, elhagyott járművek", weight: 600, legacy_id: 184 },
  { triage_external_id: 6, name: "Verejné služby", name_hu: "Közszolgáltatások", alias: "kanalizacia", description: "osvetlenie, kanalizácia, MHD, web, rozvodné siete", description_hu: "közvilágítás, csatornahálózat, városi tömegközlekedés, honlap, közműhálózat", weight: 500, legacy_id: 14 },
  { triage_external_id: 7, name: "Verejný poriadok", name_hu: "Közrend", alias: "verejny-poriadok", description: "stavby, reklama, vandalizmus", description_hu: "építkezések, reklámok, vandalizmus", weight: 400, legacy_id: 21 }
].each do |category|
  cat = Issues::Category.find_or_initialize_by(
    name: category[:name],
    name_hu: category[:name_hu],
    alias: category[:alias],
    description: category[:description],
    description_hu: category[:description_hu],
    weight: category[:weight],
    legacy_id: category[:legacy_id]
  ).tap do |c|
    c.triage_external_id = category[:triage_external_id]
  end

  cat.save!
end
