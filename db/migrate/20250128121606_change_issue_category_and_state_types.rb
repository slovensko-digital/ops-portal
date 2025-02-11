class ChangeIssueCategoryAndStateTypes < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues, :category, :string
    add_reference :issues, :category, null: true, foreign_key: { to_table: 'issues_categories' }

    remove_column :issues, :state, :string
    add_reference :issues, :state, null: true, foreign_key: { to_table: 'issues_states' }
  end
end
