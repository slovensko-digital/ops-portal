# == Schema Information
#
# Table name: legacy_agents
#
#  id               :bigint           not null, primary key
#  about            :string
#  access_token     :string
#  active           :boolean
#  admin_name       :string
#  anonymous        :boolean          default(FALSE)
#  banned           :boolean          default(FALSE)
#  birth            :date
#  created_from_app :boolean          default(FALSE)
#  email            :string
#  email_notifiable :boolean          default(TRUE)
#  exp              :integer
#  fcm_token        :string
#  firstname        :string
#  gdpr_accepted    :boolean
#  lastname         :string
#  login            :string
#  organization     :boolean
#  password_hash    :string
#  phone            :string
#  resident         :boolean
#  rights           :integer
#  sex              :integer
#  signature        :string
#  timestamp        :datetime
#  uuid             :uuid             not null
#  verification     :string
#  verified         :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  city_id          :integer
#  external_id      :integer
#  legacy_id        :integer
#  municipality_id  :bigint
#  street_id        :bigint
#
class Legacy::Agent < ApplicationRecord
  belongs_to :municipality, optional: true
  belongs_to :street, optional: true

  enum :rights, ops_admin: 1, municipality_admin: 2
  enum :sex, m: 1, f: 2

  validates :external_id, uniqueness: true, allow_nil: true

  def fullname
    [ firstname, lastname ].reject(&:blank?).join(" ")
  end
end
