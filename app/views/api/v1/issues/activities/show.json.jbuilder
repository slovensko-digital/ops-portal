json.triage_identifier @activity[:triage_identifier]
json.activity_type @activity[:article_type]
json.uuid @activity[:uuid]
json.author @activity[:author_response]
json.content_type @activity[:content_type]
json.body @activity[:body]
json.created_at @activity[:created_at]
json.updated_at @activity[:updated_at]
json.partial! "api/v1/issues/activities/attachments", attachments: @activity[:attachments], issue_id: @ticket[:triage_identifier], activity_id: @activity[:triage_identifier], urls: @attachment_urls
