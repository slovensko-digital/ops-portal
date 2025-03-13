class RenameConnectorCommentToConnectorActivity < ActiveRecord::Migration[8.0]
  def change
    rename_table :connector_comments, :connector_activities
  end
end
