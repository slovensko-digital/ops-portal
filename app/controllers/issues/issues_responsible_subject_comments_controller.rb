class Issues::IssuesResponsibleSubjectCommentsController < ApplicationController
  include IssueScoped
  before_action :require_user, only: [ :create, :edit, :update ]
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

  def edit
    @comment = Issues::ResponsibleSubjectComment.find_by!(
      id: params[:id],
      responsible_subject_author: current_user.responsible_subject
    )
  end

  def update
    @comment = Issues::ResponsibleSubjectComment.find_by!(
      id: params[:id],
      responsible_subject_author: current_user.responsible_subject
    )

    @comment.assign_attributes(comment_params)

    if @comment.save(context: :edit)
      render @comment
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @comment = Issues::ResponsibleSubjectComment.new(comment_params)
    @comment.build_activity(issue: @issue, type: Issues::CommentActivity)
    @comment.responsible_subject_author = current_user.responsible_subject

    if @comment.save
      if params[:resolves] == "true"
        @issue.update!(state: Issues::State.find_by!(key: "marked_as_resolved"))
        SyncIssueToTriageJob.perform_later(@issue, sync_activities: false)
      elsif @issue.state == Issues::State.find_by!(key: "sent_to_responsible")
        @issue.update!(state: Issues::State.find_by!(key: "in_progress"))
        SyncIssueToTriageJob.perform_later(@issue, sync_activities: false)
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @issue, notice: "Komentár bol pridaný" }
      end

      Issues::SyncEditableActivityToTriageJob.perform_later(@comment, sync_job: SyncIssueActivityObjectToTriageJob)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def comment_params
    params.require(:issues_responsible_subject_comment).permit(:text, attachments: [])
  end

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived?
  end
end
