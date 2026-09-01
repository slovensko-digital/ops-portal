class AddAiEvaluationToIssuesComments < ActiveRecord::Migration[8.1]
  def change
    add_column :issues_comments, :ai_evaluation, :jsonb, default: {}
  end
end
