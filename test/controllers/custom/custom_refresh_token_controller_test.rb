# frozen_string_literal: true

require 'test_helper'

class Custom::RefreshTokenControllerTest < ActionDispatch::IntegrationTest
  describe Custom::RefreshTokenController do
    include CustomControllersRoutes

    before do
      @resource = create(:user, :confirmed)
      @auth_headers = get_cookie_header(DeviseJwtAuth.refresh_token_name,
                                        @resource.create_refresh_token)
    end

    test 'yield resource to block on refresh_token success' do
      get '/nice_user_auth/refresh_token',
          params: {},
          headers: @auth_headers
      assert @controller.refresh_token_block_called?,
             'refresh_token failed to yield resource to provided block'
    end

    test 'yield resource to block on refresh_token success with custom json' do
      get '/nice_user_auth/refresh_token',
          params: {},
          headers: @auth_headers

      @data = JSON.parse(response.body)

      assert @controller.refresh_token_block_called?,
             'refresh_token failed to yield resource to provided block'
      assert_equal @data['custom'], 'foo'
    end
  end
end
