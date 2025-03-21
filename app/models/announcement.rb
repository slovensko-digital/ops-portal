# == Schema Information
#
# Table name: announcements
#
#  id         :bigint           not null, primary key
#  raw        :jsonb            not null
#  slug       :string           not null
#  text       :text             not null
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Announcement < ApplicationRecord
  validates :title, :slug, :text, presence: true

  before_validation :populate_slug

  def to_param
    "#{id}-#{slug}"
  end

  def populate_slug
    self.slug = title.parameterize
  end
end
