# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  describe User do
    describe 'serialization' do
      test 'hash should not include sensitive info' do
        @resource = build(:user)
        refute @resource.as_json[:tokens]
      end
    end

    describe 'creation' do
      test 'save fails if uid is missing' do
        @resource = User.new
        @resource.uid = nil
        @resource.save

        assert @resource.errors.messages[:uid]
      end
    end

    describe 'email registration' do
      test 'model should not save if email is blank' do
        @resource = build(:user, email: nil)

        refute @resource.save
        assert @resource.errors.messages[:email] == [I18n.t('errors.messages.blank')]
      end

      test 'model should not save if email is not an email' do
        @resource = build(:user, email: '@example.com')

        refute @resource.save
        assert @resource.errors.messages[:email] == [I18n.t('errors.messages.not_email')]
      end
    end

    describe 'email uniqueness' do
      test 'model should not save if email is taken' do
        user_attributes = attributes_for(:user)
        create(:user, user_attributes)
        @resource = build(:user, user_attributes)

        refute @resource.save
        assert @resource.errors.messages[:email].first.include? 'taken'
        assert @resource.errors.messages[:email].none? { |e| e =~ /translation missing/ }
      end
    end

    describe 'oauth2 authentication' do
      test 'model should save even if email is blank' do
        @resource = build(:user, :facebook, email: nil)

        assert @resource.save
        assert @resource.errors.messages[:email].blank?
      end
    end

    describe 'nil tokens are handled properly' do
      before do
        @resource = create(:user, :confirmed)
      end

      test 'tokens can be set to nil' do
        @resource.tokens = nil
        assert @resource.save
      end
    end
  end
end
