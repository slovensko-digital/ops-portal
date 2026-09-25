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

  test "should redirect legacy issue URL to issue page" do
    issue = Issue.find_by!(legacy_id: 12345)

    get "/r/bratislava/podnety/#{issue.legacy_id}/nejaky-slug"

    assert_redirected_to issue_path(issue)
  end

  test "should return 404 for legacy issue URL with non-numeric legacy_id" do
    get "/r/presov/podnety/bratislava/podnety/karlova-ves"

    assert_response :not_found
  end

  test "should return 404 for legacy user URL with non-numeric legacy_id" do
    get "/r/ludia/bratislava"

    assert_response :not_found
  end
end
