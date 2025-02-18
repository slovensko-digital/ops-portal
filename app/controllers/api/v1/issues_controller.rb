class Api::V1::IssuesController < ApiController
  before_action :authenticate_client
  before_action :set_issue, only: [ :show ]

  def show
    @issue = @ticket
  end

  def status
    head :not_found unless @zammad_client.update_ticket_status(params.require(:issue_id), params.require(:status), @client.responsible_subject_zammad_identifier)
  end

  private

  def set_issue
    @ticket = @zammad_client.get_ticket(params.require :id)

    head :not_found unless @ticket
    # TODO
    # head :not_found unless @ticket["responsible_subject"] == @client.responsible_subject_zammad_identifier
  end
end
