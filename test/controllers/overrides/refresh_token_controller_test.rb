# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class Overrides::RefreshTokenControllerTest < ActionDispatch::IntegrationTest
  include OverridesControllersRoutes

  describe Overrides::RefreshTokenController do
    before do
      DeviseJwtAuth.default_refresh_token_path = '/evil_user_auth/refresh_token'

      @resource = create(:user, :confirmed)
      @auth_headers = get_cookie_header(DeviseJwtAuth.refresh_token_name,
                                        @resource.create_refresh_token)

      get DeviseJwtAuth.default_refresh_token_path, params: {}, headers: @auth_headers

      @resp = JSON.parse(response.body)
    end

    teardown do
      DeviseJwtAuth.default_refresh_token_path = '/auth/refresh_token'
    end

    test 'response valid' do
      assert_equal 200, response.status
    end

    test 'controller was overridden' do
      assert_equal Overrides::RefreshTokenController::OVERRIDE_PROOF,
                   @resp['override_proof']
    end
  end
end
