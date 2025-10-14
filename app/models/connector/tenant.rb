# == Schema Information
#
# Table name: connector_tenants
#
#  id                          :bigint           not null, primary key
#  backoffice_api_token        :string
#  backoffice_url              :string
#  backoffice_webhook_secret   :string
#  migrate_legacy_labels       :boolean          default(TRUE)
#  name                        :string
#  ops_api_subject_identifier  :integer
#  ops_api_token_private_key   :string
#  ops_webhook_public_key      :string
#  receive_customer_activities :boolean          default(FALSE), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
class Connector::Tenant < ApplicationRecord
  has_many :issues, class_name: "Connector::Issue", dependent: :destroy, inverse_of: :tenant
  has_many :users, class_name: "Connector::User", dependent: :destroy, inverse_of: :tenant
  has_many :activities, class_name: "Connector::Activity", dependent: :destroy, inverse_of: :tenant

  encrypts :backoffice_api_token
  encrypts :backoffice_webhook_secret
  encrypts :ops_api_token_private_key
end
