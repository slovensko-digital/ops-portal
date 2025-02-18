class Api::V1::IssueCommentsController < ApiController
  before_action :set_comment, only: [ :show ]

  def show
    @comment = @article
  end

  def create
    @comment_id = @zammad_client.create_article!(params.require(:issue_id), comment_params)
  end

  private

  def comment_params
    params.require(:comment).permit(:author, :content_type, :body, :type, :created_at, attachments: [ :filename, :content_type, :data64 ])
  end

  def set_comment
    @article = @zammad_client.get_article(params.require(:issue_id), params.require(:id))

    head :not_found unless @article
    # TODO
    # head :not_found unless @ticket["responsible_subject"] == @client.responsible_subject_zammad_identifier
  end
end
