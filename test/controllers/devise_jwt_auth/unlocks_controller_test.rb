# frozen_string_literal: true

require 'test_helper'

#  was the web request successful?
#  was the user redirected to the right page?
#  was the user successfully authenticated?
#  was the correct object stored in the response?
#  was the appropriate message delivered in the json payload?

class DeviseJwtAuth::UnlocksControllerTest < ActionController::TestCase
  describe DeviseJwtAuth::UnlocksController do
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

    describe 'Unlocking user' do
      before do
        @resource = create(:lockable_user)
      end

      describe 'request unlock without email' do
        before do
          @auth_headers = @resource.create_named_token_pair
          @new_password = Faker::Internet.password

          post :create
          @data = JSON.parse(response.body)
        end

        test 'response should fail' do
          assert_equal 401, response.status
        end
        test 'error message should be returned' do
          assert @data['errors']
          assert_equal @data['errors'], [I18n.t('devise_jwt_auth.passwords.missing_email')]
        end
      end

      describe 'request unlock' do
        describe 'unknown user should return 404' do
          before do
            post :create, params: { email: 'chester@cheet.ah' }
            @data = JSON.parse(response.body)
          end
          test 'unknown user should return 404' do
            assert_equal 404, response.status
          end

          test 'errors should be returned' do
            assert @data['errors']
            assert_equal @data['errors'],
                         [I18n.t('devise_jwt_auth.passwords.user_not_found',
                                 email: 'chester@cheet.ah')]
          end
        end

        describe 'successfully requested unlock' do
          before do
            post :create, params: { email: @resource.email }

            @data = JSON.parse(response.body)
          end

          test 'response should not contain extra data' do
            assert_nil @data['data']
          end
        end

        describe 'case-sensitive email' do
          before do
            post :create, params: { email: @resource.email }

            @mail = ActionMailer::Base.deliveries.last
            @resource.reload
            @data = JSON.parse(response.body)

            @mail_config_name  = CGI.unescape(@mail.body.match(/config=([^&]*)&/)[1])
            @mail_reset_token  = @mail.body.match(/unlock_token=(.*)"/)[1]
          end

          test 'response should return success status' do
            assert_equal 200, response.status
          end

          test 'response should contains message' do
            assert_equal @data['message'], I18n.t('devise_jwt_auth.unlocks.sended', email: @resource.email)
          end

          test 'action should send an email' do
            assert @mail
          end

          test 'the email should be addressed to the user' do
            assert_equal @mail.to.first, @resource.email
          end

          test 'the client config name should fall back to "default"' do
            assert_equal 'default', @mail_config_name
          end

          test 'the email body should contain a link with reset token as a query param' do
            user = LockableUser.unlock_access_by_token(@mail_reset_token)
            assert_equal user.id, @resource.id
          end

          describe 'unlock link failure' do
            test 'response should return 404' do
              assert_raises(ActionController::RoutingError) do
                get :show, params: { unlock_token: 'bogus' }
              end
            end
          end

          describe 'password reset link success' do
            before do
              get :show, params: { unlock_token: @mail_reset_token }

              @resource.reload

              raw_qs = response.location.split('?')[1]
              @qs = Rack::Utils.parse_nested_query(raw_qs)

              @access_token   = @qs[DeviseJwtAuth.access_token_name]
              @unlock         = @qs['unlock']
              @refresh_token  = response.cookies[DeviseJwtAuth.refresh_token_name]
            end

            test 'respones should have success redirect status' do
              assert_equal 302, response.status
            end

            test 'response should contain auth params' do
              assert @access_token
              assert @unlock
              assert @refresh_token
            end
          end
        end

        describe 'case-insensitive email' do
          before do
            @resource_class = LockableUser
            @request_params = {
              email: @resource.email.upcase
            }
          end

          test 'response should return success status if configured' do
            @resource_class.case_insensitive_keys = [:email]
            post :create, params: @request_params
            assert_equal 200, response.status
          end

          test 'response should return failure status if not configured' do
            @resource_class.case_insensitive_keys = []
            post :create, params: @request_params
            assert_equal 404, response.status
          end
        end
      end
    end
  end
end
