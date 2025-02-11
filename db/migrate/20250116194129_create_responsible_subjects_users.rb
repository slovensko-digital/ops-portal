class CreateResponsibleSubjectsUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subjects_users do |t|
      t.references :responsible_subject, null: true, foreign_key: true
      t.references :role, null: false, foreign_key: { to_table: :responsible_subjects_user_roles }
      t.string :login
      t.string :password
      t.string :name
      t.string :email
      t.string :token # TODO nevieme co znamena, na co sa pouziva, ci sa moze menit
      t.string :photo
      t.datetime :deleted_at
      t.references :organization_unit, null: true, foreign_key: { to_table: :responsible_subjects_organization_units }
      t.boolean :gdpr_accepted
      t.boolean :tooltips

      t.timestamps
    end
  end
end
