# frozen_string_literal: true

require 'jwt'

module DeviseJwtAuth
  # A token management factory which allow generate token objects and check them.
  module TokenFactory
    def self.create_refresh_token(payload)
      if payload[:exp].blank? && payload['exp'].blank?
        payload[:exp] = (Time.zone.now + DeviseJwtAuth.refresh_token_lifespan).to_i
      end

      JWT.encode payload, DeviseJwtAuth.refresh_token_encryption_key
    end

    def self.create_access_token(payload)
      if payload[:exp].blank? && payload['exp'].blank?
        payload[:exp] = (Time.zone.now + DeviseJwtAuth.access_token_lifespan).to_i
      end

      JWT.encode payload, DeviseJwtAuth.access_token_encryption_key
    end

    def self.decode_refresh_token(token)
      JWT.decode(token, DeviseJwtAuth.refresh_token_encryption_key).first
    rescue JWT::ExpiredSignature
      {}
    rescue JWT::DecodeError
      {}
    rescue JWT::VerificationError
      {}
    rescue NoMethodError
      {}
    rescue TypeError
      {}
    end

    def self.decode_access_token(token)
      JWT.decode(token, DeviseJwtAuth.access_token_encryption_key).first
    rescue JWT::ExpiredSignature
      {}
    rescue JWT::DecodeError
      {}
    rescue JWT::VerificationError
      {}
    rescue NoMethodError
      {}
    rescue TypeError
      {}
    end
  end
end
