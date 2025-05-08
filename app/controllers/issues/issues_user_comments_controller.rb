class Issues::IssuesUserCommentsController < ApplicationController
  include IssueScoped
  before_action :require_user, only: [ :create, :edit, :update ]

  def show
    redirect_to @issue, status: :moved_permanently
  end

  def index
    redirect_to @issue, status: :moved_permanently
  end

  def new
    @comment = Issues::UserComment.new
  end

  def edit
    @comment = current_user.issues_comments.find(params[:id])
    @comment.valid?(:edit)
  end

  def update
    @comment = current_user.issues_comments.find(params[:id])
    @comment.assign_attributes(@comment.type == "Issues::UserPrivateComment" ? private_comment_params : comment_params)
    if @comment.save(context: :edit)
      render @comment
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @comment = @issue.triage_process? ? Issues::UserPrivateComment.new(comment_params) : Issues::UserComment.new(comment_params)
    @comment.build_activity(issue: @issue, type: Issues::CommentActivity)
    @comment.user_author = current_user

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @issue, notice: "Komentár bol pridaný" }
      end
      Issues::SyncUserCommentToTriageJob.set(wait_until: @comment.editing_window_end).perform_later(@comment)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def comment_params
    params.require(:issues_user_comment).permit(:text, attachments: [])
  end

  def private_comment_params
    params.require(:issues_user_private_comment).permit(:text, attachments: [])
  end
end
