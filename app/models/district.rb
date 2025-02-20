# == Schema Information
#
# Table name: districts
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  legacy_id  :integer
#
class District < ApplicationRecord
  has_many :municipalities
end
