# frozen_string_literal: true

require 'test_helper'

class DeviseJwtAuth::RefreshTokenControllerTest < ActionDispatch::IntegrationTest
  describe DeviseJwtAuth::RefreshTokenController do
    describe 'confirmed user' do
      before do
        @resource = create(:user, :confirmed)
        @auth_headers = get_cookie_header(DeviseJwtAuth.refresh_token_name,
                                          @resource.create_refresh_token)
        get '/auth/refresh_token', params: {}, headers: @auth_headers
        @resp = JSON.parse(response.body)
      end

      test 'response valid' do
        assert_equal 200, response.status
      end

      test 'should return access token' do
        assert @resp[DeviseJwtAuth.access_token_name]
      end
    end

    describe 'unconfirmed user' do
      before do
        @resource = create(:user)
        @auth_headers = get_cookie_header(DeviseJwtAuth.refresh_token_name,
                                          @resource.create_refresh_token)
        get '/auth/refresh_token', params: {}, headers: @auth_headers
        @resp = JSON.parse(response.body)
      end

      test 'response valid' do
        assert_equal 200, response.status
      end

      test 'should not return access token' do
        assert_nil @resp[DeviseJwtAuth.access_token_name]
      end
    end

    describe 'an expired token' do
      before do
        @resource = create(:user, :confirmed)
        @exp = (Time.now - 1.hour).to_i
        @expired_token = @resource.create_refresh_token(exp: @exp)
        @auth_headers = get_cookie_header(DeviseJwtAuth.refresh_token_name,
                                          @expired_token)
        get '/auth/refresh_token', params: {}, headers: @auth_headers
        @resp = JSON.parse(response.body)
      end

      it 'response error' do
        assert_equal 401, response.status
      end

      it 'should not return access token' do
        assert_nil @resp[DeviseJwtAuth.access_token_name]
      end
    end

    describe 'an invalid refresh token' do
      before do
        @auth_headers = get_cookie_header(DeviseJwtAuth.refresh_token_name,
                                          'invalid-token')
        get '/auth/refresh_token', params: {}, headers: @auth_headers
        @resp = JSON.parse(response.body)
      end

      it 'response error' do
        assert_equal 401, response.status
      end

      it 'should not return access token' do
        assert_nil @resp[DeviseJwtAuth.access_token_name]
      end
    end
  end
end
