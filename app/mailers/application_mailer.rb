class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name(ENV.fetch("NOTIFICATION_SMTP_USERNAME", "example@example.org"), "Odkaz pre starostu")
  layout "mailer"
end
