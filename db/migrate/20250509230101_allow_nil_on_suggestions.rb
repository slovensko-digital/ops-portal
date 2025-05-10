class AllowNilOnSuggestions < ActiveRecord::Migration[8.0]
  def change
    change_column_null :issues_drafts, :suggestions, true
    change_column_default :issues_drafts, :suggestions, nil
  end
end
