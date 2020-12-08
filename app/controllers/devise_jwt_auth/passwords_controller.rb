# frozen_string_literal: true

module DeviseJwtAuth
  class PasswordsController < DeviseJwtAuth::ApplicationController
    before_action :validate_redirect_url_param, only: [:create, :edit]

    # This action is responsible for generating password reset tokens and sending emails
    def create
      return render_create_error_missing_email unless resource_params[:email]

      @email = get_case_insensitive_field_from_resource_params(:email)
      @resource = find_resource(:uid, @email)

      if @resource
        yield @resource if block_given?
        @resource.send_reset_password_instructions(
          email: @email,
          provider: 'email',
          redirect_url: @redirect_url
        )

        if @resource.errors.empty?
          render_create_success
        else
          render_create_error @resource.errors
        end
      else
        render_not_found_error
      end
    end

    # This is where users arrive after visiting the password reset confirmation link.
    def edit
      @resource = resource_class.with_reset_password_token(resource_params[:reset_password_token])

      if @resource&.reset_password_period_valid?
        # ensure that user is confirmed
        @resource.skip_confirmation! if confirmable_enabled? && !@resource.confirmed_at

        # allow user to change password once without current_password
        @resource.allow_password_change = true if recoverable_enabled?
        @resource.save!

        yield @resource if block_given?

        if require_client_password_reset_token?
          clear_refresh_token_cookie

          redirect_to DeviseJwtAuth::Url.generate(
            @redirect_url,
            reset_password_token: resource_params[:reset_password_token]
          )
        else
          # TODO: do we put the refresh token here?
          update_refresh_token_cookie
          redirect_to @redirect_url
        end
      else
        render_edit_error
      end
    end

    def update
      # Make sure user is authorized. Either by a reset_password_token or a valid access token.
      if require_client_password_reset_token? && resource_params[:reset_password_token]
        @resource = resource_class.with_reset_password_token(resource_params[:reset_password_token])

        return render_update_error_unauthorized unless @resource
      else
        @resource = set_user_by_token
      end

      return render_update_error_unauthorized unless @resource

      # make sure account doesn't use oauth2 provider
      return render_update_error_password_not_required unless @resource.provider == 'email'

      # ensure that password params were sent
      unless password_resource_params[:password] && password_resource_params[:password_confirmation]
        return render_update_error_missing_password
      end

      if @resource.send(resource_update_method, password_resource_params)
        @resource.allow_password_change = false if recoverable_enabled?
        @resource.save!

        yield @resource if block_given?
        # invalidate old tokens
        # send refresh cookie
        # send access token
        update_refresh_token_cookie
        render_update_success
      else
        render_update_error
      end
    end

    protected

    def resource_update_method
      allow_password_change =
        recoverable_enabled? &&
        @resource.allow_password_change == true ||
        require_client_password_reset_token?

      if DeviseJwtAuth.check_current_password_before_update == false || allow_password_change
        'update'
      else
        'update_with_password'
      end
    end

    def render_create_error_missing_email
      render_error(401, I18n.t('devise_jwt_auth.passwords.missing_email'))
    end

    def render_create_error_missing_redirect_url
      render_error(401, I18n.t('devise_jwt_auth.passwords.missing_redirect_url'))
    end

    def render_error_not_allowed_redirect_url
      response = {
        status: 'error',
        data: resource_data
      }
      message = I18n.t('devise_jwt_auth.passwords.not_allowed_redirect_url',
                       redirect_url: @redirect_url)
      render_error(422, message, response)
    end

    def render_create_success
      render json: {
        success: true,
        message: I18n.t('devise_jwt_auth.passwords.sended', email: @email)
      }
    end

    def render_create_error(errors)
      render json: {
        success: false,
        errors: errors
      }, status: 400
    end

    def render_edit_error
      raise ActionController::RoutingError, 'Not Found'
    end

    def render_update_error_unauthorized
      render_error(401, 'Unauthorized')
    end

    def render_update_error_password_not_required
      render_error(422, I18n.t('devise_jwt_auth.passwords.password_not_required',
                               provider: @resource.provider.humanize))
    end

    def render_update_error_missing_password
      render_error(422, I18n.t('devise_jwt_auth.passwords.missing_passwords'))
    end

    def render_update_success
      response_body = {
        success: true,
        data: resource_data,
        message: I18n.t('devise_jwt_auth.passwords.successfully_updated')
      }.merge!(@resource.create_named_token_pair)

      render json: response_body
    end

    def render_update_error
      render json: {
        success: false,
        errors: resource_errors
      }, status: 422
    end

    private

    def resource_params
      params.permit(:email, :reset_password_token)
    end

    def password_resource_params
      params.permit(*params_for_resource(:account_update))
    end

    def render_not_found_error
      render_error(404, I18n.t('devise_jwt_auth.passwords.user_not_found', email: @email))
    end

    def validate_redirect_url_param
      # give redirect value from params priority
      @redirect_url = params.fetch(
        :redirect_url,
        DeviseJwtAuth.default_password_reset_url
      )

      return render_create_error_missing_redirect_url unless @redirect_url

      render_error_not_allowed_redirect_url if blacklisted_redirect_url?(@redirect_url)
    end

    def reset_password_token_as_raw?(recoverable)
      recoverable &&
        recoverable.reset_password_token.present? &&
        !require_client_password_reset_token?
    end

    def require_client_password_reset_token?
      DeviseJwtAuth.require_client_password_reset_token
    end
  end
end
