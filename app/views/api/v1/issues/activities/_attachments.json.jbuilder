json.attachments attachments do |attachment|
  json.triage_identifier attachment[:triage_identifier]
  json.filename attachment[:filename]
  json.content_type attachment[:content_type]
  if urls
    json.url api_v1_issue_activity_attachment_url(issue_id, activity_id, attachment[:triage_identifier], **ApiAttachmentSigner.url_params(issue_id, activity_id, attachment[:triage_identifier]))
  else
    json.data64 attachment[:data64]
  end
end
