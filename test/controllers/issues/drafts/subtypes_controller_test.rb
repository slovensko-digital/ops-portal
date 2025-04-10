require "test_helper"

class Issues::Drafts::SubtypesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get issues_drafts_subtypes_show_url
    assert_response :success
  end
end
