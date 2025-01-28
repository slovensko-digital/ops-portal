class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :firstname
      t.string :lastname
      t.integer :zammad_identifier, index: { unique: true }
      t.uuid :uuid, default: "gen_random_uuid()", null: false
    end

    create_table :connector_users do |t|
      t.integer :zammad_identifier, index: { unique: true }
      t.uuid :uuid
      t.string :firstname
      t.string :lastname

      t.timestamps
    end
  end
end
