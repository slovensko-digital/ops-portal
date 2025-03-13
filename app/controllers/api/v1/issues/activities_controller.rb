class Api::V1::Issues::ActivitiesController < ApiController
  before_action :authenticate_client
  before_action :set_issue
  before_action :set_activity, only: [ :show ]

  def show
    @activity = @zammad_client.get_article(params.require(:issue_id), params.require(:id))
    head :not_found unless @activity
  end

  def create
    @activity_id = @zammad_client.create_article_from_api!(@client.triage_external_author_identifier, params.require(:issue_id), activity_params)
  end

  private

  def activity_params
    params.require(:activity).permit(:author, :content_type, :body, :type, :created_at, attachments: [ :filename, :content_type, :data64 ])
  end

  def set_issue
    @ticket = @zammad_client.get_ticket(params.require :issue_id)

    head :not_found unless @ticket
    head :not_found unless @ticket[:responsible_subject_identifier] == @client.responsible_subject_zammad_identifier
  end

  def set_activity
    @article = @zammad_client.get_article(params.require(:issue_id), params.require(:id))

    head :not_found unless @article
  end
end
