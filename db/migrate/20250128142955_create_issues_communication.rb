class CreateIssuesCommunication < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_communications do |t|
      t.references :activity, null: false, foreign_key: { to_table: :issues_activities }
      t.boolean :from_responsible_subject
      t.string :subject
      t.string :message
      t.integer :admin_id # TODO - upravit na referenciu, ked sa ujasni ktora referencia co znamena a kam ukazuje
      t.integer :person_id # TODO - upravit na referenciu, ked sa ujasni ktora referencia co znamena a kam ukazuje
      t.integer :user_id # TODO - upravit na referenciu, ked sa ujasni ktora referencia co znamena a kam ukazuje
      t.string :text
      t.string :solved_by
      t.string :solved_in
      t.boolean :solved
      t.boolean :solution_rejected
      t.string :email
      t.datetime :added_at
      t.inet :ip
      t.boolean :internal
      t.boolean :confirmation_needed
      t.string :plain_message
      t.string :signature

      t.timestamps
    end
  end
end
