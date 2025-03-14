require "sequel/core"

class RodauthMain < Rodauth::Rails::Auth
  configure do
    # List of authentication features that are loaded.
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :logout, :remember,
      :reset_password, :change_password, :change_login, :verify_login_change,
      :close_account

    # Omniauth
    enable :omniauth

    omniauth_provider :facebook,
      ENV.fetch("FACEBOOK_APP_ID"),
      ENV.fetch("FACEBOOK_APP_SECRET"),
      scope: "email"

    # Make sure provider name is explicitly set as a string for database queries
    omniauth_provider :google_oauth2,
      ENV.fetch("GOOGLE_CLIENT_ID"),
      ENV.fetch("GOOGLE_CLIENT_SECRET"),
      name: "google" # Using a string instead of symbol

    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # ==> General
    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)
    # Avoid DB query that checks accounts table schema at boot time.
    convert_token_id_to_integer? { User.columns_hash["id"].type == :integer }

    # Change prefix of table and foreign key column names from default "account"
    accounts_table :users
    verify_account_table :user_verification_keys
    verify_login_change_table :user_login_change_keys
    reset_password_table :user_password_reset_keys
    remember_table :user_remember_keys
    omniauth_identities_table :user_identities
    omniauth_identities_account_id_column :user_id

    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    # hmac_secret "5f28b1718d78025da4a781a5e64d0fe7dcf8b3f5a66dbae064472e2773e0058fb08c37145c2627780d7208792309b593e2d8967189131a723cf84cbcac65ed0f"

    # Use path prefix for all routes.
    # prefix "/auth"

    # Specify the controller used for view rendering, CSRF, and callbacks.
    rails_controller { RodauthController }

    # Make built-in page titles accessible in your views via an instance variable.
    title_instance_variable :@page_title

    # Store account status in an integer column without foreign key constraint.
    account_status_column :status

    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash

    # Set password when creating account instead of when verifying.
    verify_account_set_password? false

    # Change some default param keys.
    login_param "email"
    login_confirm_param "email-confirm"
    # password_confirm_param "confirm_password"

    # Redirect back to originally requested location after authentication.
    # login_return_to_requested_location? true
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    # delete_account_on_close? true

    # Redirect to the app from login and registration pages if already logged in.
    # already_logged_in { redirect login_redirect }

    # ==> Emails
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end

    # ==> Flash
    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

    # Override default flash messages.
    # create_account_notice_flash "Your account has been created. Please verify your account by visiting the confirmation link sent to your email address."
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this email address doesn't exist"
    # already_an_account_with_this_login_message "user with this email address already exists"
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    # login_does_not_meet_requirements_message { "invalid email#{", #{login_requirement_message}" if login_requirement_message}" }

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    password_minimum_length 8
    # bcrypt has a maximum input length of 72 bytes, truncating any extra bytes.
    password_maximum_bytes 72

    # Custom password complexity requirements (alternative to password_complexity feature).
    # password_meets_requirements? do |password|
    #   super(password) && password_complex_enough?(password)
    # end
    # auth_class_eval do
    #   def password_complex_enough?(password)
    #     return true if password.match?(/\d/) && password.match?(/[^a-zA-Z\d]/)
    #     set_password_requirement_error_message(:password_simple, "requires one number and one special character")
    #     false
    #   end
    # end

    # ==> Remember Feature
    # Remember all logged in users.
    after_login { remember_login }

    # Or only remember users that have ticked a "Remember Me" checkbox on login.
    # after_login { remember_login if param_or_nil("remember") }

    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true

    # ==> Account Creation and OmniAuth Integration
    before_create_account { validate_user_details }
    before_omniauth_create_account { validate_user_details }

    # Add a handler for OmniAuth login failure
    omniauth_on_failure do
      flash[:error] = "Authentication failed. Please try again."
      redirect login_path
    end

    # Process OmniAuth data before callback
    omniauth_before_callback_phase do
      if omniauth_auth
        session[:omniauth_provider] = omniauth_auth["provider"] if omniauth_auth["provider"]
        session[:omniauth_email] = omniauth_auth["info"]&.[]("email") if omniauth_auth["info"]
      end
    end

    before_omniauth_create_account do
      handle_omniauth_data
      redirect create_account_path
    end

    before_create_account_route do
      handle_registration_steps
    end

    # Create OmniAuth identity after account creation if necessary
    after_create_account do
      create_omniauth_identity_if_needed

      session.delete(:account_step)
      session.delete(:account_params)
      session.delete(:omniauth_data)
    end

    # ==> Redirects
    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }

    # ==> Deadlines
    # Change default deadlines for some actions.
    # verify_account_grace_period 3.days.to_i
    # reset_password_deadline_interval Hash[hours: 6]
    # verify_login_change_deadline_interval Hash[days: 2]
    # remember_deadline_interval Hash[days: 30]

    # ==> Helper methods and implementations
    auth_class_eval do
      def validate_user_details
        validate_required_fields([ "firstname", "lastname", "day_of_birth", "month_of_birth", "year_of_birth", "sex", "municipality_id", "street_name" ])

        validate_and_set_birthdate
        validate_and_set_address

        account[:firstname] = param_or_nil("firstname")
        account[:lastname] = param_or_nil("lastname")
        account[:sex] = param_or_nil("sex")
      end

      def find_or_create_street(municipality, street_name)
        street_name = street_name.strip
        street = municipality.streets.find_by(name: street_name)

        unless street
          street = Street.create!(
            municipality: municipality,
            name: street_name,
            tested: false
          )
        end

        street
      end

      def account_from_omniauth
        unless omniauth_auth && omniauth_auth["provider"] && omniauth_auth["uid"]
          return nil
        end

        provider_value = omniauth_auth["provider"].to_s
        uid_value = omniauth_auth["uid"].to_s

        identity_query = "SELECT * FROM #{db.literal(omniauth_identities_table)} WHERE #{db.literal(omniauth_identities_provider_column)} = #{db.literal(provider_value)} AND #{db.literal(omniauth_identities_uid_column)} = #{db.literal(uid_value)}"
        identity = db.fetch(identity_query).first

        if identity
          return account_ds.where(account_id_column => identity[omniauth_identities_account_id_column]).first
        end

        if omniauth_auth["info"] && omniauth_auth["info"]["email"]
          account = _account_from_login(omniauth_auth["info"]["email"])

          if account
            return account
          end
        end

        handle_new_omniauth_user
        nil
      end

      def handle_omniauth_data
        info = omniauth_auth["info"] || {}
        email = info["email"]

        first_name = info["first_name"]
        last_name = info["last_name"]
        name = info["name"]

        if name && (!first_name || !last_name)
          name_parts = name.split(" ")
          first_name ||= name_parts.first
          last_name ||= name_parts.count > 1 ? name_parts.last : ""
        end

        first_name ||= ""
        last_name ||= ""

        session[:omniauth_data] = {
          "provider" => omniauth_auth["provider"],
          "uid" => omniauth_auth["uid"],
          "email" => email
        }

        session[:account_step] = 2

        session[:account_params] = {
          login_param.to_s => email,
          "firstname" => first_name,
          "lastname" => last_name
        }
      end

      def create_omniauth_identity_if_needed
        if request.params["omniauth_provider"] && request.params["omniauth_uid"]
          provider = request.params["omniauth_provider"]
          uid = request.params["omniauth_uid"]

          db[omniauth_identities_table].insert(
            omniauth_identities_account_id_column => account_id,
            omniauth_identities_provider_column => provider,
            omniauth_identities_uid_column => uid
          )
        end
      end

      def handle_registration_steps
        session[:account_step] ||= 1

        if request.post?
          if param_or_nil("previous_step")
            handle_previous_step
          elsif param_or_nil("next_step")
            handle_next_step
          elsif param_or_nil("create_account")
            handle_final_step
          end
        end
      end

      def validate_address_step
        valid = true

        if param_or_nil("municipality_id").to_s.empty?
          set_field_error(:municipality_id, "Municipality is required")
          valid = false
        else
          municipality_id = param_or_nil("municipality_id")
          unless Municipality.exists?(municipality_id)
            set_field_error(:municipality_id, "Municipality not found")
            valid = false
          end
        end

        if param_or_nil("street_name").to_s.empty?
          set_field_error(:street_name, "Street is required")
          valid = false
        end

        valid
      end

      private

      def handle_previous_step
        if session[:omniauth_data] && session[:account_step] == 2
          session[:account_params] ||= {}
          session[:account_params].merge!(create_account_step_params)
          redirect create_account_path
        else
          session[:account_step] = [ session[:account_step] - 1, 1 ].max
          session[:account_params] ||= {}
          session[:account_params].merge!(create_account_step_params)
          redirect create_account_path
        end
      end

      def handle_next_step
        session[:account_params] ||= {}
        session[:account_params].merge!(create_account_step_params)

        is_valid = true
        case session[:account_step]
        when 1
          is_valid = validate_account_details_step
        when 2
          is_valid = validate_personal_info_step
        end

        if is_valid
          session[:account_step] += 1
          redirect create_account_path
        end
      end

      def handle_final_step
        session[:account_params] ||= {}
        session[:account_params].merge!(create_account_step_params)

        return unless validate_address_step

        transfer_session_params_to_request

        handle_omniauth_user_final_step if session[:omniauth_data]
      end

      def transfer_session_params_to_request
        session[:account_params].each do |key, value|
          next if value.nil?
          next if (key.to_s == password_param.to_s || key.to_s == password_confirm_param.to_s) &&
                  param_or_nil(key).to_s.length > 0

          request.params[key.to_s] = value
        end
      end

      def handle_omniauth_user_final_step
        provider = session[:omniauth_data]["provider"]
        uid = session[:omniauth_data]["uid"]

        request.params["omniauth_provider"] = provider
        request.params["omniauth_uid"] = uid

        unless param_or_nil(password_param)
          random_password = SecureRandom.hex(16)
          request.params[password_param.to_s] = random_password
          request.params[password_confirm_param.to_s] = random_password if require_password_confirmation?
        end
      end

      def validate_required_fields(fields)
        fields.each do |field|
          unless value = param_or_nil(field)
            throw_error_status(422, field, "must be present")
          end
        end
      end

      def validate_and_set_birthdate
        day = param_or_nil("day_of_birth")
        month = param_or_nil("month_of_birth")
        year = param_or_nil("year_of_birth")

        begin
          birthdate = Date.new(year.to_i, month.to_i, day.to_i)
          account[:birth] = birthdate
        rescue ArgumentError
          throw_error_status(422, "day_of_birth", "Invalid date")
        end
      end

      def validate_and_set_address
        municipality_id = param_or_nil("municipality_id")
        street_name = param_or_nil("street_name")

        municipality = Municipality.find_by(id: municipality_id)
        unless municipality
          throw_error_status(422, "municipality_id", "Municipality not found")
        end

        street = find_or_create_street(municipality, street_name)

        account[:municipality_id] = municipality.id
        account[:street_id] = street.id
      end

      def handle_new_omniauth_user
        begin
          email = omniauth_auth.dig("info", "email")
          provider = omniauth_auth["provider"]
          uid = omniauth_auth["uid"]

          unless email && provider && uid
            return
          end

          info = omniauth_auth["info"] || {}
          first_name = info["first_name"]
          last_name = info["last_name"]

          if (!first_name || !last_name) && info["name"]
            name_parts = info["name"].to_s.split(" ")
            first_name ||= name_parts.first
            last_name ||= name_parts.count > 1 ? name_parts.last : ""
          end

          first_name ||= ""
          last_name ||= ""

          session[:omniauth_data] = {
            "provider" => provider,
            "uid" => uid,
            "email" => email,
            "first_name" => first_name,
            "last_name" => last_name
          }

          session[:account_step] = 2

          session[:account_params] = {
            login_param.to_s => email,
            "firstname" => first_name,
            "lastname" => last_name
          }

          redirect create_account_path
        end
      end

      def create_account_step_params
        params = {}

        params[login_param] = param_or_nil(login_param) if param_or_nil(login_param)
        params[login_confirm_param] = param_or_nil(login_confirm_param) if param_or_nil(login_confirm_param)

        if param_or_nil(password_param) && !param_or_nil(password_param).to_s.empty?
          params[password_param] = param_or_nil(password_param)
        end

        if param_or_nil(password_confirm_param) && !param_or_nil(password_confirm_param).to_s.empty?
          params[password_confirm_param] = param_or_nil(password_confirm_param)
        end

        %w[firstname lastname day_of_birth month_of_birth year_of_birth sex].each do |key|
          value = param_or_nil(key)
          params[key] = value if value
        end

        %w[municipality_id street_name].each do |key|
          value = param_or_nil(key)
          params[key] = value if value
        end

        params
      end

      def validate_account_details_step
        valid = true

        login_value = param_or_nil(login_param)
        if login_value.to_s.empty?
          set_field_error(login_param, "Email is required")
          valid = false
        elsif !login_value.to_s.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
          set_field_error(login_param, "Invalid email format")
          valid = false
        end

        if require_login_confirmation?
          login_confirm_value = param_or_nil(login_confirm_param)
          if login_confirm_value.to_s.empty?
            set_field_error(login_confirm_param, "Email confirmation is required")
            valid = false
          elsif login_confirm_value != login_value
            set_field_error(login_confirm_param, "Email confirmation doesn't match")
            valid = false
          end
        end

        if param_or_nil(password_param).to_s.empty?
          set_field_error(password_param, "Password is required")
          valid = false
        end

        if require_password_confirmation?
          if param_or_nil(password_confirm_param).to_s.empty?
            set_field_error(password_confirm_param, "Password confirmation is required")
            valid = false
          elsif param_or_nil(password_confirm_param) != param_or_nil(password_param)
            set_field_error(password_confirm_param, "Password confirmation doesn't match")
            valid = false
          end
        end

        valid
      end

      def validate_personal_info_step
        valid = true

        if param_or_nil("firstname").to_s.empty?
          set_field_error(:firstname, "First name is required")
          valid = false
        end

        if param_or_nil("lastname").to_s.empty?
          set_field_error(:lastname, "Last name is required")
          valid = false
        end

        day = param_or_nil("day_of_birth")
        if day.to_s.empty?
          set_field_error(:day_of_birth, "Day is required")
          valid = false
        elsif !day.to_s.match?(/^\d+$/) || day.to_i < 1 || day.to_i > 31
          set_field_error(:day_of_birth, "Day must be between 1 and 31")
          valid = false
        end

        month = param_or_nil("month_of_birth")
        if month.to_s.empty?
          set_field_error(:month_of_birth, "Month is required")
          valid = false
        elsif !month.to_s.match?(/^\d+$/) || month.to_i < 1 || month.to_i > 12
          set_field_error(:month_of_birth, "Month must be between 1 and 12")
          valid = false
        end

        year = param_or_nil("year_of_birth")
        if year.to_s.empty?
          set_field_error(:year_of_birth, "Year is required")
          valid = false
        elsif !year.to_s.match?(/^\d+$/) || year.to_i < 1900 || year.to_i > Date.today.year
          set_field_error(:year_of_birth, "Year must be between 1900 and #{Date.today.year}")
          valid = false
        end

        if valid && day && month && year
          begin
            Date.new(year.to_i, month.to_i, day.to_i)
          rescue ArgumentError
            set_field_error(:day_of_birth, "Invalid date combination")
            valid = false
          end
        end

        if param_or_nil("sex").to_s.empty?
          set_field_error(:sex, "Gender selection is required")
          valid = false
        end

        valid
      end
    end
  end
end
