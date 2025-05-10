module TurboStreams::RedirectHelper
  def redirect(url)
    turbo_stream_action_tag("redirect", url: url)
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreams::RedirectHelper)
