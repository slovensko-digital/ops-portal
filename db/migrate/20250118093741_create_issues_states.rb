class CreateIssuesStates < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_states do |t|
      t.string :name
      t.string :color
      t.timestamps
    end
  end
end
