class UserStats::DailyRefreshJob < ApplicationJob
  def perform
    UserStats::RefreshCountsAllJob.perform_now

    UserStats::CalculatePercentilesJob.perform_now
  end
end
