class Profiles::VerificationsController < ApplicationController
  before_action :require_user
  before_action :set_user

  def new
  end


  def update
    @user.assign_attributes(verify_params)
    if @user.valid?(:phone_verification)
      record_phone_verification_attempt(@user)

      ::Profiles::SendVerificationCodeJob.perform_later(@user, @user.phone)

      redirect_to action: :code
    else
      render :new, status: :unprocessable_entity
    end
  end

  def code
  end

  def check_code
    @user = current_user
    @user.assign_attributes(verify_code_params)
    if @user.save(context: :phone_verification_code)
      redirect_to profile_path, notice: "Váš účet bol úspešne overený."
    else
      @user.update_attribute(:phone_verification_code_attempts, @user.phone_verification_code_attempts + 1)

      render :code, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def verify_params
    params.require(:user).permit(:phone_verification_number)
  end

  def verify_code_params
    params.require(:user).permit(:phone_verification_code_confirmation, :phone_verified)
  end

  def record_phone_verification_attempt(user)
    unless user.recent_phone_verification?
      user.phone_verification_attempts = 0 # reset
    end
    user.phone_verification_attempted_at = Time.current
    user.phone_verification_attempts += 1
    user.phone_verification_code_attempts = 0 # reset
    user.save
  end
end
