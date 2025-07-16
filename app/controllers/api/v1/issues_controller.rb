class Api::V1::IssuesController < ApiController
  before_action :authenticate_client
  before_action :set_issue, only: [ :show, :update ]

  def show
    allowed_article_types = [ :agent_portal_and_backoffice_comment, :agent_backoffice_comment ]
    allowed_article_types += [ :responsible_subject_portal_and_backoffice_comment ] unless params[:exclude_responsible_subject_articles] == "true"
    allowed_article_types += [ :unknown_user_portal_comment, :user_portal_comment, :agent_portal_comment ] if params[:include_customer_activities] == "true"

    @issue = @zammad_client.get_ticket(
      params.require(:id),
      responsible_subject: @client.responsible_subject,
      allowed_article_types: allowed_article_types,
      expand: params[:expand] != "false"
    )
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
