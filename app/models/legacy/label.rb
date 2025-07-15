# == Schema Information
#
# Table name: legacy_labels
#
#  id                     :bigint           not null, primary key
#  color                  :string
#  name                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  legacy_id              :integer
#  responsible_subject_id :bigint           not null
#
class Legacy::Label < ApplicationRecord
  belongs_to :responsible_subject

  def self.find_or_create_by_legacy_id(legacy_id)
    return ::Legacy::Label.find_by(legacy_id: legacy_id) if ::Legacy::Label.find_by(legacy_id: legacy_id)

    legacy_record = Legacy::OldLabel.find_by_id(legacy_id)
    self.create_from_legacy_record(legacy_record) if legacy_record
  end

  def self.create_from_legacy_record(legacy_record)
    ::Legacy::Label.find_or_create_by!(
      legacy_id: legacy_record.id,
      name: legacy_record.text,
      color: legacy_record.color,
      responsible_subject: ResponsibleSubject.find_by(legacy_id: legacy_record.zodpovednost_id)
    )
  end
end
