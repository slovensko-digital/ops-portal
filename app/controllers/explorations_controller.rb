# Serves UX explorations from /explorations (development only, see routes).
class ExplorationsController < ActionController::Base
  ROOT = Rails.root.join("explorations")

  skip_forgery_protection

  Exploration = Data.define(:folder, :started_at, :title, :status, :note)

  def index
    @explorations = ROOT.children.select(&:directory?).sort.reverse.map { |dir| read(dir) }
    render inline: LISTING
  end

  def show
    path = ROOT.join(params[:path]).expand_path
    return head :not_found unless path.to_s.start_with?("#{ROOT}/")

    if path.directory?
      return redirect_to "#{request.path}/" unless request.original_fullpath.end_with?("/")
      path = path.join("index.html")
    end
    return head :not_found unless path.file?

    response.headers["Cache-Control"] = "no-store"
    send_file path, disposition: :inline, type: Rack::Mime.mime_type(path.extname, "text/plain")
  end

  private

  # "PR #102" in a note links to that pull request on GitHub.
  def linked_note(note)
    repo = `git -C #{Rails.root} remote get-url origin`.strip.sub(/\.git\z/, "").sub(/\Agit@github\.com:/, "https://github.com/")
    ERB::Util.html_escape(note).gsub(/PR #(\d+)/) { %(<a href="#{repo}/pull/#{$1}">#{$&}</a>) }.html_safe
  end
  helper_method :linked_note

  def read(dir)
    html = dir.join("index.html").read if dir.join("index.html").file?
    meta = ->(name) { html.to_s[/<meta name="exploration-#{name}" content="([^"]*)"/, 1] }

    Exploration.new(
      folder: dir.basename.to_s,
      started_at: Time.strptime(dir.basename.to_s[0, 14], "%Y%m%d%H%M%S"),
      title: html.to_s[%r{<title>(.*?)</title>}m, 1] || dir.basename.to_s,
      status: meta.call("status") || "open",
      note: meta.call("note")
    )
  end

  LISTING = <<~ERB
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Explorations</title>
      <style>
        @font-face { font-family: "GeneralSans-Variable"; src: url("<%= asset_path("GeneralSans-Variable.woff2") %>") format("woff2"); font-weight: 200 700; }
        body { color: #1c3054; font: 500 16px/1.6 "GeneralSans-Variable", sans-serif; font-variant-numeric: tabular-nums; margin: 40px auto; max-width: 900px; padding: 0 20px; }
        h1 { font-weight: 700; }
        ul { list-style: none; margin: 0; padding: 0; }
        li { align-items: baseline; border-bottom: 1px solid #e3e7ee; display: flex; gap: 24px; justify-content: space-between; padding: 10px 0; }
        a { color: inherit; text-decoration: none; }
        a:hover .title { text-decoration: underline; }
        .time { color: #6b7790; margin-right: 16px; }
        .meta { text-align: right; }
        .note { color: #6b7790; margin-right: 8px; }
        .note a { text-decoration: underline; }
        .status { font-weight: 600; }
        .open { color: #0a6fb8; } .chosen { color: #1a7f37; } .dropped { color: #888; }
      </style>
    </head>
    <body>
      <h1>Explorations</h1>
      <ul>
        <% @explorations.each do |e| %>
          <li>
            <a href="/explorations/<%= e.folder %>/"><span class="time"><%= e.started_at.strftime("%Y-%m-%d %H:%M") %></span><span class="title"><%= e.title %></span></a>
            <span class="meta"><% if e.note.present? %><span class="note"><%= linked_note(e.note) %></span><% end %><span class="status <%= e.status %>"><%= e.status %></span></span>
          </li>
        <% end %>
      </ul>
      <% if @explorations.empty? %><p>No explorations yet.</p><% end %>
    </body>
    </html>
  ERB
end
