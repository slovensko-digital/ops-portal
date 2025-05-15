module IssueScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_issue
  end

  private

  def set_issue
    @issue = Issue.find(params[:issue_id])
  end
end
