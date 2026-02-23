class Issues::IssuesResponsibleSubjectReferralsController < ApplicationController
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

    assignment_type = referral_params[:referral_type]
    new_subject_id = referral_params[:new_responsible_subject_id]

    if assignment_type == "change_subject"
      if new_subject_id.blank? || new_subject_id.to_i == @issue.responsible_subject_id
        @comment.errors.add(:new_responsible_subject_id, "Musíte vybrať iný zodpovedný subjekt.")
        render :new, status: :unprocessable_entity and return
      end
    end

    unless %w[change_subject refer].include?(assignment_type)
      @comment.errors.add(:referral_type, "Neplatný typ akcie.")
      render :new, status: :unprocessable_entity and return
    end

    Issue.transaction do
      if @comment.save
        if assignment_type == "change_subject"
          @issue.update!(
            responsible_subject_id: new_subject_id,
          )
        elsif assignment_type == "refer"
          @issue.update!(
            state: Issues::State.find_by!(key: "referred")
          )
        end

        respond_to do |format|
          format.turbo_stream
          format.html {
            redirect_to @issue,
                        notice: if assignment_type == "change_subject"
                                  "Zodpovedný subjekt bol úspešne zmenený."
                                else
                                  "Podnet bol úspešne odstúpený."
                                end
          }
        end

        SyncIssueToTriageJob.perform_later(@issue, sync_activities: false)
        Issues::SyncActivityToTriageJob.perform_later(@comment, sync_job: SyncIssueActivityObjectToTriageJob)
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def referral_params
    params.require(:issues_responsible_subject_referral).permit(:new_responsible_subject_id, :referral_type, comment: [ :text, attachments: [] ])
  end

  def ensure_responsible_subject
    render status: :unauthorized, body: nil unless current_user&.responsible_subject == @issue.responsible_subject
  end

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived?
  end
end
