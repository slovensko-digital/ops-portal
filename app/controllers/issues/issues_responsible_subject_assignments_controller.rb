class Issues::IssuesResponsibleSubjectAssignmentsController < ApplicationController
  include IssueScoped
  before_action :require_user
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
  end

  def create
    @comment = Issues::ResponsibleSubjectComment.new(referral_params[:comment])
    @comment.build_activity(issue: @issue, type: Issues::CommentActivity)
    @comment.responsible_subject_author = current_user.responsible_subject

    new_subject_id = referral_params[:new_responsible_subject_id]

    if new_subject_id.blank? || new_subject_id.to_i == @issue.responsible_subject_id
      @comment.errors.add(:base, "Musíte vybrať iný zodpovedný subjekt.")
      render :new, status: :unprocessable_entity and return
    end

    Issue.transaction do
      if @comment.save
        @issue.update!(
          responsible_subject_id: new_subject_id,
        )

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to @issue, notice: "Zodpovedný subjekt bol úspešne zmenený." }
        end

        SyncIssueToTriageJob.perform_later(@issue)
        Issues::SyncEditableActivityToTriageJob.perform_later(@comment, sync_job: SyncIssueActivityObjectToTriageJob)
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def referral_params
    params.require(:referral).permit(:new_responsible_subject_id, comment: [ :text ])
  end

  def ensure_responsible_subject
    render status: :unauthorized, body: nil unless current_user&.responsible_subject == @issue.responsible_subject
  end

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived?
  end
end
