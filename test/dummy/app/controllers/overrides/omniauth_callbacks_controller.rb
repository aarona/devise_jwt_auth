# frozen_string_literal: true

module Overrides
  class OmniauthCallbacksController < DeviseJwtAuth::OmniauthCallbacksController
    DEFAULT_NICKNAME = 'stimpy'

    def assign_provider_attrs(user, auth_hash)
      user.assign_attributes(
        nickname: DEFAULT_NICKNAME,
        name: auth_hash['info']['name'],
        image: auth_hash['info']['image'],
        email: auth_hash['info']['email']
      )
    end
  end
end
