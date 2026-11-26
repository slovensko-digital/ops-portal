class CreateAiPromptSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_prompt_snapshots do |t|
      t.string :prompt_name, null: false
      t.text :content, null: false
      t.string :reason, null: false
      t.string :note
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    add_index :ai_prompt_snapshots, [ :prompt_name, :created_at ]
  end
end
