class Issues::IssuesResponsibleSubjectChangesController < ApplicationController
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
    @change = Issues::ResponsibleSubjectChange.new
  end

  def create
    @change = Issues::ResponsibleSubjectChange.new(change_params)
    @change.user_author = current_user
    @change.responsible_subject_author = current_user.responsible_subject

    @change.build_activity(issue: @issue, type: Issues::ResponsibleSubjectChangeActivity)

    Issue.transaction do
      if @change.save
        if @change.reassignment?
          @issue.update!(
            responsible_subject: @change.responsible_subject,
            state: Issues::State.find_by!(key: "sent_to_responsible")
          )
        elsif @change.refer?
          @issue.update!(
            state: Issues::State.find_by!(key: "referred")
          )
        end

        respond_to do |format|
          format.turbo_stream
          format.html {
            redirect_to @issue,
                        notice: if @change.reassignment?
                                  "Zodpovedný subjekt bol úspešne zmenený."
                                else
                                  "Podnet bol úspešne odstúpený."
                                end
          }
        end

        SyncIssueToTriageJob.perform_later(@issue, sync_activities: false)
        SyncIssueActivityObjectToTriageJob.perform_later(issue: @issue, activity_object: @change)
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def change_params
    params.require(:issues_responsible_subject_change).permit(:text, :responsible_subject_id, :change_type)
  end

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived? || @issue.resolved?
  end
end
