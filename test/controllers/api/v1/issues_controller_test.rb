require "test_helper"

class Api::V1::IssuesControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get search_api_v1_issues_url, params: { portal_identifier: issues(:one).id }
    assert_response :success
    assert_equal({ id: issues(:one).resolution_external_id }.to_json, response.body)
  end

  test "search should return not found for invalid portal identifier" do
    get search_api_v1_issues_url, params: { portal_identifier: "nonexistent" }
    assert_response :not_found
  end

  test "search should return not found for missing portal identifier" do
    get search_api_v1_issues_url, params: { portal_identifier: nil }
    assert_response :not_found
  end

  test "search should return not found for empty params" do
    get search_api_v1_issues_url
    assert_response :not_found
  end

  test "search should return not found for non-triage process issue" do
    get search_api_v1_issues_url, params: { portal_identifier: issues(:without_triage_external_id).id }
    assert_response :not_found
  end
end
