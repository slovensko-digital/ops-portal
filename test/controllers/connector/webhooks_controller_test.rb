require "test_helper"

class Connector::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = connector_tenants(:default)
    @webhook_payload = {
      type: "issue.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345"
      }
    }.to_json
    @timestamp = Time.now.to_i.to_s
    @hook_id = "test-id"

    @other_tenant = connector_tenants(:other)
    @asymetric_key = OpenSSL::PKey::EC.generate("prime256v1")
    @other_tenant.update(ops_webhook_public_key: @asymetric_key.public_to_pem)
    @other_tenant.save
  end

  test "webhook should receive 400 without webhook-signature header" do
    post connector_webhook_url
    assert_response :bad_request
  end

  test "webhook should receive 422 with invalid webhook-signature header" do
    post connector_webhook_url,
         params: @webhook_payload,
         headers: {
           "Content-Type" => "application/json",
           "webhook-timestamp" => @timestamp,
           "webhook-id" => @hook_id,
           "webhook-signature" => "invalid_signature"
         }
    assert_response :unprocessable_entity
  end

  test "webhook should receive 204 with valid signature and known tenant" do
    # Generate signature with valid tenant ID
    signature = generate_hmac_signature(@webhook_payload, @tenant.ops_webhook_public_key, @timestamp, @hook_id)

    assert_enqueued_with(job: Connector::CreateNewBackofficeIssueFromTriageJob) do
      post connector_webhook_url,
           params: @webhook_payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => @timestamp,
             "webhook-id" => @hook_id,
             "webhook-signature" => signature
           }

      assert_response :no_content
    end
  end

  test "webhook should handle issue_created event correctly" do
    payload = {
      type: "issue.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345"
      }
    }.to_json

    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)

    assert_enqueued_with(job: Connector::CreateNewBackofficeIssueFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }

      assert_response :no_content
    end
  end

  test "webhook should handle activity_created event correctly" do
    payload = {
      type: "activity.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345",
        activity_id: "67890",
        activity_type: "agent_backoffice_comment"
      }
    }.to_json

    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)

    assert_enqueued_with(job: Connector::CreateNewBackofficeActivityFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }

      assert_response :no_content
    end
  end

  test "webhook should handle status_updated event correctly" do
    payload = {
      type: "issue.updated",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345"
      }
    }.to_json

    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)

    assert_enqueued_with(job: Connector::UpdateBackofficeIssueFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }

      assert_response :no_content
    end
  end

  test "webhook should receive 204 with valid asymmetric signature and known tenant" do
    payload = {
      type: "issue.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @other_tenant.ops_api_subject_identifier,
        issue_id: "12345"
      }
    }.to_json

    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_asymmetric_signature(payload, @asymetric_key, timestamp, hook_id)

    assert_enqueued_with(job: Connector::CreateNewBackofficeIssueFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }

      assert_response :no_content
    end
  end

  test "webhook should reject invalid asymmetric signature" do
    payload = {
      type: "issue.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @other_tenant.ops_api_subject_identifier,
        issue_id: "12345"
      }
    }.to_json

    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"

    post connector_webhook_url,
         params: payload,
         headers: {
           "Content-Type" => "application/json",
           "webhook-timestamp" => timestamp,
           "webhook-id" => hook_id,
           "webhook-signature" => "v1a,#{Base64.strict_encode64('invalid_signature')}"
         }

    assert_response :unprocessable_entity
  end

  test "webhook should reject asymmetric signature with tampered payload" do
    original_payload = {
      type: "issue.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @other_tenant.ops_api_subject_identifier,
        issue_id: "12345"
      }
    }.to_json

    # Create a valid signature for the original payload
    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_asymmetric_signature(original_payload, @asymetric_key, timestamp, hook_id)

    # Modify the payload but keep the original signature
    tampered_payload = {
      type: "issue.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @other_tenant.ops_api_subject_identifier,
        issue_id: "67890" # Changed issue ID
      }
    }.to_json

    post connector_webhook_url,
         params: tampered_payload,
         headers: {
           "Content-Type" => "application/json",
           "webhook-timestamp" => timestamp,
           "webhook-id" => hook_id,
           "webhook-signature" => signature
         }

    assert_response :forbidden
  end

  test "activity.created webhook should not enqueue job if user_portal_comment and tenant.receive_customer_activities? is false" do
    # Ensure the tenant does not want to receive customer activities
    @tenant.update(receive_customer_activities: false)

    # Create a payload with activity_type: "user_portal_comment"
    payload = {
      type: "activity.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345",
        activity_id: "67890",
        activity_type: "user_portal_comment"
      }
    }.to_json
    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)
    assert_no_enqueued_jobs do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }
      assert_response :no_content
    end
  end

  test "activity.created webhook should enqueue job if activity_type is user_portal_comment and tenant.receive_customer_activities? is true" do
    # Ensure the tenant wants to receive customer activities
    @tenant.update(receive_customer_activities: true)

    # Create a payload with activity_type: "user_portal_comment"
    payload = {
      type: "activity.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345",
        activity_id: "67890",
        activity_type: "user_portal_comment"
      }
    }.to_json
    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)
    assert_enqueued_with(job: Connector::CreateNewBackofficeActivityFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }
      assert_response :no_content
    end
  end

  test "activity.created webhook should enqueue job if activity_type: agent_backoffice_comment and tenant.receive_customer_activities? is true" do
    # Ensure the tenant wants to receive customer activities
    @tenant.update(receive_customer_activities: true)

    # Create a payload with activity_type: "agent_backoffice_comment"
    payload = {
      type: "activity.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345",
        activity_id: "67890",
        activity_type: "agent_backoffice_comment"
      }
    }.to_json
    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)
    assert_enqueued_with(job: Connector::CreateNewBackofficeActivityFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }
      assert_response :no_content
    end
  end

  test "activity.created webhook should enqueue job if activity_type: agent_backoffice_comment and tenant.receive_customer_activities? is false" do
    # Ensure the tenant does not want to receive customer activities
    @tenant.update(receive_customer_activities: false)

    # Create a payload with activity_type: "agent_backoffice_comment"
    payload = {
      type: "activity.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345",
        activity_id: "67890",
        activity_type: "agent_backoffice_comment"
      }
    }.to_json
    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)
    assert_enqueued_with(job: Connector::CreateNewBackofficeActivityFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }
      assert_response :no_content
    end
  end

  test "activity.created webhook should enqueue job if activity_type: agent_portal_comment and tenant.receive_customer_activities? is true" do
    # Ensure the tenant wants to receive customer activities
    @tenant.update(receive_customer_activities: true)

    # Create a payload with activity_type: "agent_portal_comment"
    payload = {
      type: "activity.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345",
        activity_id: "67890",
        activity_type: "agent_portal_comment"
      }
    }.to_json
    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)
    assert_enqueued_with(job: Connector::CreateNewBackofficeActivityFromTriageJob) do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }
      assert_response :no_content
    end
  end

  test "activity.created webhook should enqueue no job if activity_type: agent_portal_comment and tenant.receive_customer_activities? is false" do
    # Ensure the tenant does not want to receive customer activities
    @tenant.update(receive_customer_activities: false)

    # Create a payload with activity_type: "agent_portal_comment"
    payload = {
      type: "activity.created",
      data: {
        subject_id: @tenant.ops_api_subject_identifier,
        issue_id: "12345",
        activity_id: "67890",
        activity_type: "agent_portal_comment"
      }
    }.to_json
    timestamp = Time.now.to_i.to_s
    hook_id = "test-id"
    signature = generate_hmac_signature(payload, @tenant.ops_webhook_public_key, timestamp, hook_id)
    assert_no_enqueued_jobs do
      post connector_webhook_url,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "webhook-timestamp" => timestamp,
             "webhook-id" => hook_id,
             "webhook-signature" => signature
           }
      assert_response :no_content
    end
  end

  private

  def generate_hmac_signature(payload, secret, timestamp, hook_id)
    data = "#{hook_id}.#{timestamp}.#{payload}"
    "v1,#{OpenSSL::HMAC.base64digest(OpenSSL::Digest.new('sha256'), secret, data)}"
  end

  def generate_asymmetric_signature(payload, private_key, timestamp, hook_id)
    data = "#{hook_id}.#{timestamp}.#{payload}"
    hash = OpenSSL::Digest.digest("SHA256", data)
    signature = private_key.sign_raw("SHA256", hash)

    "v1a,#{Base64.strict_encode64(signature)}"
  end
end
