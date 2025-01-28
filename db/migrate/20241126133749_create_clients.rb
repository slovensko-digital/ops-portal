class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :url
      t.string :responsible_subject_zammad_identifier
      t.string :api_token_public_key
      t.string :webhook_private_key

      t.timestamps
    end
  end
end
