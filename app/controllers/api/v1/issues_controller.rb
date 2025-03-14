class Api::V1::IssuesController < ApiController
  before_action :authenticate_client
  before_action :set_issue, only: [ :show, :update ]

  def show
    @issue = @zammad_client.get_ticket(params.require(:id), expand: true)
  end

  def update
    head :not_found unless @zammad_client.update_ticket!(params.require(:issue_id), issue_params)
  end

  private

  def issue_params
    params.require(:issue).permit(:state)
  end

  def set_issue
    @ticket = @zammad_client.get_ticket(params.require :id)

    return head :not_found unless @ticket
    head :not_found unless @ticket[:responsible_subject_identifier]&.to_i == @client.responsible_subject_zammad_identifier.to_i
  end
end
