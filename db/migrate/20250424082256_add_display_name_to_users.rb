class AddDisplayNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :display_name, :string

    User.find_each do |user|
      display_name = if user.anonymous?
                       "Anonym #{user.id}"
                     else
                       [ user.firstname, user.lastname ].reject(&:blank?).join(" ")
                     end

      user.update!(display_name: display_name)
    end
  end
end
