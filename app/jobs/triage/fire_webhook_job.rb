class Triage::FireWebhookJob < ApplicationJob
  def perform(client, webhook_id, payload, provider: Faraday)
    private_key = OpenSSL::PKey::EC.new client.webhook_private_key
    attempt_timestamp = Time.now.to_i

    hash = OpenSSL::Digest.digest "SHA256", "#{webhook_id}.#{attempt_timestamp}.#{payload.to_json}"
    signature = private_key.sign_raw "SHA256", hash
    headers = {
      "webhook-id" => webhook_id,
      "webhook-timestamp" => attempt_timestamp.to_s,
      "webhook-signature" => "v1a,#{Base64.strict_encode64 signature}"
    }

    response = provider.post(client.url, payload, headers)
    raise unless response.status == 204
  end
end
