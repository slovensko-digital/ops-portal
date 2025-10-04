class UserStats::CalculatePercentilesJob < ApplicationJob
  def perform
    sql = <<-SQL
      WITH ranked_stats AS (
        SELECT
          id,
          PERCENT_RANK() OVER (ORDER BY issues_count) AS new_issues_percentile,
          PERCENT_RANK() OVER (ORDER BY comments_count) AS new_comments_percentile,
          PERCENT_RANK() OVER (ORDER BY verified_issues_count) AS new_verified_percentile
        FROM
          user_stats
      )
      UPDATE
        user_stats
      SET
        issues_percentile = ranked_stats.new_issues_percentile,
        comments_percentile = ranked_stats.new_comments_percentile,
        verified_issues_percentile = ranked_stats.new_verified_percentile
      FROM
        ranked_stats
      WHERE
        user_stats.id = ranked_stats.id;
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
