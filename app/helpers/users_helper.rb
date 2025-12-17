module UsersHelper
  def link_to_user_profile(user, avatar_variant: :normal)
    avatar = content_tag(:figure) do
      if user.anonymous?
        content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
      else
        link_to user, data: { turbo_frame: "_top" } do
          content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
        end
      end
    end

    name = content_tag(:div, user.present? ? user.display_name : "Neznámy autor", class: "name")

    safe_join([ avatar, name ])
  end

  def link_to_comment_author_profile(comment, avatar_variant: :normal)
    if comment.author.is_a?(User)
      return link_to_user_profile(comment.author, avatar_variant: avatar_variant)
    end

    avatar = content_tag(:figure) do
      content_tag(:picture) { user_avatar(comment.author, variant: avatar_variant) }
    end

    name = content_tag(:dig, comment.author_display_name, class: "name")

    safe_join([ avatar, name ])
  end
end
