json.triage_identifier @issue[:triage_identifier]
json.state @issue[:state]
json.title @issue[:title]
json.responsible_subject_identifier @issue[:responsible_subject_identifier]
json.author @issue[:author]
json.created_at @issue[:created_at]
json.updated_at @issue[:updated_at]
json.activities @issue[:activities] do |activity|
  json.triage_identifier activity[:triage_identifier]
  json.author activity[:author]
  json.content_type activity[:content_type]
  json.body activity[:body]
  json.type activity[:type]
  json.created_at activity[:created_at]
  json.updated_at activity[:updated_at]
  json.attachments activity[:attachments] do |attachment|
    json.triage_identifier attachment[:triage_identifier]
    json.filename attachment[:filename]
    json.content_type attachment[:content_type]
    json.data64 attachment[:data64]
  end
end
