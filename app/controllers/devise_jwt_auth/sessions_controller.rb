# frozen_string_literal: true

module DeviseJwtAuth
  class SessionsController < DeviseJwtAuth::ApplicationController
    before_action :set_user_by_token, only: [:destroy]
    after_action :reset_session, only: [:destroy]

    def new
      render_new_error
    end

    def create
      # Check
      field = (resource_params.keys.map(&:to_sym) & resource_class.authentication_keys).first

      @resource = nil
      if field
        q_value = get_case_insensitive_field_from_resource_params(field)

        @resource = find_resource(field, q_value)
      end

      if @resource &&
         valid_params?(field, q_value) &&
         (!@resource.respond_to?(:active_for_authentication?) ||
          @resource.active_for_authentication?)
        valid_password = @resource.valid_password?(resource_params[:password])
        if (@resource.respond_to?(:valid_for_authentication?) &&
           !@resource.valid_for_authentication? { valid_password }) ||
           !valid_password
          return render_create_error_bad_credentials
        end

        @token = @resource.create_token
        @resource.save

        sign_in(:user, @resource, store: false, bypass: false)

        yield @resource if block_given?

        update_refresh_token_cookie
        render_create_success
      elsif @resource &&
            !(!@resource.respond_to?(:active_for_authentication?) ||
              @resource.active_for_authentication?)
        if @resource.respond_to?(:locked_at) && @resource.locked_at
          render_create_error_account_locked
        else
          render_create_error_not_confirmed
        end
      else
        render_create_error_bad_credentials
      end
    end

    def destroy
      # TODO: logout? update token version?

      # remove auth instance variables so that after_action does not run
      user = remove_instance_variable(:@resource) if @resource

      if user
        yield user if block_given?
        clear_refresh_token_cookie
        render_destroy_success
      else
        render_destroy_error
      end
    end

    protected

    def valid_params?(key, val)
      resource_params[:password] && key && val
    end

    def get_auth_params
      auth_key = nil
      auth_val = nil

      # iterate thru allowed auth keys, use first found
      resource_class.authentication_keys.each do |k|
        next unless resource_params[k]

        auth_val = resource_params[k]
        auth_key = k
        break
      end

      # honor devise configuration for case_insensitive_keys
      auth_val.downcase! if resource_class.case_insensitive_keys.include?(auth_key)

      { key: auth_key, val: auth_val }
    end

    def render_new_error
      render_error(405, I18n.t('devise_jwt_auth.sessions.not_supported'))
    end

    def render_create_success
      auth_header = @resource.create_named_token_pair
      render json: {
        data: resource_data(resource_json: @resource.token_validation_response)
      }.merge(auth_header)
    end

    def render_create_error_not_confirmed
      render_error(401, I18n.t('devise_jwt_auth.sessions.not_confirmed', email: @resource.email))
    end

    def render_create_error_account_locked
      render_error(401, I18n.t('devise.mailer.unlock_instructions.account_lock_msg'))
    end

    def render_create_error_bad_credentials
      render_error(401, I18n.t('devise_jwt_auth.sessions.bad_credentials'))
    end

    def render_destroy_success
      render json: {
        success: true
      }, status: 200
    end

    def render_destroy_error
      render_error(404, I18n.t('devise_jwt_auth.sessions.user_not_found'))
    end

    private

    def resource_params
      params.permit(*params_for_resource(:sign_in))
    end
  end
end
