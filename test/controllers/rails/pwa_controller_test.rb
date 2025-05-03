require "test_helper"

class Rails::PwaControllerTest < ActionDispatch::IntegrationTest
  test "should get manifest" do
    get pwa_manifest_path
    assert_response :success
  end
end
