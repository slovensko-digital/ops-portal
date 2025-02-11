
# == Schema Information
#
# Table name: responsible_subjects_types
#
#  id         :bigint           not null, primary key
#  active     :boolean
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ResponsibleSubjects::Type < ApplicationRecord
end
