# == Schema Information
#
# Table name: issues_categories
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
#  parent_id      :bigint
#
class Issues::Category < ApplicationRecord
  belongs_to :parent, class_name: "Issues::Category", dependent: :destroy, optional: true
end
