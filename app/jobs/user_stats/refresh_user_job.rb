class UserStats::RefreshUserJob < ApplicationJob
  def perform(user)
    user.stats.update!(
      issues_count: user.issues.publicly_visible.count,
      comments_count: user.issues_comments.count,
      verified_issues_count: 0
    )
  end
end
