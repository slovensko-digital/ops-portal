class SubscriptionsController < ApplicationController
  def unsubscribe
    # TODO: add custom views for subscription unsubscribes
    subscription = IssueSubscription.find_by(email_unsubscribe_token: params[:token])
    if subscription && subscription.destroy
      redirect_to root_path, notice: "Odhlásenie z odberu bolo úspešné."
    else
      redirect_to root_path, alert: "Odhlásenie z odberu sa nepodarilo. Skontrolujte prosím platnosť odkazu."
    end
  end
end
