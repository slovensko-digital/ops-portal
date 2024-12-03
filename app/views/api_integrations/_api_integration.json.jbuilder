json.extract! api_integration, :id, :name, :url, :api_token_public_key, :responsible_subject_zammad_identifier, :created_at, :updated_at
json.url api_integration_url(api_integration, format: :json)
