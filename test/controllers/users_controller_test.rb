require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "show renders load-more trigger with classic pagination" do
    get user_url(users(:one))

    assert_response :success
    assert_select "div#load-more-trigger", 1
    assert_select "div#load-more-trigger nav.pagination", 1
  end

  test "show turbo_stream appends issues and refreshes load-more trigger" do
    get user_url(users(:one), format: :turbo_stream)

    assert_response :success
    assert_select "turbo-stream[action='append'][target='issues-items']", 1
    assert_select "turbo-stream[action='update'][target='load-more-trigger']", 1
  end
end
