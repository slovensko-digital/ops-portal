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
    sig_header = x_hub_signature_header
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV.fetch("WEBHOOK_SECRET"), request.body.read)
    raise ActionController::BadRequest.new("Invalid Signature") unless signature == sig_header
  end

  def x_hub_signature_header
    raise ActionController::ParameterMissing.new("X-Hub-Signature header") unless request.headers["X-Hub-Signature"]
    request.headers["X-Hub-Signature"].gsub("sha1=", "")
  end
end
