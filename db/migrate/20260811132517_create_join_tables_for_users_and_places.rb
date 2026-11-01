class CreateJoinTablesForUsersAndPlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :municipalities_users, id: false do |t|
      t.belongs_to :municipality, null: false, foreign_key: true, index: false
      t.belongs_to :user, null: false, foreign_key: true, index: false

      t.index [ :municipality_id, :user_id ], unique: true
      t.index [ :user_id, :municipality_id ]
    end

    create_table :municipality_districts_users, id: false do |t|
      t.belongs_to :municipality_district, null: false, foreign_key: true, index: false
      t.belongs_to :user, null: false, foreign_key: true, index: false

      t.index [ :municipality_district_id, :user_id ], unique: true,
        name: "index_municipality_districts_users_on_district_and_user"
      t.index [ :user_id, :municipality_district_id ],
        name: "index_municipality_districts_users_on_user_and_district"
    end
  end
end
