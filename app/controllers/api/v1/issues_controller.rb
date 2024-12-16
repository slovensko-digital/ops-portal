class Api::V1::IssuesController < ApiController
  before_action :authenticate_integration
  before_action :set_issue, only: [ :show ]

  def show
    @issue = @ticket
  end

  private

  def set_issue
    zammad_client = TriageZammadEnvironment.client

    begin
      @ticket = zammad_client.ticket.find(params.require :id)
    rescue
      return head(:not_found)
    end

    head :not_found unless @ticket.responsible_subject == @api_integration.responsible_subject_zammad_identifier
  end
end
