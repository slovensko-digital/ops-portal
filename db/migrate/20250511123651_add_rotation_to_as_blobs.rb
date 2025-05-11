class AddRotationToAsBlobs < ActiveRecord::Migration[8.0]
  def change
    add_column :active_storage_blobs, :rotation, :integer, default: 0
  end
end
