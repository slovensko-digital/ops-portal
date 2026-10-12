# == Schema Information
#
# Table name: districts
#
#  id         :bigint           not null, primary key
#  legacy_id  :integer
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class District < ApplicationRecord
  has_many :municipalities
end
