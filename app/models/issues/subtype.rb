# == Schema Information
#
# Table name: issues_subtypes
#
#  id             :bigint           not null, primary key
#  alias          :string
#  catch_all      :boolean          default(FALSE)
#  description    :string
#  description_hu :string
#  name           :string
#  name_hu        :string
#  weight         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  legacy_id      :integer
#  subcategory_id :bigint           not null
#
class Issues::Subtype < ApplicationRecord
  belongs_to :subcategory, class_name: "Issues::Subcategory"

  scope :non_legacy, -> { where(legacy_id: nil) }
end
