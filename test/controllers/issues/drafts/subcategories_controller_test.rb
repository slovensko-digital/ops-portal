require "test_helper"

class Issues::Drafts::SubcategoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get issues_drafts_subcategories_show_url
    assert_response :success
  end
end
