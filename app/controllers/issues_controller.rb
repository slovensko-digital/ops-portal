class IssuesController < ApplicationController
  before_action :set_issue, only: %i[ show destroy ]

  # GET /issues or /issues.json
  def index
    @tab = params[:tab].in?(%w[map stats]) ? params[:tab] : "list"

    @issues = search_issues.limit(12)
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

  private
  def search_issues
    scope = Issue
    scope = scope.joins(:category).where(issues_categories: { name: params[:kategoria] }) if params[:kategoria].present?
    scope = scope.joins(:subcategory).where(issues_subcategories: { name: params[:subkategoria] }) if params[:subkategoria].present?
    scope = scope.joins(:subtype).where(issues_subtypes: { name: params[:typ] }) if params[:typ].present?

    scope = scope.order(reported_at: :desc) # TODO
    scope
  end
end
