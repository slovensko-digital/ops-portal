class AddActiveToClients < ActiveRecord::Migration[8.1]
  def change
    # responsible_subjects:downgrade_to_basic disables the Client of a PRO responsible subject, its API tokens stop working
    add_column :clients, :active, :boolean, default: true, null: false
  end
end
