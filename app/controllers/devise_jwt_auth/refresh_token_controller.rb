# frozen_string_literal: true

module DeviseJwtAuth
  # Controller that handles sending refresh tokens.
  class RefreshTokenController < DeviseJwtAuth::ApplicationController
    before_action :set_user_by_refresh_token

    def show
      if @resource
        yield @resource if block_given?
        render_refresh_token_success
      else
        render_refresh_token_error
      end
    end

    protected

    def resource_data
      response_data = @resource.as_json
      response_data['type'] = @resource.class.name.parameterize if json_api?
      response_data
    end

    def render_refresh_token_success
      response_data = {
        status: 'success',
        data: resource_data
      }

      response_data.merge!(@resource.create_named_token_pair) if active_for_authentication?

      render json: response_data
    end

    def render_refresh_token_error
      render_error(401, I18n.t('devise_jwt_auth.token_validations.invalid'))
    end

    def active_for_authentication?
      !@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?
    end
  end
end
