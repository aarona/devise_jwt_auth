# frozen_string_literal: true

require 'test_helper'

class DeviseJwtAuth::TokenFactoryTest < ActiveSupport::TestCase
  describe 'TokenFactory module' do
    let(:tf) { DeviseJwtAuth::TokenFactory }
    let(:token_regexp) { %r{^[A-Za-z0-9\-_=]+\.[A-Za-z0-9\-_=]+\.?[A-Za-z0-9\-_.+/=]*$} }

    it 'should be defined' do
      assert_equal(tf.present?, true)
      assert_kind_of(Module, tf)
    end

    describe 'interface' do
      let(:payload) { { foo: 'test' } }
      let(:future_exp) { (Time.zone.now + 1.hour).to_i }
      let(:past_exp) { (Time.zone.now - 1.hour).to_i }

      it '::create_refresh_token' do
        assert_respond_to(tf, :create_refresh_token)
        token = tf.create_refresh_token(payload)
        assert_match(token_regexp, token)
      end

      it '::create_access_token' do
        assert_respond_to(tf, :create_access_token)
        token = tf.create_access_token(payload)
        assert_match(token_regexp, token)
      end

      describe '::decode_refresh_token' do
        let(:valid_key) { DeviseJwtAuth.refresh_token_encryption_key }

        it 'decodes payload' do
          assert_respond_to(tf, :decode_refresh_token)
          token = tf.create_refresh_token(payload)
          result = tf.decode_refresh_token(token)
          assert result['foo']
        end

        it 'validates expiry' do
          token = tf.create_refresh_token(payload.merge(exp: future_exp))
          result = tf.decode_refresh_token(token)
          assert result['exp'] == future_exp
        end

        it 'invalidates expired token' do
          token = tf.create_refresh_token(payload.merge(exp: past_exp))
          result = tf.decode_refresh_token(token)
          assert_nil result['exp']
        end

        it 'invalidates bogus token' do
          result = tf.decode_refresh_token('bogus token')
          assert_empty result
        end

        it 'invalidates nil token' do
          result = tf.decode_refresh_token(nil)
          assert_empty result
        end

        it 'invalidates token created with incorrect key' do
          token = tf.create_refresh_token(payload)
          DeviseJwtAuth.refresh_token_encryption_key = 'invalid key'
          result = tf.decode_refresh_token(token)
          assert_empty result
          DeviseJwtAuth.refresh_token_encryption_key = valid_key
        end
      end

      describe '::decode_access_token' do
        let(:valid_key) { DeviseJwtAuth.access_token_encryption_key }

        it 'decodes payload' do
          assert_respond_to(tf, :decode_access_token)
          token = tf.create_access_token(payload)
          result = tf.decode_access_token(token)
          assert result['foo']
        end

        it 'validates expiry' do
          token = tf.create_access_token(payload.merge(exp: future_exp))
          result = tf.decode_access_token(token)
          assert result['exp'] == future_exp
        end

        it 'invalidates expired token' do
          token = tf.create_access_token(payload.merge(exp: past_exp))
          result = tf.decode_access_token(token)
          assert_nil result['exp']
        end

        it 'invalidates bogus token' do
          result = tf.decode_access_token('bogus token')
          assert_empty result
        end

        it 'invalidates nil token' do
          result = tf.decode_access_token(nil)
          assert_empty result
        end

        it 'invalidates token created with incorrect key' do
          token = tf.create_access_token(payload)
          DeviseJwtAuth.access_token_encryption_key = 'invalid key'
          result = tf.decode_access_token(token)
          assert_empty result
          DeviseJwtAuth.access_token_encryption_key = valid_key
        end
      end
    end
  end
end
