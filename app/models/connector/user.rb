# == Schema Information
#
# Table name: connector_users
#
#  id                  :bigint           not null, primary key
#  firstname           :string
#  lastname            :string
#  uuid                :uuid
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  connector_tenant_id :bigint           not null
#  external_id         :integer
#
class Connector::User < ApplicationRecord
  belongs_to :tenant, class_name: "Connector::Tenant", optional: false, foreign_key: :connector_tenant_id
end
