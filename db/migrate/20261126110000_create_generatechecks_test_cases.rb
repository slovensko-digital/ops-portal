class CreateGeneratechecksTestCases < ActiveRecord::Migration[8.1]
  # Starting test cases for the admin prompt playground, written against the production prompt.
  def up
    load Rails.root.join("db/seeds/ai_prompt_test_cases.rb")
  end

  def down
    # the cases may have been edited in the playground since, keep them
  end
end
