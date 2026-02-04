class Issues::IssuesResponsibleSubjectCommentsController < ApplicationController
  include IssueScoped
  before_action :require_user, only: [ :create ]
  before_action :ensure_responsible_subject
  before_action :check_permissions

  def show
    redirect_to @issue, status: :moved_permanently
  end

  def index
    redirect_to @issue, status: :moved_permanently
  end

  def new
    @comment = Issues::ResponsibleSubjectComment.new
    @resolves = params[:resolves]
  end

  def create
    @comment = Issues::ResponsibleSubjectComment.new(comment_params)
    @comment.build_activity(issue: @issue, type: Issues::CommentActivity)
    @comment.responsible_subject_author = current_user.responsible_subject

    if @comment.save
      if params[:resolves] == "true"
        @issue.update!(state: Issues::State.find_by!(key: "resolved"))
        SyncIssueToTriageJob.perform_later(@issue)
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @issue, notice: "Komentár bol pridaný" }
      end
      Issues::SyncActivityToTriageJob.perform_later(@comment, sync_job: SyncIssueActivityObjectToTriageJob)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def comment_params
    params.require(:issues_responsible_subject_comment).permit(:text, attachments: [])
  end

  def ensure_responsible_subject
    render status: :unauthorized, body: nil unless current_user&.responsible_subject == @issue.responsible_subject
  end

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived?
  end
end
