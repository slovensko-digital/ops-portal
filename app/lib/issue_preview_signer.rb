# Signs read-only preview links for issues that only their author can see
# (in triage, rejected, duplicate, ...). Triage shows the link in the ticket
# sidebar, so volunteers can check how the issue looks on the portal.
#
# The token depends only on the issue id, so the link never expires. Rotating
# ISSUE_PREVIEW_SECRET invalidates every link.
module IssuePreviewSigner
  PARAM = :nahlad
  TOKEN_LENGTH = 20

  module_function

  def url(issue)
    Rails.application.routes.url_helpers.issue_url(issue, PARAM => token(issue))
  end

  def token(issue)
    OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("ISSUE_PREVIEW_SECRET"), issue.id.to_s).first(TOKEN_LENGTH)
  end

  def valid?(issue, token)
    return false unless token.is_a?(String) && token.present?

    ActiveSupport::SecurityUtils.secure_compare(token, token(issue))
  end
end
