json.extract! client, :id, :name, :url, :api_token_public_key, :responsible_subject_zammad_identifier, :created_at, :updated_at
json.url client_url(client, format: :json)
