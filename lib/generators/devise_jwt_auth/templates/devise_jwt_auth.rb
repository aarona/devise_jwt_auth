# frozen_string_literal: true

DeviseJwtAuth.setup do |config|
  # By default, you will only receive an access token when authenticating a
  # user. To receive new access tokens, you should either reauthenticate or
  # use the HTTP only refresh cookie that is sent during the authentication
  # process and make refresh token requests.
  # config.send_new_access_token_on_each_request = false
  
  # By default, refresh token HTTP Only cookies last for 2 weeks. These tokens
  # are used for requesting shorter-lived acccess tokens.
  # config.refresh_token_lifespan = 2.weeks

  # By default, access tokens last for 15 minutes. These tokens are used to
  # access protected resources. When these tokens expire, you need to
  # reauthenticate the user or use a refresh token cookie to get a new access
  # token.
  # config.access_token_lifespan = 15.minutes

  # This is the name of the HTTP Only cookie that will be sent to the client
  # for the purpose of requesting new access tokens.
  # config.refresh_token_name = 'refresh-token'

  # This is the name of the token that will be sent in the JSON responses used
  # for accessing protected resources. NEVER store this token in a cookie or
  # any form of local storage on the client. Save it in memory as a javascript
  # variable or in some kind of context manager like Redux. Send it in your
  # request headers when you want to be authenticated.
  # config.access_token_name = 'access-token'

  # This is the refresh token encryption key. You should set this in an
  # environment variable or secret key base that isn't store in a repository.
  # Also, its a good idea to NOT use the same key for access tokens.
  config.refresh_token_encryption_key = 'your-refresh-token-secret-key-here'
  
  # This is the refresh token encryption key. You should set this in an
  # environment variable or secret key base that isn't store in a repository.
  # Also, its a good idea to NOT use the same key for access tokens.
  config.access_token_encryption_key = 'your-access-token-secret-key-here'

  # This route will be the prefix for all oauth2 redirect callbacks. For
  # example, using the default '/omniauth', the github oauth2 provider will
  # redirect successful authentications to '/omniauth/github/callback'
  # config.omniauth_prefix = "/omniauth"

  # By default sending current password is not needed for the password update.
  # Uncomment to enforce current_password param to be checked before all
  # attribute updates. Set it to :password if you want it to be checked only if
  # password is updated.
  # config.check_current_password_before_update = :attributes

  # By default we will use callbacks for single omniauth.
  # It depends on fields like email, provider and uid.
  # config.default_callbacks = true

  # By default, only Bearer Token authentication is implemented out of the box.
  # If, however, you wish to integrate with legacy Devise authentication, you can
  # do so by enabling this flag. NOTE: This feature is highly experimental!
  # config.enable_standard_devise_support = false

  # By default DeviseJwtAuth will not send confirmation email, even when including
  # devise confirmable module. If you want to use devise confirmable module and
  # send email, set it to true. (This is a setting for compatibility)
  # config.send_confirmation_email = true

  # TODO: Document these settings
  # config.default_confirm_success_url               = nil
  # config.default_password_reset_url                = nil
  # config.redirect_whitelist                        = nil
  # config.update_token_version_after_password_reset = true
  # config.bypass_sign_in                            = true
  # config.require_client_password_reset_token       = false

end
