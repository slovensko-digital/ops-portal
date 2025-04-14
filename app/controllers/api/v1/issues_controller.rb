class Api::V1::IssuesController < ApiController
  before_action :authenticate_client
  before_action :set_issue, only: [ :show, :update ]

  def show
    @issue = @zammad_client.get_ticket(params.require(:id), customer_articles: params[:include_customer_activities] == "true", expand: true)
  end

  def update
    head :not_found unless @zammad_client.update_ticket!(params.require(:id), issue_params)
    head :ok
  end

  private

  def issue_params
    params.require(:issue).permit(:ops_state, :investment, responsible_subject: [ :label, :value ])
  end

  def set_issue
    @ticket = @zammad_client.get_ticket(params.require :id)

    return head :not_found unless @ticket
    head :not_found unless @ticket[:responsible_subject] == @client.responsible_subject
  end
end
