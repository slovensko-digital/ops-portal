class UserStats::RefreshCountsAllJob < ApplicationJob
  queue_as :low_priority

  def perform
    sql = <<-SQL
      WITH stats AS (
        SELECT
          u.id AS user_id,
          COALESCE(COUNT(DISTINCT i.id), 0) AS total_issues,
          COALESCE(COUNT(DISTINCT c.id), 0) AS total_comments
        FROM
          users u
        LEFT JOIN
          issues i ON u.id = i.author_id AND i.state_id NOT IN (
            SELECT id FROM issues_states WHERE key IN (?)
          )
        LEFT JOIN
          issues_comments c ON u.id = c.user_author_id
        GROUP BY
          u.id
      )
      UPDATE
        users
      SET
        stats_issues_count = stats.total_issues,
        stats_comments_count = stats.total_comments,
        stats_verified_issues_count = 0,
        updated_at = CURRENT_TIMESTAMP
      FROM
        stats
      WHERE
        users.id = stats.user_id;
    SQL

    ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array([ sql, Issues::State::PRIVATE_KEYS ]))
  end
end
