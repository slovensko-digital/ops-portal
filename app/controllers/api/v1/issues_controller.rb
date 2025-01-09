class Api::V1::IssuesController < ApiController
  before_action :authenticate_backoffice_client
  before_action :set_issue, only: [ :show ]

  def show
    @issue = @ticket
  end

  private

  def set_issue
    zammad_client = TriageZammadEnvironment.client

    @ticket = zammad_client.get_ticket(params.require :id)
    puts @ticket

    head :not_found unless @ticket
    # head :not_found unless @ticket["responsible_subject"] == @backoffice_client.responsible_subject_zammad_identifier
  end
end
