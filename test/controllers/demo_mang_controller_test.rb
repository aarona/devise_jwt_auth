# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DemoMangControllerTest < ActionDispatch::IntegrationTest
  describe DemoMangController do
    describe 'Token access' do
      before do
        @resource = create(:mang_user, :confirmed)
        @auth_headers = @resource.create_named_token_pair
      end

      describe 'successful request' do
        before do
          get '/demo/members_only_mang',
              params: {},
              headers: @auth_headers
        end

        describe 'devise mappings' do
          it 'should define current_mang' do
            assert_equal @resource, @controller.current_mang
          end

          it 'should define mang_signed_in?' do
            assert @controller.mang_signed_in?
          end

          it 'should not define current_user' do
            refute_equal @resource, @controller.current_user
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
          get '/demo/members_only_mang',
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
    end
  end
end
