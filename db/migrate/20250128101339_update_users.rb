class UpdateUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :banned, :boolean, default: false
    add_column :users, :login, :string
    add_column :users, :legacy_rights, :integer
    add_column :users, :admin_name, :string
    add_column :users, :phone, :string
    add_column :users, :password, :string
    add_column :users, :about, :string
    add_column :users, :organization, :boolean
    add_column :users, :timestamp, :datetime # TODO Toto nevieme co je
    add_column :users, :anonymous, :boolean, default: false
    add_column :users, :active, :boolean # TODO Toto je len taky odhad co moze boolean status atribut znamenat
    add_reference :users, :municipality, null: true, foreign_key: true
    add_column :users, :created_from_app, :boolean, default: false
    add_column :users, :verification, :string # TODO Toto nevieme co je, ci sa hodnota meni alebo nie
    add_column :users, :verified, :boolean, default: false
    add_column :users, :signature, :string
    add_column :users, :city_id, :integer  # TODO Toto nevieme co je, referencia na mesto je ocividne municipality a tu nie je vzdy to iste
    add_reference :users, :street, null: true, foreign_key: true
    add_column :users, :resident, :boolean
    add_column :users, :sex, :integer
    add_column :users, :birth, :date
    add_column :users, :fcm_token, :string
    add_column :users, :gdpr_accepted, :boolean
    add_column :users, :access_token, :string # TODO Toto nevieme ako sa vyuziva, ci sa meni hodnota alebo nie
    add_column :users, :exp, :integer  # TODO Toto nevieme co znamena
    add_column :users, :email_notifiable, :boolean, default: true

    add_column :users, :created_at, :datetime, null: false
    add_column :users, :updated_at, :datetime, null: false
  end
end
