# == Schema Information
#
# Table name: connector_tenants
#
#  id                         :bigint           not null, primary key
#  backoffice_api_token       :string
#  backoffice_url             :string
#  backoffice_webhook_secret  :string
#  name                       :string
#  ops_api_subject_identifier :integer
#  ops_api_token_private_key  :string
#  ops_webhook_public_key     :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class Connector::Tenant < ApplicationRecord
  has_many :issues, class_name: "Connector::Issue", dependent: :destroy, inverse_of: :tenant
  has_many :users, class_name: "Connector::User", dependent: :destroy, inverse_of: :tenant
  has_many :activities, class_name: "Connector::Activity", dependent: :destroy, inverse_of: :tenant
  # TODO: encrypt secret fields
end
