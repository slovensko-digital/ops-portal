class OvmConnector::Triage::WebhooksController < ActionController::API
  before_action :authenticate
  # before_action :set_issue, only: %i[ ticket_updated ]

  def ticket_created
    puts "Hello!"
    puts params

    ticket_id = params.expect(:ticket_id)
    client = OvmConnector::Triage::TriageZammadEnvironment.client

    ticket = client.ticket.find ticket_id
    article = ticket.articles.first


    tmp_body = {
      state: "new",
      # group: "Bratislava::Karlova ves",
      group: "Sečovce",
      title: ticket.title,
      customer_id: 11,
      triage_id: ticket.id,
      # anonymous: true, TODO: handle anonymous issues - email and name visible to triage zammad, invisible for municipality
      article: {
          internal: false,
          triage_id: 32,
          from: article.from,
          content_type: article.content_type,
          body: article.body,
          attachments: article.attachments
        }
    }

    puts tmp_body

    new_ticket = OvmConnector::Ovm::OvmZammadEnvironment.client.ticket.create(
      tmp_body
    )
  end

  private

  def set_issue
    @issue = Issue.find_by!(triage_external_id: ticket_params[:id])
  end

  def ticket_params
  end

  def authenticate
    sig_header = request.headers["X-Hub-Signature"]&.gsub("sha1=", "")
    render status: :unauthorized, json: nil and return unless sig_header.present?

    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), ENV.fetch("TRIAGE_ZAMMAD_WEBHOOK_SECRET"), request.body.read)
    render status: :forbidden, json: nil if signature != sig_header
  end
end
