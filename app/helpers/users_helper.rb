module UsersHelper
  def link_to_user_profile(user, avatar_variant: :normal)
    avatar = content_tag(:figure) do
      if user.anonymous?
        content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
      else
        link_to user_path(user), data: { turbo_frame: "_top" } do
          content_tag(:picture) { user_avatar(user, variant: avatar_variant) }
        end
      end
    end

    display_name = user.present? ? user.display_name : "Neznámy autor"

    name = if user.anonymous?
             content_tag(:div, display_name, class: "name")
    else
             link_to user_path(user), data: { turbo_frame: "_top" } do
               content_tag(:div, display_name, class: "name")
             end
    end

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
