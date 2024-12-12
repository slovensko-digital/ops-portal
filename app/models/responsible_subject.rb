# == Schema Information
#
# Table name: responsible_subjects
#
#  id                          :bigint           not null, primary key
#  active                      :boolean
#  code                        :string
#  email                       :string
#  name                        :string
#  pro                         :boolean
#  scope                       :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  district_id                 :bigint           not null
#  municipality_id             :bigint           not null
#  responsible_subject_type_id :bigint           not null
#
class ResponsibleSubject < ApplicationRecord

end
