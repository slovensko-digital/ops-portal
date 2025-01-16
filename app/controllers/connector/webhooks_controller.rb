class Connector::WebhooksController < ActionController::API
  before_action :set_tenant
  before_action :authenticate

  def webhook
    event_type = webhook_params.require :type

    case event_type
    when "issue.created"
      Connector::CreateNewBackofficeIssueFromTriageJob.perform_later(@tenant, data.require(:issue_id))
    when "comment.created"
      Connector::CreateNewBackofficeCommentFromTriageJob.perform_later(@tenant, data.require(:issue_id), data.require(:comment_id))
    when "issue.status_updated"
      Connector::UpdateBackofficeIssueStatusFromTriageJob.perform_later(@tenant, data.require(:issue_id))
    else
      render text: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
    end
  end

  private

  def webhook_params
    params.permit(:type, :timestamp, data: [ :subject_id, :issue_id, :comment_id ])
  end

  def data
    params.require(:data).permit(:subject_id, :issue_id, :comment_id)
  end

  def set_tenant
    @tenant = Connector::Tenant.find_by(api_subject_identifier: data.require(:subject_id))
  end

  def authenticate
    timestamp = request.headers["webhook-timestamp"]
    hook_id = request.headers["webhook-id"]
    signature = request.headers["webhook-signature"]
    render status: :unauthorized, json: nil and return unless signature.present? && hook_id.present? && timestamp.present?

    # TODO: canonicalize/sort json keys to create the same signed hash
    # if signature.starts_with? "v1a,"
    #   key = OpenSSL::PKey::EC.new(@tenant.webhook_public_key)
    #   hash = OpenSSL::Digest.digest("SHA256", "#{hook_id}.#{timestamp}.#{webhook_params.to_json}")
    #   render status: :forbidden, json: nil unless key.verify_raw("SHA256", Base64.decode64(signature&.gsub("v1a,", "")), hash)

    # elsif signature.starts_with "v1,"
    #   key = OpenSSL::PKey::EC.new(@tenant.webhook_public_key)
    #   expected_signature = OpenSSL::HMAC.base64digest("SHA256", @tenant.webhook_public_key, "#{hook_id}.#{timestamp}.#{webhook_params.to_json}")
    #   render status: :forbidden, json: nil unless expected_signature == signature&.gsub("v1,", "")

    # else
    #   render text: "Unrecognized webhook-signature prefix", status: :unprocessable_entity
    # end
  end
end
