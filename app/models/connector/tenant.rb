# == Schema Information
#
# Table name: connector_tenants
#
#  id                     :bigint           not null, primary key
#  api_subject_identifier :integer
#  api_token_private_key  :string
#  name                   :string
#  webhook_public_key     :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  triage_user_id         :integer
#
class Connector::Tenant < ApplicationRecord
end
