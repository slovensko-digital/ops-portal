# == Schema Information
#
# Table name: connector_comments
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  backoffice_external_id :integer
#  triage_external_id     :integer
#
class Connector::Comment < ApplicationRecord
  belongs_to :tenant, class_name: "Connector::Tenant", optional: false, foreign_key: :connector_tenant_id
end
