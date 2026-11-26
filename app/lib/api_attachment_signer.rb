# Signs attachment download links handed out by the API, so integrators can fetch
# the file without a token. The signature binds the ids in the path and the expiry.
module ApiAttachmentSigner
  EXPIRES_IN = 3.hours

  module_function

  def url_params(issue_id, activity_id, attachment_id)
    expires = EXPIRES_IN.from_now.to_i
    { expires: expires, signature: signature(issue_id, activity_id, attachment_id, expires) }
  end

  def valid?(issue_id, activity_id, attachment_id, expires:, signature:)
    expires = Integer(expires, exception: false) if expires.is_a?(String)
    return false unless expires.is_a?(Integer) && expires > Time.current.to_i
    return false unless signature.is_a?(String) && signature.present?

    ActiveSupport::SecurityUtils.secure_compare(signature, signature(issue_id, activity_id, attachment_id, expires))
  end

  def signature(issue_id, activity_id, attachment_id, expires)
    OpenSSL::HMAC.hexdigest("SHA256", key, [ issue_id, activity_id, attachment_id, expires ].join("/"))
  end

  def key
    Rails.application.key_generator.generate_key("api attachment urls")
  end
end
