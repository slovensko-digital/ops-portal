# == Schema Information
#
# Table name: issue_categories
#
#  id             :bigint           not null, primary key
#  catch_all      :boolean          default(FALSE)
#  category       :string
#  category_alias :string
#  category_hu    :string
#  description    :string
#  description_hu :string
#  weight         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  parent_id      :bigint           not null
#
class Issue::Category < ApplicationRecord

end
