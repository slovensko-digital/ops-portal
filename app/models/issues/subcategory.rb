# == Schema Information
#
# Table name: issues_subcategories
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
#  category_id    :bigint           not null
#  legacy_id      :integer
#
class Issues::Subcategory < ApplicationRecord
  belongs_to :category, class_name: "Issues::Category"
  has_many :subtypes, class_name: "Issues::Subtype", dependent: :destroy

  scope :non_legacy, -> { where(legacy_id: nil) }
end
