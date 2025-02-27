class CreateIssuesStates < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_states do |t|
      t.string :name
      t.string :color
      t.timestamps
    end

    Issues::State.find_or_create_by!(name: "Zaslaný zodpovednému")
    Issues::State.find_or_create_by!(name: "Odstúpený")
  end
end
