require "test_helper"

# NOTE: These tests require CMS env vars to be set (used by fixtures in test/fixtures/cms/categories.yml).
# Run with: set -a && source .env && set +a && bin/rails test test/controllers/issues/drafts/anonymous_access_test.rb

class Issues::Drafts::AnonymousAccessTest < ActionDispatch::IntegrationTest
  test "anonymous user is redirected to profile creation from all draft step routes" do
    {
      "checks"  => "/dopyty/novy-dopyt/123/checks",
      "geo"     => "/dopyty/novy-dopyt/123/geo",
      "suggestions" => "/dopyty/novy-dopyt/123/suggestions",
      "summary" => "/dopyty/novy-dopyt/123/summary",
      "details" => "/dopyty/novy-dopyt/123/details"
    }.each do |step, path|
      get path
      assert_redirected_to please_create_profile_path, "Expected #{step} to redirect anonymous user"
    end
  end
end
