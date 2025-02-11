
# == Schema Information
#
# Table name: responsible_subjects_categories
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  issues_category_id     :bigint           not null
#  responsible_subject_id :bigint
#
class ResponsibleSubjects::Category < ApplicationRecord
  belongs_to :responsible_subject, optional: true
  belongs_to :issues_category, class_name: "Issues::Category"
end
