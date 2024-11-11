class WebhooksController < ActionController::API
  before_action :authenticate
  before_action :set_issue, only: %i[ ticket_updated ]

  def ticket_updated
    @issue.state = ticket_params[:state]
    render :new, status: :unprocessable_entity unless @issue.save
  end

  private

  def set_issue
    @issue = Issue.find_by!(triage_external_id: ticket_params[:id])
  end

  def ticket_params
    params.expect(ticket: [ :id, :state ])
  end

  def authenticate
    sig_header = request.headers["X-Hub-Signature"]&.gsub("sha1=", "")
    render status: :unauthorized, json: nil and return unless sig_header.present?

    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV.fetch("WEBHOOK_SECRET"), request.body.read)
    render status: :forbidden, json: nil if signature != sig_header
  end
end
