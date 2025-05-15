module ApplicationMailerHelper
  def ops_button(label, url)
    link_to label, url, class: "ops-email-button", target: "_blank"
  end

  def ops_title(title)
    content_tag :p, title, class: "ops-email-title"
  end

  def ops_issue_link(issue)
    content_tag :b, link_to(issue.title, issue_url(issue), class: "ops-email-link", target: "_blank")
  end
end
