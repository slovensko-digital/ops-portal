require "test_helper"

class IssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @issue = issues(:two)
  end

  test "should get search index" do
    get issues_url
    assert_response :success
  end

  test "should get search with pin" do
    get issues_url(pin: "48.16430806895233,17.051006812727774")
    assert_response :success
  end

  test "should get stats index" do
    get issues_url(tab: :stats)
    assert_response :success
  end

  test "should filter by indexed array params the same way as by array params" do
    category = @issue.category.name
    municipality = @issue.municipality.name

    get issues_url(kategoria: [ category ], obec: [ municipality ])
    assert_response :success
    expected_body = response.body

    get "/dopyty?kategoria[0]=#{CGI.escape(category)}&obec[0]=#{CGI.escape(municipality)}"
    assert_response :success
    assert_equal expected_body, response.body
    assert_equal [ municipality ], session[:last_municipality]
  end

  test "should ignore filter params of unexpected shape" do
    get "/dopyty?kategoria[foo]=bar&obec[foo]=bar&podkategoria[0][x]=y&q[a]=b"
    assert_response :success
    assert_nil session[:last_municipality]
  end

  test "should show issue" do
    get issue_url(@issue)
    assert_response :success
  end

  test "should not show resolved_private issues" do
    get issue_url(issues(:resolved_private))
    assert_response :not_found
  end

  test "should redirect responsible subject user to responsible subject issues" do
    user = users(:responsible_subject)

    post email_auth_request_path, params: { email: user.email }
    assert_response :redirect

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    key = email.body.encoded.match(/key=([^"&]+)/)[1]

    post "/email-auth", params: { key: key }
    assert_response :redirect
    follow_redirect!

    get relevant_issues_url

    assert_redirected_to issues_url(zodpovedny: user.responsible_subject.subject_name)
  end

  test "should redirect citizen user to municipality issues" do
    user = users(:one)

    post "/login", params: { email: user.email, password: "password" }
    assert_response :redirect

    get relevant_issues_url

    assert_redirected_to issues_url(obec: user.municipality.name)
  end

  test "should redirect anonymous user to all issues" do
    get relevant_issues_url

    assert_redirected_to issues_url
  end
end
