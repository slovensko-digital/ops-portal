# == Schema Information
#
# Table name: users
#
#  id                 :bigint           not null, primary key
#  about              :string
#  access_token       :string
#  active             :boolean
#  admin_name         :string
#  anonymous          :boolean          default(FALSE)
#  banned             :boolean          default(FALSE)
#  birth              :date
#  created_from_app   :boolean          default(FALSE)
#  email              :string
#  email_notification :boolean          default(TRUE)
#  exp                :integer
#  fcm_token          :string
#  first_name         :string
#  gdpr_accepted      :boolean
#  last_name          :string
#  login              :string
#  logo               :string
#  organization       :boolean
#  password           :string
#  phone              :string
#  resident           :boolean
#  rights             :integer
#  sex                :integer
#  signature          :string
#  verification       :string
#  verified           :boolean          default(FALSE)
#  website            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  city_id            :integer
#  municipality_id    :bigint           not null
#  street_id          :bigint           not null
#
class User < ApplicationRecord
  belongs_to :municipality
  belongs_to :street

  enum :rights, ops_admin: 1, municipality_admin: 2, user: 3
  enum :sex, m: 1, f: 2
end
