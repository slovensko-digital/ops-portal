class BackfillUserTypeAndMakeNotNull < ActiveRecord::Migration[8.1]
  def up
    User.where(type: nil).update_all(type: "User::Citizen")

    change_column_null :users, :type, false
  end

  def down
    change_column_null :users, :type, true
  end
end
