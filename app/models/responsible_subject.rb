# == Schema Information
#
# Table name: responsible_subjects
#
#  id                           :bigint           not null, primary key
#  active                       :boolean
#  code                         :string
#  email                        :string
#  name                         :string
#  pro                          :boolean
#  scope                        :integer
#  subject_name                 :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  district_id                  :bigint
#  municipality_district_id     :bigint
#  municipality_id              :bigint
#  responsible_subjects_type_id :bigint           not null
#
class ResponsibleSubject < ApplicationRecord
  has_many :categories, class_name: "ResponsibleSubjectCategory"
end
