class Connector::Backoffice::WebhooksController < ActionController::API
  before_action :authenticate

  def webhook
    event_type = webhook_params.require :type

    case event_type
    when "article.created"
      Connector::SendNewCommentToTriageFromBackofficeJob.perform_later(data.require(:ticket_id), data.require(:article_id))
    when "ticket.status_updated"
      Connector::SendNewIssueStatusToTriageFromBackofficeJob.perform_later(data.require(:ticket_id), data.require(:group))
    else
      render json: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
    end
  end

  private

  def webhook_params
    params.permit(:type, :timestamp, :data)
  end

  def data
    params.require(:data).permit(:ticket_id, :article_id, :group)
  end

  def authenticate
    sig_header = request.headers["X-Hub-Signature"]&.gsub("sha1=", "")
    render status: :unauthorized, json: nil and return unless sig_header.present?

    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV.fetch("CONNECTOR__ZAMMAD_WEBHOOK_SECRET"), request.body.read)
    render status: :forbidden, json: nil if signature != sig_header
  end
end
