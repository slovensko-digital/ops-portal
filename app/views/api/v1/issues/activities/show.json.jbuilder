json.triage_identifier @activity[:triage_identifier]
json.activity_type @activity[:article_type]
json.author @activity[:author_response]
json.content_type @activity[:content_type]
json.body @activity[:body]
json.type @activity[:type]
json.customer_activity [ :user_portal_comment, :unknown_user_portal_comment ].include?(@activity[:article_type])
json.created_at @activity[:created_at]
json.updated_at @activity[:updated_at]
json.attachments @activity[:attachments] do |attachment|
  json.triage_identifier attachment[:triage_identifier]
  json.filename attachment[:filename]
  json.content_type attachment[:content_type]
  json.data64 attachment[:data64]
end
