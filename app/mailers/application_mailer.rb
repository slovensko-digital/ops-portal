class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name(ENV.fetch("NOTIFICATION_SENDER_EMAIL", "example@example.org"), "Odkaz pre starostu")
  layout "mailer"
end
