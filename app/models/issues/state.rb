# == Schema Information
#
# Table name: issues_states
#
#  id         :bigint           not null, primary key
#  color      :string
#  key        :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  legacy_id  :integer
#
class Issues::State < ApplicationRecord
  PRIVATE_KEYS = %w[waiting rejected]
end
