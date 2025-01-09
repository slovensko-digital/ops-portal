json.triage_identifier @issue[:triage_identifier]
json.state @issue[:state]
json.title @issue[:title]
json.responsible_subject_identifier @issue[:responsible_subject_identifier]
json.author @issue[:author]
json.created_at @issue[:created_at]
json.updated_at @issue[:updated_at]
json.comments @issue[:comments] do |comment|
  json.triage_identifier comment[:triage_identifier]
  json.author comment[:author]
  json.content_type comment[:content_type]
  json.body comment[:body]
  json.type comment[:type]
  json.created_at comment[:created_at]
  json.updated_at comment[:updated_at]
  json.attachments comment[:attachments] do |attachment|
    json.triage_identifier attachment[:triage_identifier]
    json.filename attachment[:filename]
    json.content_type attachment[:content_type]
    json.data64 attachment[:data64]
  end
end
