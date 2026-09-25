class MigrateUserMunicipalityToJoinTable < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO municipalities_users (municipality_id, user_id)
      SELECT municipality_id, id
      FROM users
      WHERE municipality_id IS NOT NULL
    SQL

    remove_reference :users, :municipality, foreign_key: true
  end

  def down
    add_reference :users, :municipality, foreign_key: true

    execute <<~SQL
      UPDATE users
      SET municipality_id = municipalities_users.municipality_id
      FROM municipalities_users
      WHERE municipalities_users.user_id = users.id
    SQL
  end
end
