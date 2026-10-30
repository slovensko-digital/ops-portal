require "test_helper"
require "test_helpers/api_helper"

class Api::V1::Issues::Activities::AttachmentsControllerTest < ActionDispatch::IntegrationTest
  include ApiHelper

  DISPOSITION = "inline; filename=\"lavicka.jpg\"; filename*=UTF-8''lavi%C4%8Dka.jpg".freeze

  def signed_url(issue_id = 601, activity_id = 7, id = 501)
    api_v1_issue_activity_attachment_url(issue_id, activity_id, id, **ApiAttachmentSigner.url_params(issue_id, activity_id, id))
  end

  def zammad_serving_attachment
    zammad = Minitest::Mock.new
    zammad.expect :download_attachment, { body: "image-bytes", content_type: "image/jpeg", content_disposition: DISPOSITION }, [ "601", "7", "501" ]
    zammad
  end

  test "a signed link downloads the attachment from triage without a token" do
    zammad = zammad_serving_attachment

    with_zammad_client(zammad) { get signed_url }

    assert_response :success
    assert_mock zammad
    assert_equal "image-bytes", response.body
    assert_equal "image/jpeg", response.media_type
    assert_equal DISPOSITION, response.headers["Content-Disposition"]
  end

  test "a link stays valid for three hours" do
    url = signed_url
    zammad = zammad_serving_attachment

    travel 3.hours - 1.minute do
      with_zammad_client(zammad) { get url }
    end

    assert_response :success
  end

  test "an expired link is forbidden" do
    url = signed_url

    travel 3.hours + 1.second do
      get url
    end

    assert_response :forbidden
    assert_equal({ "message" => "Invalid or expired link" }, response.parsed_body)
  end

  test "a link signed for another attachment is forbidden" do
    get api_v1_issue_activity_attachment_url(601, 7, 502, **ApiAttachmentSigner.url_params(601, 7, 501))

    assert_response :forbidden
  end

  test "a link with a changed expiry is forbidden" do
    params = ApiAttachmentSigner.url_params(601, 7, 501)

    get api_v1_issue_activity_attachment_url(601, 7, 501, **params, expires: params[:expires] + 3600)

    assert_response :forbidden
  end

  test "a link without a valid signature or expiry is forbidden" do
    get api_v1_issue_activity_attachment_url(601, 7, 501)
    assert_response :forbidden

    get api_v1_issue_activity_attachment_url(601, 7, 501, expires: "zajtra", signature: "abc")
    assert_response :forbidden
  end

  test "an attachment triage does not serve is not found" do
    zammad = Minitest::Mock.new
    zammad.expect :download_attachment, nil, [ "601", "7", "501" ]

    with_zammad_client(zammad) { get signed_url }

    assert_response :not_found
  end
end
