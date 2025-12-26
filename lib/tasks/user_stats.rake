namespace :user_stats do
  desc "Create user stats for all users, and refresh counts"
  task create: :environment do
    Rails.logger.info "Creating user stats all users..."
    UserStats::RefreshCountsAllJob.perform_now
    Rails.logger.info "User stats created and counts refreshed for all users"
  end

  desc "Calculate global percentiles after counts have been calculated"
  task calculate_percentiles: :environment do
    Rails.logger.info "Calculating global percentiles..."
    UserStats::CalculatePercentilesJob.perform_now
    Rails.logger.info "Percentiles calculated for all users"
  end
end
