require "test_helper"

class SafeUrlTest < ActiveSupport::TestCase
  test "allows absolute http and https URLs" do
    assert SafeUrl.allowed?("https://example.com/page")
    assert SafeUrl.allowed?("http://example.com/page")
  end

  test "allows root-relative paths used by the checks dictionary" do
    assert SafeUrl.allowed?("/podnet-tykajuci-sa-vyrubu-stromu")
    assert SafeUrl.allowed?("/pravidla-komunikacie")
  end

  test "rejects scriptable and protocol-relative URLs" do
    assert_not SafeUrl.allowed?("javascript:alert(1)")
    assert_not SafeUrl.allowed?("JaVaScRiPt:alert(1)")
    assert_not SafeUrl.allowed?("data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==")
    assert_not SafeUrl.allowed?("//evil.example/phishing")
    assert_not SafeUrl.allowed?("  javascript:alert(1)")
  end

  test "rejects blank and non-string values" do
    assert_not SafeUrl.allowed?(nil)
    assert_not SafeUrl.allowed?("")
    assert_not SafeUrl.allowed?(42)
  end
end
