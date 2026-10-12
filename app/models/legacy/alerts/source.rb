# == Schema Information
#
# Table name: legacy_alerts_sources
#
#  id                     :bigint           not null, primary key
#  legacy_id              :integer
#  responsible_subject_id :bigint           not null
#  name                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class Legacy::Alerts::Source < ApplicationRecord
  self.table_name = "legacy_alerts_sources"

  belongs_to :responsible_subject
end
