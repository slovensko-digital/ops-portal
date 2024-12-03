# == Schema Information
#
# Table name: issues
#
#  id                 :bigint           not null, primary key
#  author             :string           not null
#  description        :string           not null
#  last_synced_at     :datetime
#  reported_at        :datetime         not null
#  state              :string
#  title              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  triage_external_id :integer
#
class Issue < ApplicationRecord
  after_create_commit :schedule_send_to_zammad

  def schedule_send_to_zammad
    SendIssueToZammadJob.perform_later self
  end
end
