# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DemoUserControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  describe DemoUserController do
    describe 'Token access' do
      before do
        @resource = create(:user, :confirmed)
        @auth_headers = @resource.create_named_token_pair
      end

      describe 'successful request' do
        before do
          get '/demo/members_only',
              params: {},
              headers: @auth_headers
        end

        describe 'devise mappings' do
          it 'should define current_user' do
            assert_equal @resource, @controller.current_user
          end

          it 'should define user_signed_in?' do
            assert @controller.user_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @resource, @controller.current_mang
          end

          it 'should define render_authenticate_error' do
            assert @controller.methods.include?(:render_authenticate_error)
          end
        end

        it 'should return success status' do
          assert_equal 200, response.status
        end
      end

      describe 'failed request' do
        before do
          get '/demo/members_only',
              params: {},
              headers: @auth_headers.merge('access-token' => 'bogus')
        end

        it 'should not return any auth headers' do
          refute response.headers['access-token']
        end

        it 'should return error: unauthorized status' do
          assert_equal 401, response.status
        end
      end

      describe 'successful password change' do
        before do
          # adding one more token to simulate another logged in device
          @old_auth_headers = @auth_headers
          @auth_headers = @resource.create_named_token_pair

          # password changed from new device
          @resource.update(password: 'newsecret123',
                           password_confirmation: 'newsecret123')

          get '/demo/members_only',
              params: {},
              headers: @auth_headers
        end

        it 'new request should be successful' do
          assert 200, response.status
        end

        describe 'another device should not be able to login' do
          it 'should return forbidden status' do
            get '/demo/members_only',
                params: {},
                headers: @old_auth_headers
            assert 401, response.status
          end
        end
      end

      describe 'when access-token name has been changed' do
        before do
          DeviseJwtAuth.access_token_name = 'new-access-token'

          auth_headers_modified = @resource.create_named_token_pair

          get '/demo/members_only',
              params: {},
              headers: auth_headers_modified

          # TODO: do we want to send access-tokens with every response?
          @data = JSON.parse(response.body)
        end

        after do
          DeviseJwtAuth.access_token_name = 'access-token'
        end
      end
    end

    describe 'bypass_sign_in' do
      before do
        @resource = create(:user)
        @auth_headers = @resource.create_named_token_pair
      end
      describe 'is default value (true)' do
        before do
          get '/demo/members_only', params: {}, headers: @auth_headers
          @response_status = response.status
        end

        it 'should allow the request through' do
          assert_equal 200, @response_status
        end

        it 'should set current user' do
          assert_equal @controller.current_user, @resource
        end
      end
      describe 'is false' do
        before do
          DeviseJwtAuth.bypass_sign_in = false

          get '/demo/members_only', params: {}, headers: @auth_headers

          @access_token = response.headers['access-token']
          @response_status = response.status

          DeviseJwtAuth.bypass_sign_in = true
        end

        it 'should not allow the request through' do
          refute_equal 200, @response_status
        end

        it 'should not return auth headers from the first request' do
          assert_nil @access_token
        end
      end
    end

    describe 'enable_standard_devise_support' do
      before do
        @resource = create(:user, :confirmed)
        @auth_headers = @resource.create_named_token_pair

        DeviseJwtAuth.enable_standard_devise_support = true
      end

      describe 'Existing Warden authentication' do
        before do
          @resource = create(:user, :confirmed)
          login_as(@resource, scope: :user)

          # no auth headers sent, testing that warden authenticates correctly.
          get '/demo/members_only',
              params: {},
              headers: nil
        end

        describe 'devise mappings' do
          it 'should define current_user' do
            assert_equal @resource, @controller.current_user
          end

          it 'should define user_signed_in?' do
            assert @controller.user_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @resource, @controller.current_mang
          end
        end

        it 'should return success status' do
          assert_equal 200, response.status
        end
      end

      describe 'existing Warden authentication with ignored token data' do
        before do
          @resource = create(:user, :confirmed)
          login_as(@resource, scope: :user)

          get '/demo/members_only',
              params: {},
              headers: @auth_headers
        end

        describe 'devise mappings' do
          it 'should define current_user' do
            assert_equal @resource, @controller.current_user
          end

          it 'should define user_signed_in?' do
            assert @controller.user_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @resource, @controller.current_mang
          end
        end

        it 'should return success status' do
          assert_equal 200, response.status
        end
      end
    end
  end
end
