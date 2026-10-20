module Issues::Drafts::ChecksHelper
  def check_more_info_url(check)
    url = check["more_info"]
    url if SafeUrl.allowed?(url)
  end
end
