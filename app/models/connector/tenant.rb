# == Schema Information
#
# Table name: connector_tenants
#
#  id                     :bigint           not null, primary key
#  api_subject_identifier :integer
#  api_token              :string
#  api_token_private_key  :string
#  name                   :string
#  url                    :string
#  webhook_public_key     :string
#  webhook_secret         :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  triage_user_id         :integer
#
class Connector::Tenant < ApplicationRecord
  has_many :issues, class_name: "Connector::Issue", dependent: :destroy
  has_many :users, class_name: "Connector::User", dependent: :destroy
  has_many :comments, class_name: "Connector::Comment", dependent: :destroy
end
