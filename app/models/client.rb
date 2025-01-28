# == Schema Information
#
# Table name: clients
#
#  id                                    :bigint           not null, primary key
#  api_token_public_key                  :string
#  name                                  :string
#  responsible_subject_zammad_identifier :string
#  url                                   :string
#  webhook_private_key                   :string
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#
class Client < ApplicationRecord
end
