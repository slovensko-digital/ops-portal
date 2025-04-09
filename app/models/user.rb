# == Schema Information
#
# Table name: users
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
#  email            :citext           not null
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
#  sex              :integer
#  signature        :string
#  status           :integer          default("unverified"), not null
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
class User < ApplicationRecord
  include Rodauth::Rails.model
  # TODO: encrypt password field and access_token

  belongs_to :municipality, optional: true
  belongs_to :street, optional: true
  has_many :issues
  has_many :issues_drafts, class_name: "Issues::Draft", foreign_key: :author_id

  enum :sex, m: 1, f: 2
  enum :status, { unverified: 1, verified: 2, closed: 3 }

  validates :external_id, uniqueness: true, allow_nil: true

  def fullname
    [ firstname, lastname ].reject(&:blank?).join(" ")
  end
end
