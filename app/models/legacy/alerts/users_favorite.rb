# == Schema Information
#
# Table name: users_favorites
#
#  id            :integer          unsigned, not null, primary key
#  created_at    :datetime         not null
#  submission_id :integer          unsigned, not null
#  user_id       :integer          not null
#
class Legacy::Alerts::UsersFavorite < Legacy::GenericModel
  self.table_name = "users_favorites"
end
