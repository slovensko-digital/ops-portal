require "test_helper"

class PraisesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_praise_url
    assert_response :success
  end
end
