# == Schema Information
#
# Table name: legacy_alerts_sources
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  legacy_id              :integer
#  responsible_subject_id :bigint           not null
#
class Legacy::Alerts::Source < ApplicationRecord
  self.table_name = "legacy_alerts_sources"

  belongs_to :responsible_subject

  def self.find_or_create_by_legacy_id(legacy_id)
    return ::Legacy::Alerts::Source.find_by(legacy_id: legacy_id) if ::Legacy::Alerts::Source.find_by(legacy_id: legacy_id)

    legacy_record = Legacy::Alerts::OldSource.find_by_id(legacy_id)
    self.create_from_legacy_record(legacy_record) if legacy_record
  end

  def self.create_from_legacy_record(legacy_record)
    ::Legacy::Alerts::Source.find_or_create_by!(
      legacy_id: legacy_record.id,
      name: legacy_record.text,
      responsible_subject: ResponsibleSubject.find_by(legacy_id: legacy_record.zodpovednost_id)
    )
  end
end
