# == Schema Information
#
# Table name: cms_pages
#
#  id          :bigint           not null, primary key
#  raw         :text             not null
#  slug        :string           not null
#  tags        :string           default([]), is an Array
#  text        :text             not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint           not null
#
module Ai
  class Prompt < Cms::Page
    def self.get(prompt_name)
      joins(:category)
        .where(cms_categories: { id: ENV.fetch("CMS_AI_CATEGORY_ID") })
        .with_tags("prompt:#{prompt_name}")
        .first&.raw
    end
  end
end
