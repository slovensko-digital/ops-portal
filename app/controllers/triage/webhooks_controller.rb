class Triage::WebhooksController < ActionController::API
  before_action :authenticate

  def portal
    event_type = params.require :type

    case event_type
    when "ticket.updated"
      Triage::SyncTicketUpdateFromTriageJob.perform_later(data.require(:ticket_id))
    when "article.created"
      Triage::CreateNewPortalActivityFromTriageJob.perform_later(data.require(:ticket_id), data.require(:article_id))
    else
      render json: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
    end
  end

  def responsible_subject
    event_type = params.require :type
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

  def common
    event_type = params.require :type
    case event_type
    when "article.updated"
      Triage::UpdatePortalActivityFromTriageJob.perform_later(data.require(:ticket_id), data.require(:article_id))
    when "user.updated"
      Triage::UpdatePortalUserFromTriageJob.perform_later(data.require(:user_id))
    else
      render json: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
    end
  end

  private

  def data
    params.require(:data).permit(:ticket_id, :article_id, :user_id)
  end

  def authenticate
    sig_header = request.headers["X-Hub-Signature"]&.gsub("sha1=", "")
    render status: :unauthorized, json: nil and return unless sig_header.present?

    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV.fetch("TRIAGE_ZAMMAD_WEBHOOK_SECRET"), request.body.read)
    render status: :forbidden, json: nil unless ActiveSupport::SecurityUtils.secure_compare(signature, sig_header)
  end
end
