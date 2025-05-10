class UnsubscribesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :global_post ]

  def global
    # TODO: add custom views for global unsubscribes
    user = User.find_by(email_global_unsubscribe_token: params[:token])
    if user
      user.update(email_notifiable: false)
      redirect_to root_path, notice: "Odhlásenie z odberu bolo úspešné."
    else
      redirect_to root_path, alert: "Odhlásenie z odberu sa nepodarilo. Skontrolujte prosím platnosť odkazu."
    end
  end

  def global_post
    user = User.find_by(email_global_unsubscribe_token: params[:token])
    if user
      user.update(email_notifiable: false)
      head :ok
    else
      head :not_found
    end
  end

  def subscription
    # TODO: add custom views for subscription unsubscribes
    subscription = IssueSubscription.find_by(email_unsubscribe_token: params[:token])
    if subscription
      subscription.update(email_notifiable: false)
      redirect_to root_path, notice: "Odhlásenie z odberu bolo úspešné."
    else
      redirect_to root_path, alert: "Odhlásenie z odberu sa nepodarilo. Skontrolujte prosím platnosť odkazu."
    end
  end
end
