module ApiEnvironment
  extend self

  def token_authenticator
    @token_authenticator ||= ApiTokenAuthenticator.new(
      public_key_reader: USER_PUBLIC_KEY_READER
      )
  end

  USER_PUBLIC_KEY_READER = ->(sub) { OpenSSL::PKey::EC.new(Client.find(sub).api_token_public_key) }
end
