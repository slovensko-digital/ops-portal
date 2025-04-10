# == Schema Information
#
# Table name: issues_categories
#
#  id                 :bigint           not null, primary key
#  alias              :string
#  catch_all          :boolean          default(FALSE)
#  description        :string
#  description_hu     :string
#  name               :string
#  name_hu            :string
#  weight             :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  legacy_id          :integer
#  triage_external_id :integer
#
class Issues::Category < ApplicationRecord
  has_many :subcategories, class_name: "Issues::Subcategory", dependent: :destroy

  scope :non_legacy, -> { where(legacy_id: nil) }
end
