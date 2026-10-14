require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    login_user(@user)
  end

  test "show renders load-more trigger with classic pagination" do
    get profile_url

    assert_response :success
    assert_select "div#load-more-trigger", 1
    assert_select "div#load-more-trigger nav.pagination", 1
  end

  test "show turbo_stream appends issues and refreshes load-more trigger" do
    get profile_url(format: :turbo_stream)

    assert_response :success
    assert_select "turbo-stream[action='append'][target='issues-items']", 1
    assert_select "turbo-stream[action='update'][target='load-more-trigger']", 1
  end

  private

  def login_user(user)
    post "/login", params: {
      email: user.email,
      password: "password"
    }
    follow_redirect!
  end
end
