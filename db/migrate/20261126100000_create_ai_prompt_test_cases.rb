class CreateAiPromptTestCases < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_prompt_test_cases do |t|
      t.string :prompt_name, null: false
      t.string :name, null: false
      t.jsonb :input, null: false, default: {}
      t.string :expected_check_titles, array: true, null: false, default: []
      t.timestamps
    end

    add_index :ai_prompt_test_cases, :prompt_name
  end
end
