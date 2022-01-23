# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DemoGroupControllerTest < ActionDispatch::IntegrationTest
  describe DemoGroupController do
    describe 'Token access' do
      before do
        # user
        @resource = create(:user, :confirmed)
        @resource_auth_headers = @resource.create_named_token_pair

        # mang
        @mang = create(:mang_user, :confirmed)

        @mang_auth_headers = @mang.create_named_token_pair
      end

      describe 'user access' do
        before do
          get '/demo/members_only_group',
              params: {},
              headers: @resource_auth_headers
        end

        test 'request is successful' do
          assert_equal 200, response.status
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

          it 'should define current_member' do
            assert_equal @resource, @controller.current_member
          end

          it 'should define current_members' do
            assert @controller.current_members.include? @resource
          end

          it 'should define member_signed_in?' do
            assert @controller.current_members.include? @resource
          end

          it 'should define render_authenticate_error' do
            assert @controller.methods.include?(:render_authenticate_error)
          end
        end
      end

      describe 'mang access' do
        before do
          get '/demo/members_only_group',
              params: {},
              headers: @mang_auth_headers
        end

        test 'request is successful' do
          assert_equal 200, response.status
        end

        describe 'devise mappings' do
          it 'should define current_mang' do
            assert_equal @mang, @controller.current_mang
          end

          it 'should define mang_signed_in?' do
            assert @controller.mang_signed_in?
          end

          it 'should not define current_mang' do
            refute_equal @mang, @controller.current_user
          end

          it 'should define current_member' do
            assert_equal @mang, @controller.current_member
          end

          it 'should define current_members' do
            assert @controller.current_members.include? @mang
          end

          it 'should define member_signed_in?' do
            assert @controller.current_members.include? @mang
          end

          it 'should define render_authenticate_error' do
            assert @controller.methods.include?(:render_authenticate_error)
          end
        end
      end

      describe 'failed access' do
        before do
          get '/demo/members_only_group',
              params: {},
              headers: @mang_auth_headers.merge('access-token' => 'bogus')
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
