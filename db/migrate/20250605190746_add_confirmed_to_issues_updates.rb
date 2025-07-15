class AddConfirmedToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :confirmed, :boolean, default: false

    Issues::Update.where.not(confirmed_by_id: nil).update_all(confirmed: true)
  end
end
