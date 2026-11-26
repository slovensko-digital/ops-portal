# == Schema Information
#
# Table name: clients
#
#  id                     :bigint           not null, primary key
#  responsible_subject_id :bigint
#  active                 :boolean          default(TRUE), not null
#  api_token_public_key   :string
#  name                   :string
#  url                    :string
#  webhook_private_key    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Client < ApplicationRecord
  belongs_to :responsible_subject, optional: true

  scope :active, -> { where(active: true) }

  encrypts :webhook_private_key
end
