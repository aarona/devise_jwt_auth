# frozen_string_literal: true

module DeviseJwtAuth
  class UnlocksController < DeviseJwtAuth::ApplicationController
    # skip_after_action :update_auth_header, only: [:create, :show]

    # this action is responsible for generating unlock tokens and
    # sending emails
    def create
      return render_create_error_missing_email unless resource_params[:email]

      @email = get_case_insensitive_field_from_resource_params(:email)
      @resource = find_resource(:email, @email)

      if @resource
        yield @resource if block_given?

        @resource.send_unlock_instructions(
          email: @email,
          provider: 'email',
          client_config: params[:config_name]
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

    def show
      @resource = resource_class.unlock_access_by_token(params[:unlock_token])

      if @resource.persisted?
        yield @resource if block_given?

        redirect_header_options = { unlock: true }
        redirect_headers = @resource.create_named_token_pair
                             .merge(redirect_header_options)

        update_refresh_token_cookie
        redirect_url = after_unlock_path_for(@resource)
        redirect_to_link = DeviseJwtAuth::Url.generate(redirect_url, redirect_headers)

        redirect_to redirect_to_link
      else
        render_show_error
      end
    end

    private

    def after_unlock_path_for(_resource)
      # TODO: This should probably be a configuration option at the very least.
      # Use confirmation controller / tests as a template for building out this feature.
      '/'
    end

    def render_create_error_missing_email
      render_error(401, I18n.t('devise_jwt_auth.unlocks.missing_email'))
    end

    def render_create_success
      render json: {
        success: true,
        message: I18n.t('devise_jwt_auth.unlocks.sended', email: @email)
      }
    end

    def render_create_error(errors)
      render json: {
        success: false,
        errors: errors
      }, status: 400
    end

    def render_show_error
      raise ActionController::RoutingError, 'Not Found'
    end

    def render_not_found_error
      render_error(404, I18n.t('devise_jwt_auth.unlocks.user_not_found', email: @email))
    end

    def resource_params
      params.permit(:email, :unlock_token, :config)
    end
  end
end
