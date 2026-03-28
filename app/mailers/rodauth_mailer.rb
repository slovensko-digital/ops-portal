class RodauthMailer < ApplicationMailer
  default to: -> { @rodauth.email_to }

  def verify_account(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @verify_account_key_value = key }
    @account = @rodauth.rails_account

    mail subject: "Odkaz pre starostu | #{t('rodauth.verify_account_email_subject')}"
  end

  def reset_password(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @reset_password_key_value = key }
    @account = @rodauth.rails_account

    mail subject: "Odkaz pre starostu | #{t('rodauth.reset_password_email_subject')}"
  end

  def verify_login_change(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @verify_login_change_key_value = key }
    @account = @rodauth.rails_account
    @new_email = @account.login_change_key.login

    mail to: @new_email, subject: "Odkaz pre starostu | #{t('rodauth.verify_login_change_email_subject')}"
  end

  def email_auth(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @email_auth_key_value = key }
    @account = @rodauth.rails_account
    @email_auth_link = @rodauth.email_auth_email_link

    mail subject: "Odkaz pre starostu | #{t('rodauth.email_auth_email_subject')}"
  end

  private

  # Default URL options are inherited from Action Mailer, but you can override them
  # ad-hoc by modifying the `rodauth.rails_url_options` hash.
  def rodauth(name, account_id, &block)
    instance = RodauthApp.rodauth(name).allocate
    instance.account_from_id(account_id)
    instance.instance_eval(&block) if block
    instance
  end
end
