# frozen_string_literal: true

require 'test_helper'

class Custom::RefreshTokenControllerTest < ActionDispatch::IntegrationTest
  describe Custom::RefreshTokenController do
    include CustomControllersRoutes

    before do
      DeviseJwtAuth.default_refresh_token_path = '/nice_user_auth/refresh_token'
      @resource = create(:user, :confirmed)
      @auth_headers = get_cookie_header(DeviseJwtAuth.refresh_token_name,
                                        @resource.create_refresh_token)
    end

    teardown do
      DeviseJwtAuth.default_refresh_token_path = '/auth/refresh_token'
    end

    test 'yield resource to block on refresh_token success' do
      get DeviseJwtAuth.default_refresh_token_path, params: {}, headers: @auth_headers
      assert @controller.refresh_token_block_called?,
             'refresh_token failed to yield resource to provided block'
    end

    test 'yield resource to block on refresh_token success with custom json' do
      get DeviseJwtAuth.default_refresh_token_path, params: {}, headers: @auth_headers

      @data = JSON.parse(response.body)

      assert @controller.refresh_token_block_called?,
             'refresh_token failed to yield resource to provided block'
      assert_equal @data['custom'], 'foo'
    end
  end
end
