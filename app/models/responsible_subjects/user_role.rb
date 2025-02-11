# == Schema Information
#
# Table name: responsible_subjects_user_roles
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ResponsibleSubjects::UserRole < ApplicationRecord
end
