class AddSuggestionIndexToDrafts < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :picked_suggestion_index, :integer
  end
end
