class Issues::IssuesUserCommentsController < ApplicationController
  include IssueScoped
  before_action :require_user, only: [ :create, :edit, :update ]
  before_action :check_permissions

  def show
    redirect_to @issue, status: :moved_permanently
  end

  def index
    redirect_to @issue, status: :moved_permanently
  end

  def new
    @comment = if current_user.is_a?(User::Citizen)
      @issue.triage_process? ? Issues::UserPrivateComment.new : Issues::UserComment.new
    elsif current_user.is_a?(User::ResponsibleSubject)
      Issues::ResponsibleSubjectComment.new
    end
  end

  def edit
    @comment = current_user.issues_comments.find(params[:id])
  end

  def update
    @comment = current_user.issues_comments.find(params[:id])
    @comment.assign_attributes(comment_params)
    if @comment.save(context: :edit)
      render @comment
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    if current_user.is_a?(User::ResponsibleSubject)
      @comment = Issues::ResponsibleSubjectComment.new(comment_params)
      @comment.build_activity(issue: @issue, type: Issues::CommentActivity)
      @comment.responsible_subject_author = current_user.responsible_subject
    else
      @comment = @issue.triage_process? ? Issues::UserPrivateComment.new(comment_params) : Issues::UserComment.new(comment_params)
      @comment.build_activity(issue: @issue, type: Issues::CommentActivity)
      @comment.user_author = current_user
    end

    if @comment.save
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
    if @issue.triage_process?
      params.require(:issues_user_private_comment).permit(:text, attachments: [])
    elsif current_user.is_a?(User::Citizen)
      params.require(:issues_user_comment).permit(:text, attachments: [])
    elsif current_user.is_a?(User::ResponsibleSubject)
      params.require(:issues_responsible_subject_comment).permit(:text, attachments: [])
    end
  end

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived? ||
      (current_user.is_a?(User::ResponsibleSubject) && @issue.responsible_subject != current_user.responsible_subject)
  end
end
