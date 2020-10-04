# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DeviseJwtAuth::SessionsControllerTest < ActionController::TestCase
  describe DeviseJwtAuth::SessionsController do
    describe 'Confirmed user' do
      before do
        @existing_user = create(:user, :with_nickname, :confirmed)
      end

      describe 'success' do
        before do
          post :create,
               params: {
                 email: @existing_user.email,
                 password: @existing_user.password
               }

          @resource = assigns(:resource)
          @data = JSON.parse(response.body)
        end

        test 'request should succeed' do
          assert_equal 200, response.status
        end

        test 'request should return user data' do
          assert_equal @existing_user.email, @data['data']['email']
        end

        test 'response should have access token' do
          assert @data[DeviseJwtAuth.access_token_name]
        end

        test 'response should have refresh token' do
          assert response.cookies[DeviseJwtAuth.refresh_token_name]
        end
      end

      describe 'get sign_in is not supported' do
        before do
          get :new,
              params: { nickname: @existing_user.nickname,
                        password: @existing_user.password }
          @data = JSON.parse(response.body)
        end

        test 'user is notified that they should use post sign_in to authenticate' do
          assert_equal 405, response.status
        end

        test 'response should contain errors' do
          assert @data['errors']
          assert_equal @data['errors'], [I18n.t('devise_jwt_auth.sessions.not_supported')]
        end

        test 'response should not have access token' do
          assert_nil @data[DeviseJwtAuth.access_token_name]
        end

        test 'response should not have refresh token' do
          assert_nil response.cookies[DeviseJwtAuth.refresh_token_name]
        end
      end

      describe 'header sign_in is supported' do
        before do
          request.headers.merge!(
            'email' => @existing_user.email,
            'password' => @existing_user.password
          )

          head :create
          @data = JSON.parse(response.body)
        end

        test 'user can sign in using header request' do
          assert_equal 200, response.status
        end

        test 'response should have access token' do
          assert @data[DeviseJwtAuth.access_token_name]
        end

        test 'response should have refresh token' do
          assert response.cookies[DeviseJwtAuth.refresh_token_name]
        end
      end

      describe 'alt auth keys' do
        before do
          post :create,
               params: { nickname: @existing_user.nickname,
                         password: @existing_user.password }
          @data = JSON.parse(response.body)
        end

        test 'user can sign in using nickname' do
          assert_equal 200, response.status
          assert_equal @existing_user.email, @data['data']['email']
        end

        test 'response should have access token' do
          assert @data[DeviseJwtAuth.access_token_name]
        end

        test 'response should have refresh token' do
          assert response.cookies[DeviseJwtAuth.refresh_token_name]
        end
      end

      describe 'authed user sign out' do
        before do
          def @controller.reset_session_called
            @reset_session_called == true
          end

          def @controller.reset_session
            @reset_session_called = true
          end

          @auth_headers = @existing_user.create_named_token_pair

          request.headers.merge!(@auth_headers)
          delete :destroy, format: :json
          @data = JSON.parse(response.body)
        end

        test 'user is successfully logged out' do
          assert_equal 200, response.status
        end

        test 'response should not have access token' do
          assert_nil @data[DeviseJwtAuth.access_token_name]
        end

        test 'response should delete refresh token from client' do
          assert_equal true, response.cookies.keys.include?(DeviseJwtAuth.refresh_token_name)
          assert_nil response.cookies[DeviseJwtAuth.refresh_token_name]
        end

        test 'session was destroyed' do
          assert_equal true, @controller.reset_session_called
        end
      end

      describe 'unauthed user sign out' do
        before do
          @auth_headers = @existing_user.create_named_token_pair

          delete :destroy, format: :json
          @data = JSON.parse(response.body)
        end

        test 'unauthed request returns 404' do
          assert_equal 404, response.status
        end

        test 'response should contain errors' do
          assert @data['errors']
          assert_equal @data['errors'],
                       [I18n.t('devise_jwt_auth.sessions.user_not_found')]
        end

        test 'response should not have access token' do
          assert_nil @data[DeviseJwtAuth.access_token_name]
        end

        test 'response should not have refresh token' do
          assert_nil response.cookies[DeviseJwtAuth.refresh_token_name]
        end
      end

      describe 'failure' do
        before do
          post :create,
               params: { email: @existing_user.email,
                         password: 'bogus' }

          @resource = assigns(:resource)
          @data = JSON.parse(response.body)
        end

        test 'request should fail' do
          assert_equal 401, response.status
        end

        test 'response should contain errors' do
          assert @data['errors']
          assert_equal @data['errors'],
                       [I18n.t('devise_jwt_auth.sessions.bad_credentials')]
        end

        test 'response should not have access token' do
          assert_nil @data[DeviseJwtAuth.access_token_name]
        end

        test 'response should not have refresh token' do
          assert_nil response.cookies[DeviseJwtAuth.refresh_token_name]
        end
      end

      #       describe 'failure with bad password when change_headers_on_each_request false' do
      #         before do
      #           DeviseJwtAuth.change_headers_on_each_request = false
      #
      #           # accessing current_user calls through set_user_by_token,
      #           # which initializes client_id
      #           @controller.current_user
      #
      #           post :create,
      #                params: { email: @existing_user.email,
      #                          password: 'bogus' }
      #
      #           @resource = assigns(:resource)
      #           @data = JSON.parse(response.body)
      #         end
      #
      #         test 'request should fail' do
      #           assert_equal 401, response.status
      #         end
      #
      #         test 'response should contain errors' do
      #           assert @data['errors']
      #           assert_equal @data['errors'], [I18n.t('devise_jwt_auth.sessions.bad_credentials')]
      #         end
      #
      #         after do
      #           DeviseJwtAuth.change_headers_on_each_request = true
      #         end
      #       end

      describe 'case-insensitive email' do
        before do
          @resource_class = User
          @request_params = {
            email: @existing_user.email.upcase,
            password: @existing_user.password
          }
        end

        test 'request should succeed if configured' do
          @resource_class.case_insensitive_keys = [:email]
          post :create, params: @request_params
          @data = JSON.parse(response.body)

          assert_equal 200, response.status
          assert @data[DeviseJwtAuth.access_token_name]
          assert response.cookies[DeviseJwtAuth.refresh_token_name]
        end

        test 'request should fail if not configured' do
          @resource_class.case_insensitive_keys = []
          post :create, params: @request_params
          @data = JSON.parse(response.body)

          assert_equal 401, response.status
          assert_nil response.cookies[DeviseJwtAuth.refresh_token_name]
          assert_nil @data[DeviseJwtAuth.access_token_name]
        end
      end

      describe 'stripping whitespace on email' do
        before do
          @resource_class = User
          @request_params = {
            # adding whitespace before and after email
            email: " #{@existing_user.email}  ",
            password: @existing_user.password
          }
        end

        test 'request should succeed if configured' do
          @resource_class.strip_whitespace_keys = [:email]
          post :create, params: @request_params
          @data = JSON.parse(response.body)

          assert_equal 200, response.status
          assert @data[DeviseJwtAuth.access_token_name]
          assert response.cookies[DeviseJwtAuth.refresh_token_name]
        end

        test 'request should fail if not configured' do
          @resource_class.strip_whitespace_keys = []
          post :create, params: @request_params
          @data = JSON.parse(response.body)

          assert_equal 401, response.status
          assert_nil @data[DeviseJwtAuth.access_token_name]
          assert_nil response.cookies[DeviseJwtAuth.refresh_token_name]
        end
      end
    end

    describe 'Unconfirmed user' do
      before do
        @unconfirmed_user = create(:user)
        post :create, params: { email: @unconfirmed_user.email,
                                password: @unconfirmed_user.password }
        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should fail' do
        assert_equal 401, response.status
      end

      test 'response should contain errors' do
        assert @data['errors']
        assert_equal @data['errors'],
                     [I18n.t('devise_jwt_auth.sessions.not_confirmed',
                             email: @unconfirmed_user.email)]
      end
    end

    describe 'Unconfirmed user with allowed unconfirmed access' do
      before do
        @original_duration = Devise.allow_unconfirmed_access_for
        Devise.allow_unconfirmed_access_for = 3.days
        @recent_unconfirmed_user = create(:user)
        post :create,
             params: { email: @recent_unconfirmed_user.email,
                       password: @recent_unconfirmed_user.password }
        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      after do
        Devise.allow_unconfirmed_access_for = @original_duration
      end

      test 'request should succeed' do
        assert_equal 200, response.status
      end

      test 'request should return user data' do
        assert_equal @recent_unconfirmed_user.email, @data['data']['email']
      end
    end

    describe 'Unconfirmed user with expired unconfirmed access' do
      before do
        @unconfirmed_user = create(:user, :unconfirmed)
        post :create,
             params: { email: @unconfirmed_user.email,
                       password: @unconfirmed_user.password }
        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should fail' do
        assert_equal 401, response.status
      end

      test 'response should contain errors' do
        assert @data['errors']
      end
    end

    describe 'Non-existing user' do
      before do
        post :create,
             params: { email: -> { Faker::Internet.email },
                       password: -> { Faker::Number.number(10) } }
        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should fail' do
        assert_equal 401, response.status
      end

      test 'response should contain errors' do
        assert @data['errors']
      end
    end

    describe 'Alternate user class' do
      setup do
        @request.env['devise.mapping'] = Devise.mappings[:mang]
      end

      teardown do
        @request.env['devise.mapping'] = Devise.mappings[:user]
      end

      before do
        @existing_user = create(:mang_user, :confirmed)

        post :create,
             params: { email: @existing_user.email,
                       password: @existing_user.password }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'request should succeed' do
        assert_equal 200, response.status
      end

      test 'request should return user data' do
        assert_equal @existing_user.email, @data['data']['email']
      end
    end

    describe 'User with only :database_authenticatable and :registerable included' do
      setup do
        @request.env['devise.mapping'] = Devise.mappings[:only_email_user]
      end

      teardown do
        @request.env['devise.mapping'] = Devise.mappings[:user]
      end

      before do
        @existing_user = create(:only_email_user)

        post :create,
             params: { email: @existing_user.email,
                       password: @existing_user.password }

        @resource = assigns(:resource)
        @data = JSON.parse(response.body)
      end

      test 'user should be able to sign in without confirmation' do
        assert 200, response.status
        refute OnlyEmailUser.method_defined?(:confirmed_at)
      end
    end

    describe 'Lockable User' do
      setup do
        @request.env['devise.mapping'] = Devise.mappings[:lockable_user]
      end

      teardown do
        @request.env['devise.mapping'] = Devise.mappings[:user]
      end

      before do
        @original_lock_strategy = Devise.lock_strategy
        @original_unlock_strategy = Devise.unlock_strategy
        @original_maximum_attempts = Devise.maximum_attempts
        Devise.lock_strategy = :failed_attempts
        Devise.unlock_strategy = :email
        Devise.maximum_attempts = 5
      end

      after do
        Devise.lock_strategy = @original_lock_strategy
        Devise.maximum_attempts = @original_maximum_attempts
        Devise.unlock_strategy = @original_unlock_strategy
      end

      describe 'locked user' do
        before do
          @locked_user = create(:lockable_user, :locked)
          post :create,
               params: { email: @locked_user.email,
                         password: @locked_user.password }
          @data = JSON.parse(response.body)
        end

        test 'request should fail' do
          assert_equal 401, response.status
        end

        test 'response should contain errors' do
          assert @data['errors']
          assert_equal @data['errors'], [I18n.t('devise.mailer.unlock_instructions.account_lock_msg')]
        end
      end

      describe 'unlocked user with bad password' do
        before do
          @unlocked_user = create(:lockable_user)
          post :create,
               params: { email: @unlocked_user.email,
                         password: 'bad-password' }
          @data = JSON.parse(response.body)
        end

        test 'request should fail' do
          assert_equal 401, response.status
        end

        test 'should increase failed_attempts' do
          assert_equal 1, @unlocked_user.reload.failed_attempts
        end

        test 'response should contain errors' do
          assert @data['errors']
          assert_equal @data['errors'], [I18n.t('devise_jwt_auth.sessions.bad_credentials')]
        end

        describe 'after maximum_attempts should block the user' do
          before do
            4.times do
              post :create,
                   params: { email: @unlocked_user.email,
                             password: 'bad-password' }
            end
            @data = JSON.parse(response.body)
          end

          test 'should increase failed_attempts' do
            assert_equal 5, @unlocked_user.reload.failed_attempts
          end

          test 'should block the user' do
            assert_equal true, @unlocked_user.reload.access_locked?
          end
        end
      end
    end
  end
end
