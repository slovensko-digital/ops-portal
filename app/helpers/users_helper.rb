module UsersHelper
  def user_subject(user, avatar_variant: :normal)
    avatar = content_tag(:figure) do
      if user.anonymous?
        content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
      else
        link_to "/pouzivatelia/#{user.id}", data: { turbo: false } do
          content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
        end
      end
    end

    name = content_tag(:div, user.present? ? user.display_name : "Neznámy autor", class: "name")

    safe_join([ avatar, name ])
  end
end
