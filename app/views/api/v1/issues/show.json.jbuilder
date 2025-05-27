json.triage_identifier @issue[:triage_identifier]
json.ops_issue_identifier @issue[:ops_issue_identifier]
json.ops_state @issue[:ops_state].key
json.title @issue[:title]
json.responsible_subject {
  json.label @issue[:responsible_subject]&.subject_name
  json.value @issue[:responsible_subject]&.id
}
json.responsible_subject_changed_at @issue[:responsible_subject_changed_at]
json.author @issue[:author_response]
json.issue_type @issue[:issue_type]
json.category @issue[:category].name
json.subcategory @issue[:subcategory]&.name
json.subtype @issue[:subtype]&.name
json.address_municipality @issue.values_at(:municipality, :municipality_district).compact.pluck(:name).join("::")
json.address_postcode @issue[:address_postcode]
json.address_street @issue[:address_street]
json.address_house_number @issue[:address_house_number]
json.likes_count @issue[:likes_count]
json.address_lat @issue[:address_lat]
json.address_lon @issue[:address_lon]
json.portal_url @issue[:portal_url]
json.created_at @issue[:created_at]
json.updated_at @issue[:updated_at]
json.activities @issue[:activities] do |activity|
  json.triage_identifier activity[:triage_identifier]
  json.activity_type activity[:article_type]
  json.uuid activity[:uuid]
  json.author activity[:author_response]
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
