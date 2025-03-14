class IssuesController < ApplicationController
  before_action :set_issue, only: %i[ show destroy ]

  # GET /issues or /issues.json
  def index
    @issues = Issue.order(created_at: :desc).limit(2)
  end

  # GET /issues/1 or /issues/1.json
  def show
  end

  # DELETE /issues/1 or /issues/1.json
  def destroy
    @issue.destroy!
    redirect_to issues_path, status: :see_other, notice: "Issue was successfully destroyed."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_issue
    @issue = Issue.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def issue_params
    params.expect(issue: [ :title, :description, :author, :reported_at ])
  end
end
