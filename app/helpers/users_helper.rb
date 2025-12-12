module UsersHelper
  def link_to_user_profile(user, display_name: nil, avatar_variant: :normal)
    avatar = content_tag(:figure) do
      if not user.is_a?(User) or user.anonymous?
        content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
      else
        link_to user, data: { turbo_frame: "_top" } do
          content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
        end
      end
    end

    name = content_tag(:div, display_name.presence || user&.display_name || "Neznámy autor", class: "name")

    safe_join([ avatar, name ])
  end
end
