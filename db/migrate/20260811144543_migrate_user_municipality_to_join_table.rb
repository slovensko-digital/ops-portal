class MigrateUserMunicipalityToJoinTable < ActiveRecord::Migration[8.1]
  # NOTE: intentionally does NOT drop users.municipality_id.
  # Old code still reads/writes it, so dropping it in the same deploy would break
  # processes running the previous release. The column is ignored by the new code
  # (see User.ignored_columns) and will be dropped in a follow-up deploy.
  def up
    execute <<~SQL
      INSERT INTO municipalities_users (municipality_id, user_id)
      SELECT municipality_id, id
      FROM users
      WHERE municipality_id IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM municipalities_users
    SQL
  end
end
