require "test_helper"

class PraisesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get praises_new_url
    assert_response :success
  end
end
