# == Schema Information
#
# Table name: connector_users
#
#  id                :bigint           not null, primary key
#  firstname         :string
#  lastname          :string
#  uuid              :uuid
#  zammad_identifier :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Connector::User < ApplicationRecord
end
