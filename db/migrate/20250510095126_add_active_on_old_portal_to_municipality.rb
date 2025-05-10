class AddActiveOnOldPortalToMunicipality < ActiveRecord::Migration[8.0]
  def change
    add_column :municipalities, :active_on_old_portal, :boolean, default: false, null: false
  end
end
