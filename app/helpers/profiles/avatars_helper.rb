module Profiles::AvatarsHelper
  def user_avatar(user, variant: :normal)
    image = "ops-avatar-blue.png"
    if user.is_a?(User) && user.avatar.attached?
      image = user.avatar.variant(variant)
    end

    image_tag(image, alt: "Avatar")
  end
end
