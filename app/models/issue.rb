class Issue < ApplicationRecord
  after_create_commit :schedule_send_to_zammad

  def schedule_send_to_zammad
    SendIssueToZammadJob.perform_later self
  end
end
