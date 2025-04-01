# == Schema Information
#
# Table name: issues_communications
#
#  id                       :bigint           not null, primary key
#  added_at                 :datetime
#  author_type              :string
#  confirmation_needed      :boolean
#  email                    :string
#  from_responsible_subject :boolean
#  internal                 :boolean
#  ip                       :inet
#  message                  :string
#  plain_message            :string
#  signature                :string
#  solution_rejected        :boolean
#  solved                   :boolean
#  solved_by                :string
#  solved_in                :string
#  subject                  :string
#  text                     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  activity_id              :bigint           not null
#  admin_id                 :integer
#  author_id                :bigint
#  legacy_id                :integer
#  person_id                :integer
#  triage_external_id       :integer
#  user_id                  :integer
#
class Issues::Communication < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity"
  belongs_to :author, polymorphic: true, optional: true

  has_many_attached :attachments


  def activity_body
    message
  end

  def in_triage_as_internal?
    true
  end
end
