require "test_helper"

class Legacy::RedirectsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect legacy user URL to user page for User::Citizen" do
    citizen = users(:one)
    citizen.update!(legacy_id: 12345)

    get "/r/ludia/#{citizen.legacy_id}"

    assert_redirected_to user_path(citizen)
  end

  test "should redirect legacy user URL to user page for User::ResponsibleSubject" do
    responsible_subject = users(:responsible_subject)
    responsible_subject.update!(legacy_id: 67890)

    get "/r/ludia/#{responsible_subject.legacy_id}"

    assert_redirected_to user_path(responsible_subject)
  end

  test "should return 404 when user with legacy_id not found" do
    get "/r/ludia/99999"

    assert_response :not_found
  end
end
