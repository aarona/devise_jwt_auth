# frozen_string_literal: true

require 'devise_jwt_auth/rails/routes'

module DeviseJwtAuth
  class Engine < ::Rails::Engine
    isolate_namespace DeviseJwtAuth

    initializer 'devise_jwt_auth.url_helpers' do
      Devise.helpers << DeviseJwtAuth::Controllers::Helpers
    end
  end

  mattr_accessor :send_new_access_token_on_each_request,
                 :refresh_token_lifespan,
                 :access_token_lifespan,
                 :refresh_token_name,
                 :access_token_name,
                 :refresh_token_encryption_key,
                 :access_token_encryption_key,
                 :batch_request_buffer_throttle,
                 :omniauth_prefix,
                 :default_confirm_success_url,
                 :default_password_reset_url,
                 :redirect_whitelist,
                 :check_current_password_before_update,
                 :enable_standard_devise_support,
                 :update_token_version_after_password_reset,
                 :default_callbacks,
                 :bypass_sign_in,
                 :send_confirmation_email,
                 :require_client_password_reset_token

  self.send_new_access_token_on_each_request     = false
  self.refresh_token_lifespan                    = 1.week
  self.access_token_lifespan                     = 15.minutes
  self.refresh_token_name                        = 'refresh-token'
  self.access_token_name                         = 'access-token'
  self.refresh_token_encryption_key              = 'your-refresh-token-secret-key-here'
  self.access_token_encryption_key               = 'your-access-token-secret-key-here'
  self.batch_request_buffer_throttle             = 5.seconds
  self.omniauth_prefix                           = '/omniauth'
  self.default_confirm_success_url               = nil
  self.default_password_reset_url                = nil
  self.redirect_whitelist                        = nil
  self.check_current_password_before_update      = false
  self.enable_standard_devise_support            = false
  self.update_token_version_after_password_reset = true
  self.default_callbacks                         = true
  self.bypass_sign_in                            = true
  self.send_confirmation_email                   = false
  self.require_client_password_reset_token       = false

  def self.setup
    yield self

    Rails.application.config.after_initialize do
      if defined?(::OmniAuth)
        ::OmniAuth.config.path_prefix = Devise.omniauth_path_prefix = omniauth_prefix

        # Omniauth currently does not pass along omniauth.params upon failure redirect
        # see also: https://github.com/intridea/omniauth/issues/626
        OmniAuth::FailureEndpoint.class_eval do
          def redirect_to_failure
            message_key = env['omniauth.error.type']
            origin_query_param = env['omniauth.origin'] ? "&origin=#{CGI.escape(env['omniauth.origin'])}" : ''
            strategy_name_query_param = env['omniauth.error.strategy'] ? "&strategy=#{env['omniauth.error.strategy'].name}" : ''
            extra_params = env['omniauth.params'] ? "&#{env['omniauth.params'].to_query}" : ''
            new_path = "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/failure?message=#{message_key}#{origin_query_param}#{strategy_name_query_param}#{extra_params}"
            Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
          end
        end

        # Omniauth currently removes omniauth.params during mocked requests
        # see also: https://github.com/intridea/omniauth/pull/812
        OmniAuth::Strategy.class_eval do
          def mock_callback_call
            setup_phase
            @env['omniauth.origin'] = session.delete('omniauth.origin')
            @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
            @env['omniauth.params'] = session.delete('omniauth.params') || {}
            mocked_auth = OmniAuth.mock_auth_for(name.to_s)
            if mocked_auth.is_a?(Symbol)
              fail!(mocked_auth)
            else
              @env['omniauth.auth'] = mocked_auth
              OmniAuth.config.before_callback_phase&.call(@env)
              call_app!
            end
          end
        end

      end
    end
  end
end
