json.triage_identifier @issue.id
json.state @issue.state
json.title @issue.title
json.responsible_subject_identifier @issue.responsible_subject
json.author @issue.anonymous ? "anonymous@example.com" : @issue.customer
json.created_at @issue.created_at
json.updated_at @issue.updated_at
json.comments @issue.articles do |article|
  json.triage_identifier article.id
  json.author (@issue.anonymous && article.created_by == @issue.customer) ? "anonymous@example.com" : article.created_by
  json.content_type article.content_type
  json.body article.body
  json.type article.type
  json.created_at article.created_at
  json.updated_at article.updated_at
  json.attachments article.attachments do |attachment|
    json.triage_identifier attachment.id
    json.filename attachment.filename
    json.content_type attachment.preferences.dig(:"Content-Type")
    json.data64 Base64.strict_encode64(attachment.download)
  end
end
