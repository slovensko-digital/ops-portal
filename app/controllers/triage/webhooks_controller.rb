class Triage::WebhooksController < ActionController::API
  before_action :authenticate

  def webhook
    event_type = webhook_params.require :type

    case event_type
    when "ticket.created"
      Triage::SendNewIssueFromTriageToBackofficeJob.perform_later(data.require(:ticket_id))
    when "article.created"
      Triage::ProcessNewActivityFromTriageJob.perform_later(data.require(:ticket_id), data.require(:article_id))
    when "ticket.updated"
      Triage::SendNewIssueUpdateFromTriageToBackofficeJob.perform_later(data.require :ticket_id)
    else
      render json: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
    end
  end

  private

  def webhook_params
    params.permit(:type, :timestamp, :data)
  end

  def data
    params.require(:data).permit(:ticket_id, :article_id)
  end

  def authenticate
    sig_header = request.headers["X-Hub-Signature"]&.gsub("sha1=", "")
    render status: :unauthorized, json: nil and return unless sig_header.present?

    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV.fetch("TRIAGE_ZAMMAD_WEBHOOK_SECRET"), request.body.read)
    render status: :forbidden, json: nil unless ActiveSupport::SecurityUtils.secure_compare(signature, sig_header)
  end
end
