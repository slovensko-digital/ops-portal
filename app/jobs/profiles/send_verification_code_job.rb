class Profiles::SendVerificationCodeJob < ApplicationJob
  queue_as :default
  queue_with_priority ASAP

  def perform(user, phone_number)
    user.regenerate_phone_verification_code!
    client = Aws::PinpointSMSVoiceV2::Client.new
    client.send_text_message(
      {
        destination_phone_number: phone_number,
        origination_identity: "OPS",
        message_body: "Overovací kód pre Odkaz pre starostu: #{user.phone_verification_code}\n\n@#{ENV['APP_HOST']} ##{user.phone_verification_code}",
        message_type: "TRANSACTIONAL",
        protect_configuration_id: ENV["AWS_PINPOINT_PROTECT_CONFIGURATION_ID"]
      }
    )
  end
end
