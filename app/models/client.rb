# == Schema Information
#
# Table name: clients
#
#  id                     :bigint           not null, primary key
#  api_token_public_key   :string
#  name                   :string
#  url                    :string
#  webhook_private_key    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  responsible_subject_id :bigint
#
class Client < ApplicationRecord
  belongs_to :responsible_subject, optional: true

  encrypts :webhook_private_key
end
