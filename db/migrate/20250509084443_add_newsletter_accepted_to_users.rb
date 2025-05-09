class AddNewsletterAcceptedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :newsletter_accepted, :boolean, default: false, null: false
  end
end
