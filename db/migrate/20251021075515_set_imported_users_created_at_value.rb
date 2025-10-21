class SetImportedUsersCreatedAtValue < ActiveRecord::Migration[8.0]
  def up
    User.where.not(legacy_id: nil).find_each do |user|
      user.update!(created_at: user.timestamp)
    end
  end
end
