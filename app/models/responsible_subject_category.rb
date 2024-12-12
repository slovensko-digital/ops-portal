# == Schema Information
#
# Table name: responsible_subject_categories
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  issue_category_id      :bigint           not null
#  responsible_subject_id :bigint           not null
#
class ResponsibleSubjectCategory < ApplicationRecord

end
