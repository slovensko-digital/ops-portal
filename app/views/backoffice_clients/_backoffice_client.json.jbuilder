json.extract! backoffice_client, :id, :name, :url, :api_token_public_key, :responsible_subject_zammad_identifier, :created_at, :updated_at
json.url backoffice_client_url(backoffice_client, format: :json)
