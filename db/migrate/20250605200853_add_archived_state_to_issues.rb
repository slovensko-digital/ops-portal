class AddArchivedStateToIssues < ActiveRecord::Migration[8.0]
  def change
    add_index :issues_states, :key, unique: true

    add_reference :issues, :archived_state, null: true, foreign_key: { to_table: :issues_states }
    Issues::State.find_or_create_by!(key: 'archived', name: "Archivovaný")
  end
end
