class Issues::IssuesReferralsController < ApplicationController
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
    @referral = Issues::Referral.new
  end

  def create
    @referral = Issues::Referral.new(referral_params)
    @referral.user_author = current_user
    @referral.responsible_subject_author = current_user.responsible_subject

    @referral.build_activity(issue: @issue, type: Issues::ReferralActivity)

    if @referral.change_subject? && @referral.responsible_subject_id == @issue.responsible_subject_id
      @referral.errors.add(:responsible_subject_id, "Musíte vybrať iný zodpovedný subjekt.")
      render :new, status: :unprocessable_entity and return
    end

    Issue.transaction do
      if @referral.save
        if @referral.change_subject?
          @issue.update!(
            responsible_subject: @referral.responsible_subject,
            state: Issues::State.find_by!(key: "sent_to_responsible")
          )
        elsif @referral.refer?
          @issue.update!(
            state: Issues::State.find_by!(key: "referred")
          )
        end

        respond_to do |format|
          format.turbo_stream
          format.html {
            redirect_to @issue,
                        notice: if @referral.change_subject?
                                  "Zodpovedný subjekt bol úspešne zmenený."
                                else
                                  "Podnet bol úspešne odstúpený."
                                end
          }
        end

        SyncIssueToTriageJob.perform_later(@issue, sync_activities: false)
        SyncIssueActivityObjectToTriageJob.perform_later(issue: @issue, activity_object: @referral)
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def referral_params
    params.require(:issues_referral).permit(:text, :responsible_subject_id, :referral_type)
  end

  def check_permissions
    render status: :unauthorized, body: nil if !current_user.can_view?(@issue) || @issue.discussion_closed? || @issue.archived?
  end
end
