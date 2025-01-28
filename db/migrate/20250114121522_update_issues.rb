class UpdateIssues < ActiveRecord::Migration[8.0]
  def up
    add_column :issues, :anonymous, :bool
    add_column :issues, :address, :string
    add_column :issues, :latitude, :float
    add_column :issues, :longitude, :float
    add_column :issues, :category, :string, null: false
    add_column :issues, :municipality, :string, null: false

    remove_column :issues, :author
    add_belongs_to :issues, :author, foreign_key: { to_table: :users }
  end

  def down
    remove_column :issues, :anonymous
    remove_column :issues, :address
    remove_column :issues, :latitude
    remove_column :issues, :longitude
    remove_column :issues, :category
    remove_column :issues, :municipality

    add_column :issues, :author, :string
    remove_belongs_to :issues, :author, foreign_key: { to_table: :users }
  end
end
