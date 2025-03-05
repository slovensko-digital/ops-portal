
# == Schema Information
#
# Table name: responsible_subjects_categories
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  issues_category_id     :bigint
#  issues_subcategory_id  :bigint
#  issues_subtype_id      :bigint
#  legacy_id              :integer
#  responsible_subject_id :bigint
#
class ResponsibleSubjects::Category < ApplicationRecord
  belongs_to :responsible_subject, optional: true
  belongs_to :issues_category, class_name: "Issues::Category", optional: true
  belongs_to :issues_subcategory, class_name: "Issues::Subcategory", optional: true
  belongs_to :issues_subtype, class_name: "Issues::Subtype", optional: true
end
