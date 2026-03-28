class UserStats::CalculatePercentilesJob < ApplicationJob
  def perform
    sql = <<-SQL
      WITH ranked_stats AS (
        SELECT
          id,
          PERCENT_RANK() OVER (ORDER BY stats_issues_count) AS new_issues_percentile,
          PERCENT_RANK() OVER (ORDER BY stats_comments_count) AS new_comments_percentile,
          PERCENT_RANK() OVER (ORDER BY stats_verified_issues_count) AS new_verified_percentile
        FROM
          users
        WHERE
          type = ?
      )
      UPDATE
        users
      SET
        stats_issues_percentile = ranked_stats.new_issues_percentile,
        stats_comments_percentile = ranked_stats.new_comments_percentile,
        stats_verified_issues_percentile = ranked_stats.new_verified_percentile
      FROM
        ranked_stats
      WHERE
        users.id = ranked_stats.id;
    SQL

    ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql_array([ sql, User::Citizen.name ]))
  end
end
