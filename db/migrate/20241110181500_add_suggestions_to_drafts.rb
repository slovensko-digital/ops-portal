class AddSuggestionsToDrafts < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :suggestions, :jsonb, default: []
  end
end
