# frozen_string_literal: true

module DeviseJwtAuth::Concerns::SetUserByToken
  extend ActiveSupport::Concern
  include DeviseJwtAuth::Concerns::ResourceFinder

  included do
  end

  protected

  def set_user_by_token(mapping = nil)
    # determine target authentication class
    rc = resource_class(mapping)

    # no default user defined
    return unless rc

    # check for an existing user, authenticated via warden/devise, if enabled
    if DeviseJwtAuth.enable_standard_devise_support
      devise_warden_user = warden.user(rc.to_s.underscore.to_sym)
      @resource = devise_warden_user if devise_warden_user
    end

    # user has already been found and authenticated
    return @resource if @resource.is_a?(rc)

    # TODO: Look for the access token in an 'Authentication' header
    token = request.headers[DeviseJwtAuth.access_token_name]
    return unless token

    payload = DeviseJwtAuth::TokenFactory.decode_access_token(token)
    return if payload.empty?
    return if payload && payload['sub'].blank?

    uid = payload['sub']

    # mitigate timing attacks by finding by uid instead of auth token
    user = uid && rc.dta_find_by(uid: uid)
    scope = rc.to_s.underscore.to_sym

    if user
      # sign_in with bypass: true will be deprecated in the next version of Devise
      if respond_to?(:bypass_sign_in) && DeviseJwtAuth.bypass_sign_in
        bypass_sign_in(user, scope: scope)
      else
        sign_in(scope, user, store: false, event: :fetch, bypass: DeviseJwtAuth.bypass_sign_in)
      end
      @resource = user
    else
      # zero all values previously set values
      @resource = nil
    end
  end

  def set_user_by_refresh_token(mapping = nil)
    # determine target authentication class
    rc = resource_class(mapping)

    # no default user defined
    return unless rc

    # check for an existing user, authenticated via warden/devise, if enabled
    if DeviseJwtAuth.enable_standard_devise_support
      devise_warden_user = warden.user(rc.to_s.underscore.to_sym)
      @resource = devise_warden_user if devise_warden_user
    end

    # user has already been found and authenticated
    return @resource if @resource.is_a?(rc)

    token = request.cookies[DeviseJwtAuth.refresh_token_name]

    return unless token

    payload = DeviseJwtAuth::TokenFactory.decode_refresh_token(token)
    return if payload.empty?
    return if payload && payload['sub'].blank?

    uid = payload['sub']

    # mitigate timing attacks by finding by uid instead of auth token
    user = uid && rc.dta_find_by(uid: uid)
    scope = rc.to_s.underscore.to_sym

    if user
      # sign_in with bypass: true will be deprecated in the next version of Devise
      if respond_to?(:bypass_sign_in) && DeviseJwtAuth.bypass_sign_in
        bypass_sign_in(user, scope: scope)
      else
        sign_in(scope, user, store: false, event: :fetch, bypass: DeviseJwtAuth.bypass_sign_in)
      end
      @resource = user
    else
      # zero all values previously set values
      @resource = nil
    end
  end

  def update_refresh_token_cookie
    response.set_cookie(DeviseJwtAuth.refresh_token_name,
                        value: @resource.create_refresh_token,
                        path: '/auth/refresh_token', # TODO: Use configured auth path
                        expires: Time.zone.now + DeviseJwtAuth.refresh_token_lifespan,
                        httponly: true,
                        secure: Rails.env.production?)
  end

  def clear_refresh_token_cookie
    response.set_cookie(DeviseJwtAuth.refresh_token_name,
                        value: '',
                        path: '/auth/refresh_token', # TODO: Use configured auth path
                        expires: Time.zone.now)
  end
end
