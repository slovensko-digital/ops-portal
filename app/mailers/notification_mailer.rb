class NotificationMailer < ApplicationMailer
  layout "notification_mailer"

  before_action { @subscription = params[:subscription] }
  before_action { @user = @subscription.subscriber }
  before_action { @issue = @subscription.issue }
  before_action :set_unsubscribe_headers
  default to: -> { @user.email },
    subject: -> { ops_subject },
    from: email_address_with_name(ENV.fetch("NOTIFICATION_SMTP_USERNAME", "example@example.org"), "Odkaz pre starostu")

  def new_issue_user_comment(comment)
    @comment = comment
    mail
  end

  def new_issue_responsible_subject_comment(comment)
    @comment = comment
    mail
  end

  def new_issue_update
    # TODO: remove this when issue update is implemented and view is ready
    raise NotImplementedError
    mail
  end

  def new_issue_verification
    # TODO: remove this when issue verification is implemented and view is ready
    raise NotImplementedError

    mail
  end

  def issue_accepted
    mail
  end

  def issue_unresolved
    mail
  end

  def issue_resolved
    mail
  end

  def issue_referred
    mail
  end

  def issue_closed
    mail
  end

  def issue_rejected
    mail
  end

  def praise_accepted
    mail
  end

  private

  def set_unsubscribe_headers
    headers["List-Unsubscribe"] = "<#{unsubscribe_global_subscriptions_url(token: @user.email_global_unsubscribe_token)}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end

  def ops_subject
    case @issue.issue_type
    when "issue"
      "Odkaz pre starostu | #{@issue.title} (Podnet ##{@issue.id})"
    when "question"
      "Odkaz pre starostu | #{@issue.title} (Otázka ##{@issue.id})"
    when "praise"
      "Odkaz pre starostu | #{@issue.title} (Pochvala ##{@issue.id})"
    else
      raise NotImplementedError
    end
  end
end
