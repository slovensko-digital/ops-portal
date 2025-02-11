class AddPositionToActiveStorageAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :active_storage_attachments, :position, :integer, default: nil
  end
end
