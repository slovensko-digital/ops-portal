# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

webhook_url = ENV.fetch("CONNECTOR_WEBHOOK_URL", "http://localhost:3000/connector/webhook")

# TODO: only run in development
[
  { name: "MÚ Staré Mesto", subject: "1", url: webhook_url },
  { name: "MÚ Karlova Ves", subject: "8", url: webhook_url },
  { name: "Dopravný podnik Bratislava, a.s.", subject: "217", url: webhook_url }
].each do |data|
  client = Client.find_or_create_by!(name: data[:name])
  tenant = Connector::Tenant.find_or_create_by!(name: data[:name])

  api_key = OpenSSL::PKey::EC.generate("prime256v1")
  webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

  client.update_columns(
    api_token_public_key: api_key.public_to_pem,
    webhook_private_key: webhook_key.to_pem,
    url: data[:url],
    responsible_subject_zammad_identifier: data[:subject]
  )

  tenant.update_columns(
    api_token_private_key: api_key.to_pem,
    webhook_public_key: webhook_key.public_to_pem,
    api_subject_identifier: client.id
  )
end
