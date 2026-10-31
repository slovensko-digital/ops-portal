require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    login_user(@user)
  end

  test "show with page range loads the whole range and points the button at the next page" do
    create_issues(50)

    get profile_url(page: "1-2")

    assert_response :success
    assert_select "div#load-more-trigger a.button[href*='page=3']", 1
  end

  test "show with invalid page param falls back to the first page" do
    create_issues(50)

    get profile_url(page: "nonsense")

    assert_response :success
    assert_select "div#load-more-trigger a.button[href*='page=2']", 1
  end

  private

  def login_user(user)
    post "/login", params: { email: user.email, password: "password" }
    follow_redirect!
  end

  def create_issues(count)
    state = Issues::State.find_by(key: "in_progress") || issues_states(:in_progress)

    count.times do |i|
      Issue.create!(
        title: "Profile range test issue #{i}",
        description: "Test description with enough characters to pass validation",
        municipality: Municipality.first,
        state: state,
        category: Issues::Category.first,
        author: @user
      )
    end
  end
end
