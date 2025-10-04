class UserStats::RefreshCountsAllJob < ApplicationJob
  queue_as :low_priority

  def perform
    private_state_keys = Issues::State::PRIVATE_KEYS
    quoted_keys = private_state_keys.map { |key| ActiveRecord::Base.connection.quote(key) }.join(",")

    sql = <<-SQL
      INSERT INTO user_stats (user_id, issues_count, comments_count, verified_issues_count, created_at, updated_at)
      SELECT
        stats.user_id,
        stats.total_issues,
        stats.total_comments,
        0, -- verified_issues_count
        CURRENT_TIMESTAMP, -- created_at
        CURRENT_TIMESTAMP  -- updated_at
      FROM (
        SELECT
          u.id AS user_id,
          COALESCE(COUNT(DISTINCT i.id), 0) AS total_issues,
          COALESCE(COUNT(DISTINCT c.id), 0) AS total_comments
        FROM
          users u
        LEFT JOIN
          issues i ON u.id = i.author_id AND i.state_id NOT IN (
            SELECT id FROM issues_states WHERE key IN (#{quoted_keys})
          )
        LEFT JOIN
          issues_comments c ON u.id = c.user_author_id
        GROUP BY
          u.id
      ) AS stats
      ON CONFLICT (user_id) DO UPDATE SET
        issues_count = EXCLUDED.issues_count,
        comments_count = EXCLUDED.comments_count,
        verified_issues_count = EXCLUDED.verified_issues_count,
        updated_at = EXCLUDED.updated_at;
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
