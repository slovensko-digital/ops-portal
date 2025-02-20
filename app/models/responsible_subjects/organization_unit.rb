
# == Schema Information
#
# Table name: responsible_subjects_organization_units
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  legacy_id              :integer
#  responsible_subject_id :bigint           not null
#
class ResponsibleSubjects::OrganizationUnit < ApplicationRecord
  belongs_to :responsible_subject
end
