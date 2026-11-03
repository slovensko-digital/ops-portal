# The portal side of a PRO responsible subject's Backoffice shared by ProActivation, ProUpgrade and ProDowngrade: the
# Client (the Backoffice's access to the portal API and the Connector webhook it is sent issues to) and the
# Connector::Tenant (the Connector's access to the Backoffice), see docs/how-it-works/07-backoffice-connector.md.
#
# A downgrade disables both, a later upgrade enables them again with the new Backoffice URL, token and secret, so
# the Tenant keeps its id (the Backoffice's WEBHOOK_TENANT_ID) and its issues.
#
# Expects name, backoffice_url, connector_webhook_url, backoffice_api_token, backoffice_webhook_secret and
# @receive_customer_activities.
module ResponsibleSubjects::BackofficeConnection
  private

  def backoffice_errors(responsible_subject)
    errors = []
    errors << "Responsible subject #{name} already has an active Client" if responsible_subject&.clients&.active&.any?
    tenant = Connector::Tenant.find_by(name: name) if name.present?
    if tenant && tenant != disabled_tenant(responsible_subject)
      errors << "Connector::Tenant #{name} (#{tenant.id}, #{tenant.status}) already exists"
    end

    { "BACKOFFICE_URL" => backoffice_url, "CONNECTOR_WEBHOOK_URL" => connector_webhook_url }.each do |variable, url|
      errors << "#{variable} #{url.inspect} is not an http(s) URL" unless url.match?(%r{\Ahttps?://\S+\z})
    end
    errors << "BACKOFFICE_API_TOKEN is missing" if backoffice_api_token.blank?
    errors << "BACKOFFICE_WEBHOOK_SECRET is missing" if backoffice_webhook_secret.blank?

    errors
  end

  def connect_backoffice_plan(responsible_subject)
    tenant = disabled_tenant(responsible_subject)
    action = tenant ? "enable the disabled Client #{tenant.ops_api_subject_identifier} and Connector::Tenant #{tenant.id}" : "create Client and Connector::Tenant"
    "Portal: #{action} #{name}, Backoffice #{backoffice_url}, webhook #{connector_webhook_url}"
  end

  def connect_backoffice!(responsible_subject)
    tenant = disabled_tenant(responsible_subject)
    if tenant
      client = Client.find(tenant.ops_api_subject_identifier)
      client.update!(active: true, url: connector_webhook_url)
    else
      client = Client.create!(name: name, responsible_subject: responsible_subject)
      tenant = Connector::Tenant.create!(name: name)

      api_key = OpenSSL::PKey::EC.generate("prime256v1")
      webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

      client.update!(api_token_public_key: api_key.public_to_pem, webhook_private_key: webhook_key.to_pem, url: connector_webhook_url)
      tenant.update!(
        ops_api_token_private_key: api_key.to_pem,
        ops_webhook_public_key: webhook_key.public_to_pem,
        ops_api_subject_identifier: client.id
      )
    end

    tenant.update!(
      status: :active,
      backoffice_api_token: backoffice_api_token,
      backoffice_webhook_secret: backoffice_webhook_secret,
      backoffice_url: backoffice_url,
      receive_customer_activities: @receive_customer_activities
    )

    tenant
  end

  def disconnect_backoffice!(responsible_subject)
    responsible_subject.clients.active.find_each do |client|
      client.update!(active: false)
      Connector::Tenant.where(ops_api_subject_identifier: client.id).find_each { _1.update!(status: :inactive) }
    end
  end

  def disabled_tenant(responsible_subject)
    return unless responsible_subject

    Connector::Tenant.inactive.find_by(name: name, ops_api_subject_identifier: responsible_subject.clients.where(active: false).select(:id))
  end
end
