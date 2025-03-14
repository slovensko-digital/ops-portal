class Connector::WebhooksController < ActionController::API
  before_action :set_tenant
  before_action :authenticate

  def webhook
    event_type = webhook_params.require :type

    case event_type
    when "issue.created"
      Connector::CreateNewBackofficeIssueFromTriageJob.perform_later(@tenant, data.require(:issue_id))
    when "activity.created"
      Connector::CreateNewBackofficeActivityFromTriageJob.perform_later(@tenant, data.require(:issue_id), data.require(:activity_id))
    when "issue.updated"
      Connector::UpdateBackofficeIssueFromTriageJob.perform_later(@tenant, data.require(:issue_id))
    else
      render text: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
    end
  end

  private

  def webhook_params
    params.permit(:type, :timestamp, data: [ :subject_id, :issue_id, :activity_id ])
  end

  def data
    params.require(:data).permit(:subject_id, :issue_id, :activity_id)
  end

  def set_tenant
    @tenant = Connector::Tenant.find_by(ops_api_subject_identifier: data.require(:subject_id))
  end

  def authenticate
    timestamp = request.headers["webhook-timestamp"]
    hook_id = request.headers["webhook-id"]
    signature = request.headers["webhook-signature"]
    render status: :unauthorized, json: nil and return unless signature.present? && hook_id.present? && timestamp.present?

    data_string = "#{hook_id}.#{timestamp}.#{request.body.read}"

    if signature.starts_with? "v1a,"
      hash = OpenSSL::Digest.digest("SHA256", data_string)
      key = OpenSSL::PKey::EC.new(@tenant.ops_webhook_public_key)
      render status: :forbidden, json: nil unless key.verify_raw("SHA256", Base64.decode64(signature.gsub("v1a,", "")), hash)

    elsif signature.starts_with? "v1,"
      key = @tenant.ops_webhook_public_key
      expected_signature = OpenSSL::HMAC.base64digest("SHA256", key, data_string)
      render status: :forbidden, json: nil unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature.gsub("v1,", ""))

    else
      render status: :unprocessable_entity, json: { message: "Unrecognized webhook-signature prefix" }
    end
  rescue
    render status: :unprocessable_entity, json: nil
  end
end
