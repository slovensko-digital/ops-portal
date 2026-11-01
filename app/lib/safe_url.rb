class SafeUrl
  def self.allowed?(url)
    return false unless url.is_a?(String)

    uri = URI.parse(url.strip)

    return true if uri.is_a?(URI::HTTP) && uri.host.present?

    uri.scheme.nil? && uri.host.nil? && uri.path.start_with?("/")
  rescue URI::InvalidURIError
    false
  end
end
