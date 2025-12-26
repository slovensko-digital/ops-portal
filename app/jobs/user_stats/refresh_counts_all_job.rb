class UserStats::RefreshCountsAllJob < ApplicationJob
  queue_as :low_priority

  def perform
    sql = <<-SQL
      UPDATE users
      SET
        stats_issues_count = (
          SELECT COUNT(*)
          FROM issues
          WHERE author_id = users.id
            AND state_id NOT IN (SELECT id FROM issues_states WHERE key IN (?))
        ),
        stats_comments_count = (
          SELECT COUNT(*)
          FROM issues_comments
          WHERE user_author_id = users.id
        ),
        stats_verified_issues_count = (
          SELECT COUNT(*)
          FROM issues_updates
          WHERE author_id = users.id
            AND verification_status = 1
        ),
        updated_at = CURRENT_TIMESTAMP
    SQL

    ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array([ sql, Issues::State::PRIVATE_KEYS ]))
  end
end
