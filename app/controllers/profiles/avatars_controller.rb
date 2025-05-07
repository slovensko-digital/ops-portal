class Profiles::AvatarsController < ApplicationController
  def update
    current_user.assign_attributes(avatar_params)
    if current_user.save
      redirect_to edit_profile_path, notice: "Fotka bola úspešne zmenená."
    else
      redirect_to edit_profile_path, error: "Fotku sa nepodarilo nahrať."
    end
  end

  private

  def avatar_params
    params.require(:user).permit(:avatar)
  end
end
