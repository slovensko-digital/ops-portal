# == Schema Information
#
# Table name: responsible_subjects_users
#
#  id                     :bigint           not null, primary key
#  deleted_at             :datetime
#  email                  :string
#  gdpr_accepted          :boolean
#  login                  :string
#  name                   :string
#  password               :string
#  photo                  :string
#  token                  :string
#  tooltips               :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  legacy_id              :integer
#  organization_unit_id   :bigint
#  responsible_subject_id :bigint
#  role_id                :bigint           not null
#
class ResponsibleSubjects::User < ApplicationRecord
  belongs_to :responsible_subject, optional: true
  belongs_to :organization_unit, optional: true
  belongs_to :role, class_name: "ResponsibleSubjects::UserRole", optional: true

  delegate :external_id, to: :responsible_subject
end
