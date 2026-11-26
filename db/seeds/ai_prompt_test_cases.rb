# Adds the generatechecks test cases from fixtures/ai_prompt_test_cases.yml that are not there yet.
# Also run by the CreateGeneratechecksTestCases data migration, so production gets them on deploy.
YAML.load_file(Rails.root.join("db/seeds/fixtures/ai_prompt_test_cases.yml")).each do |attributes|
  Ai::PromptTestCase.find_or_create_by!(prompt_name: "generatechecks", name: attributes.fetch("name")) do |test_case|
    test_case.assign_attributes(attributes.except("name"))
  end
end
