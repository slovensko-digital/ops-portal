# == Schema Information
#
# Table name: legacy_labels
#
#  id                     :bigint           not null, primary key
#  legacy_id              :integer
#  responsible_subject_id :bigint           not null
#  color                  :string
#  name                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Legacy::Label < ApplicationRecord
  belongs_to :responsible_subject
end
