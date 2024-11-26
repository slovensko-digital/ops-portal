class Triage::WebhooksController < ActionController::API
  before_action :authenticate
  before_action :set_target_webhook_client


  def ticket_created
    render :bad_gatway unless @webhook_client.ticket_created(issue_id: params.require(:ticket_id))
  end

  def article_created
    @issue.state = ticket_params[:state]
    render :new, status: :unprocessable_entity unless @issue.save
  end

  def ticket_status_changed
    @issue.state = ticket_params[:state]
    render :new, status: :unprocessable_entity unless @issue.save
  end

  private

  def authenticate
    sig_header = request.headers["X-Hub-Signature"]&.gsub("sha1=", "")
    render status: :unauthorized, json: nil and return unless sig_header.present?

    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV.fetch("TRIAGE_ZAMMAD_WEBHOOK_SECRET"), request.body.read)
    render status: :forbidden, json: nil if signature != sig_header
  end

  def set_target_webhook_client
    municipality_id = params.require(:municipality_id)


  end
end
