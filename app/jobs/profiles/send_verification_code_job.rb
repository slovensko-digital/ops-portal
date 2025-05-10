class Profiles::SendVerificationCodeJob < ApplicationJob
  queue_as :default
  queue_with_priority ASAP

  def perform(user, phone_number)
    user.regenerate_phone_verification_code!
    sns = Aws::SNS::Client.new
    sns.publish(
      phone_number: phone_number,
      message: "Overovací kód pre Odkaz pre starostu: #{user.phone_verification_code}\n\n@#{ENV['APP_HOST']} ##{user.phone_verification_code}"
    )
  end
end
