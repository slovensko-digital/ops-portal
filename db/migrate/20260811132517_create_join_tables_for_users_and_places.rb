class CreateJoinTablesForUsersAndPlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :municipalities_users, id: false do |t|
      t.belongs_to :municipality
      t.belongs_to :user
    end

    create_table :municipality_districts_users, id: false do |t|
      t.belongs_to :municipality_district
      t.belongs_to :user
    end
  end
end
