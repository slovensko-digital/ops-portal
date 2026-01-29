require "test_helper"

class Legacy::RedirectsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect legacy user URL to user page for User::Citizen" do
    citizen = users(:legacy_citizen)

    get "/r/ludia/#{citizen.legacy_id}"

    assert_redirected_to user_path(citizen)
  end

  test "should return 404 when user with legacy_id not found" do
    get "/r/ludia/99999"

    assert_response :not_found
  end
end
