class MigrateUserMunicipalityToJoinTable < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO municipalities_users (municipality_id, user_id)
      SELECT municipality_id, id
      FROM users
      WHERE municipality_id IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM municipalities_users
    SQL
  end
end
